#!/usr/bin/env bash
# Verify hebe's provisioning end to end on hartland, AFTER the olymp PR has merged to master
# and ArgoCD has synced. Read-only: it mutates nothing. Prints a pass/fail line per link in the
# chain so a failure names the hop, not just "hebe is red".
#
#   ./verify-hebe-provisioning.sh
set -uo pipefail

CONTEXT="${CONTEXT:-hartland}"
FAILED=0

ok()   { printf '  \033[32mPASS\033[0m  %s\n' "$*"; }
bad()  { printf '  \033[31mFAIL\033[0m  %s\n' "$*"; FAILED=1; }
head_() { printf '\n== %s\n' "$*"; }
k() { kubectl --context "$CONTEXT" "$@"; }

head_ "1. ArgoCD apps"
for app in auth data hebe; do
  line=$(k -n argocd get application "$app" -o jsonpath='{.status.sync.status}/{.status.health.status}' 2>/dev/null)
  [ "$line" = "Synced/Healthy" ] && ok "app $app — $line" || bad "app $app — ${line:-<not found>}"
done

head_ "2. ExternalSecret hebe-dev -> Secret"
es=$(k -n kantheon get externalsecret hebe-dev -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
[ "$es" = "True" ] && ok "ExternalSecret hebe-dev Ready" \
  || bad "ExternalSecret hebe-dev not Ready (${es:-missing}) — check the ESO log; a bad template
        function or a missing vault key shows up here first"

# Key names only — values are never read or printed by this script.
keys=$(k -n kantheon get secret hebe-dev -o jsonpath='{range .data.*}{"x"}{end}' 2>/dev/null | wc -c | tr -d ' ')
names=$(k -n kantheon get secret hebe-dev -o go-template='{{range $k,$v := .data}}{{$k}} {{end}}' 2>/dev/null)
for want in pg llm-gateway-key receipts.signing_key; do
  case " $names " in *" $want "*) ok "secret key present: $want" ;; *) bad "secret key MISSING: $want" ;; esac
done

# The one field whose LENGTH is load-bearing. Length only; never the value.
seedlen=$(k -n kantheon get secret hebe-dev -o jsonpath='{.data.receipts\.signing_key}' 2>/dev/null | base64 -d | wc -c | tr -d ' ')
[ "$seedlen" = "32" ] && ok "receipts.signing_key is 32 bytes" \
  || bad "receipts.signing_key is ${seedlen:-0} bytes, must be 32 (hebe: 'Ed25519 seed must be 32 bytes')"

head_ "3. pgvector in the hebe database"
PRIMARY=$(k -n data get pods -l cnpg.io/cluster=postgres \
  -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.metadata.labels.cnpg\.io/instanceRole}{"\n"}{end}' \
  | awk '/primary/{print $1; exit}')
if [ -z "$PRIMARY" ]; then
  bad "no CNPG primary found"
else
  ext=$(k -n data exec -i "$PRIMARY" -c postgres -- psql -U postgres -d hebe -tAc \
        "SELECT extversion FROM pg_extension WHERE extname='vector'" 2>/dev/null | tr -d ' \n')
  [ -n "$ext" ] && ok "extension vector $ext installed in db hebe" \
    || bad "extension vector NOT installed in db hebe — Flyway V2 will fail on vector(1536)"
  dbstate=$(k -n data get database hebe -o jsonpath='{.status.applied}' 2>/dev/null)
  [ "$dbstate" = "true" ] && ok "CNPG Database hebe applied" \
    || bad "CNPG Database hebe not applied: $(k -n data get database hebe -o jsonpath='{.status.message}' 2>/dev/null)"
fi

head_ "4. hebe pod"
phase=$(k -n kantheon get pods -l app.kubernetes.io/name=hebe -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
ready=$(k -n kantheon get pods -l app.kubernetes.io/name=hebe -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null)
[ "$phase" = "Running" ] && [ "$ready" = "true" ] && ok "pod Running and Ready" \
  || bad "pod phase=${phase:-none} ready=${ready:-none}"

# The two boot failures this whole change exists to prevent — surfaced by name, not by
# "read the logs yourself".
logs=$(k -n kantheon logs -l app.kubernetes.io/name=hebe --tail=200 2>/dev/null)
case "$logs" in
  *"Ed25519 seed must be 32 bytes"*) bad "boot log: bad receipts seed length" ;;
  *'type "vector" does not exist'*)  bad "boot log: pgvector missing at Flyway V2" ;;
  *"requires the 'pg' secret"*)      bad "boot log: pg secret absent or blank" ;;
  *) ok "no known boot-blocker in the last 200 log lines" ;;
esac
printf '%s\n' "$logs" | grep -qi "Successfully applied\|migrat" && ok "Flyway ran" || true

head_ "5. gateway key accepted (hebe's own key, from its mounted Secret)"
if [ "$ready" = "true" ]; then
  code=$(k -n kantheon exec deploy/hebe -- sh -c \
    'curl -sS -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $(cat $HEBE_SECRETS_DIR/llm-gateway-key)" http://llm-gateway.ttr-server:7280/v1/models' 2>/dev/null)
  case "$code" in
    200) ok "llm-gateway accepted hebe's ttrk- key (200)" ;;
    401) bad "llm-gateway rejected the key (401) — vault value and seeded virtual_keys hash disagree" ;;
    *)   bad "unexpected gateway response: ${code:-<no curl in image?>}" ;;
  esac
else
  printf '  SKIP  gateway check (pod not Ready)\n'
fi

printf '\n'
[ "$FAILED" = 0 ] && { printf 'ALL GREEN — hebe is provisioned.\n'; exit 0; }
printf 'One or more checks FAILED (see above).\n'; exit 1
