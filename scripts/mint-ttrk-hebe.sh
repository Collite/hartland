#!/usr/bin/env bash
# Mint (or reuse) hebe's `ttrk-` virtual key for the LLM gateway on the hartland cluster.
#
#   ./mint-ttrk-hebe.sh            # ensure: reuse the vault key if present, else mint one
#   ./mint-ttrk-hebe.sh --rotate   # force a fresh key (old plaintext is overwritten in the vault)
#   ./mint-ttrk-hebe.sh --verify   # no mutation; just check vault ↔ DB ↔ data plane agree
#
# What it does (cutover-runbook §2a, adapted for the ClusterExternalSecret delivery path):
#   1. mints a 256-bit url-safe `ttrk-…` key,
#   2. stores the PLAINTEXT in Azure Key Vault as secret `ttrk-hebe`   ← the CES reads this,
#   3. seeds its SHA-256 into `virtual_keys` in the gateway's `llm_gateway` DB,
#   4. verifies the key is accepted on the data plane (`GET /v1/models` → 200).
#
# It deliberately does NOT touch the `hebe-dev` Secret: delivery is the ClusterExternalSecret
# in olymp (clusters/hartland/platform/auth/), so a re-run of `just hebe-provision dev` can no
# longer blank the key — the durability caveat the runbook flags for the hand-carried path.
#
# The plaintext key is NEVER printed, never passed in argv (so it stays out of `ps` and out of
# any pod spec), and never written outside a mode-0600 temp file that is removed on exit.
set -euo pipefail

CONTEXT="${CONTEXT:-hartland}"
VAULT="${VAULT:-hartland}"
TEAM="hebe"
VAULT_SECRET="ttrk-${TEAM}"
VK_ID="${VK_ID:-vk_hebe_hartland_0001}"
VK_NAME="${VK_NAME:-hebe-dev}"
GW_NS="ttr-server"
DATA_NS="data"
GW_DB="llm_gateway"

MODE=ensure
case "${1:-}" in
  --rotate) MODE=rotate ;;
  --verify) MODE=verify ;;
  "") ;;
  *) echo "usage: $0 [--rotate|--verify]" >&2; exit 2 ;;
esac

TMPDIR_KEY="$(umask 077; mktemp -d)"
trap 'rm -rf "$TMPDIR_KEY"' EXIT
KEYFILE="$TMPDIR_KEY/key"

say() { printf '==> %s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

# SHA-256, lowercase hex, over the exact bytes of the key with NO trailing newline —
# PgKeyValidator hashes the whole `ttrk-…` string verbatim, so this must be byte-exact.
sha256_of_file() {
  if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | cut -d' ' -f1
  elif command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | cut -d' ' -f1
  else die "need shasum or sha256sum"; fi
}

# ── 0. preflight ──────────────────────────────────────────────────────────────
say "preflight"
command -v az >/dev/null 2>&1 || die "az CLI not found"
command -v kubectl >/dev/null 2>&1 || die "kubectl not found"
az account show >/dev/null 2>&1 || die "not logged in to Azure — run: az login"
kubectl --context "$CONTEXT" get ns "$GW_NS" >/dev/null 2>&1 \
  || die "cannot reach cluster context '$CONTEXT'"

# The gateway must be Ready: its boot applies Flyway V1–V3 (creating virtual_keys) and upserts
# the teams that virtual_keys.team_id references. Seeding earlier => missing relation / FK error.
say "waiting for llm-gateway to be Ready (Flyway V1-V3 + team upsert happen at boot)"
kubectl --context "$CONTEXT" -n "$GW_NS" rollout status deploy/llm-gateway --timeout=180s

PRIMARY="$(kubectl --context "$CONTEXT" -n "$DATA_NS" get pods -l cnpg.io/cluster=postgres \
  -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.metadata.labels.cnpg\.io/instanceRole}{"\n"}{end}' \
  | awk '/primary/{print $1; exit}')"
[ -n "$PRIMARY" ] || die "no writable CNPG primary found for cluster 'postgres' in ns $DATA_NS"
say "CNPG primary: $PRIMARY"

psql_gw() { kubectl --context "$CONTEXT" -n "$DATA_NS" exec -i "$PRIMARY" -c postgres -- psql -U postgres -d "$GW_DB" "$@"; }

# team_id is an FK — fail loudly rather than leaving a half-seeded gateway.
psql_gw -tAc "SELECT 1 FROM teams WHERE id = '$TEAM'" | grep -q 1 \
  || die "team '$TEAM' missing from the gateway's teams table (check governance.yaml)"
say "team '$TEAM' present in governance"

# ── 1. obtain the key: reuse from the vault, or mint ───────────────────────────
EXISTING=0
if az keyvault secret show --vault-name "$VAULT" --name "$VAULT_SECRET" >/dev/null 2>&1; then
  EXISTING=1
fi

if [ "$MODE" = verify ]; then
  [ "$EXISTING" = 1 ] || die "vault secret '$VAULT_SECRET' does not exist — nothing to verify"
  az keyvault secret show --vault-name "$VAULT" --name "$VAULT_SECRET" --query value -o tsv \
    | tr -d '\n' > "$KEYFILE"
  say "verify mode — using the existing vault key"
elif [ "$EXISTING" = 1 ] && [ "$MODE" = ensure ]; then
  az keyvault secret show --vault-name "$VAULT" --name "$VAULT_SECRET" --query value -o tsv \
    | tr -d '\n' > "$KEYFILE"
  say "vault already holds '$VAULT_SECRET' — reusing it (pass --rotate to replace)"
else
  # 256-bit, url-safe alphabet, `ttrk-` prefix (cutover-runbook §2a step 1).
  printf 'ttrk-%s' "$(openssl rand -base64 32 | tr '+/' '-_' | tr -d '=')" > "$KEYFILE"
  say "minted a fresh key"
  az keyvault secret set --vault-name "$VAULT" --name "$VAULT_SECRET" \
    --file "$KEYFILE" --encoding utf-8 --output none
  say "stored plaintext in Key Vault '$VAULT' as '$VAULT_SECRET'"
  # Read back and compare — proves the vault round-trip is byte-exact before we seed the hash.
  az keyvault secret show --vault-name "$VAULT" --name "$VAULT_SECRET" --query value -o tsv \
    | tr -d '\n' > "$KEYFILE.rt"
  cmp -s "$KEYFILE" "$KEYFILE.rt" || die "vault round-trip changed the key bytes — aborting before seeding"
  rm -f "$KEYFILE.rt"
fi

HASH="$(sha256_of_file "$KEYFILE")"
say "key sha256: ${HASH:0:12}… (plaintext stays in the vault; never printed)"

# ── 2. seed the hash into the gateway ─────────────────────────────────────────
if [ "$MODE" != verify ]; then
  say "seeding virtual_keys row '$VK_ID' (team=$TEAM)"
  # id-upsert: a rotate overwrites the hash in place and un-revokes. Note the UNIQUE on
  # key_hash — if this exact key were already seeded under a DIFFERENT id, this errors rather
  # than silently creating a duplicate, which is the behaviour we want.
  psql_gw -v ON_ERROR_STOP=1 -v vk_id="$VK_ID" -v team="$TEAM" -v vk_name="$VK_NAME" -v hash="$HASH" <<'SQL'
INSERT INTO virtual_keys (id, team_id, name, key_hash, seeded)
VALUES (:'vk_id', :'team', :'vk_name', :'hash', true)
ON CONFLICT (id) DO UPDATE
  SET key_hash = EXCLUDED.key_hash, seeded = true, revoked_at = NULL;
SQL
fi

psql_gw -c "SELECT team_id, name, left(key_hash,12)||'…' AS hash, seeded, revoked_at, last_used_at
            FROM virtual_keys ORDER BY team_id;"

# ── 3. verify on the data plane ───────────────────────────────────────────────
# The key goes into a short-lived Secret rather than the pod's command line, so the plaintext
# never lands in the pod spec (and therefore never in the API server's object store / audit log).
say "verifying against llm-gateway /v1/models (validator cache TTL is 30s, so allow a moment)"
kubectl --context "$CONTEXT" -n "$GW_NS" delete secret ttrk-verify --ignore-not-found >/dev/null
kubectl --context "$CONTEXT" -n "$GW_NS" delete pod keytest --ignore-not-found >/dev/null
kubectl --context "$CONTEXT" -n "$GW_NS" create secret generic ttrk-verify \
  --from-file=key="$KEYFILE" >/dev/null

kubectl --context "$CONTEXT" -n "$GW_NS" apply -f - >/dev/null <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: keytest
spec:
  restartPolicy: Never
  containers:
    - name: curl
      image: curlimages/curl
      env:
        - name: TTRK
          valueFrom:
            secretKeyRef: { name: ttrk-verify, key: key }
      command: ["sh", "-c"]
      args:
        - 'curl -sS -o /dev/null -w "HTTP %{http_code}\n" -H "Authorization: Bearer $TTRK" http://llm-gateway:7280/v1/models'
YAML

kubectl --context "$CONTEXT" -n "$GW_NS" wait --for=jsonpath='{.status.phase}'=Succeeded pod/keytest --timeout=60s >/dev/null || true
RESULT="$(kubectl --context "$CONTEXT" -n "$GW_NS" logs keytest 2>/dev/null || echo 'HTTP ???')"
kubectl --context "$CONTEXT" -n "$GW_NS" delete pod keytest --ignore-not-found >/dev/null
kubectl --context "$CONTEXT" -n "$GW_NS" delete secret ttrk-verify --ignore-not-found >/dev/null

printf '\n'
case "$RESULT" in
  *200*) say "data plane accepted the key — $RESULT" ;;
  *401*) die "gateway rejected the key (401) — hash mismatch or the row is revoked. Re-run --verify after 30s (validator cache); if it persists the vault value and the seeded hash have diverged." ;;
  *)     die "unexpected data-plane result: $RESULT" ;;
esac

cat <<NEXT

==> ttrk-${TEAM} is live.
    vault:    ${VAULT} / ${VAULT_SECRET}   (plaintext — the only copy)
    gateway:  virtual_keys.${VK_ID}         (sha256 only)
    next:     land the ClusterExternalSecret so hebe receives it as the
              'llm-gateway-key' field of the hebe-dev Secret in ns kantheon.
NEXT
