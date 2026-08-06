#!/usr/bin/env bash
# Seed hebe's receipts signing key into the hartland Key Vault (step 1 of the B fix).
#
#   ./seed-hebe-receipts-key.sh            # idempotent: creates it only if absent
#   ./seed-hebe-receipts-key.sh --rotate   # DESTRUCTIVE — see the warning below
#
# WHY 32 ASCII CHARS, NOT 32 RANDOM BYTES
# hebe loads this value as an Ed25519 private-key seed and hard-requires exactly 32 bytes
# (Ed25519PrivateKey: `require(seed.size == 32)`). It travels vault -> ESO template -> Secret,
# and ESO templating is string-based, so arbitrary binary would not survive intact.
# `openssl rand -base64 24` emits exactly 32 printable ASCII characters (24 bytes -> 32 base64
# chars, no padding) = 32 bytes on the wire. One value, safe at every hop, still 192 bits of
# entropy in the seed material.
#
# ROTATION IS NOT FREE
# Receipts are an append-only signed chain and the derived public key is persisted with it.
# Replacing the seed means every receipt signed under the old key stops verifying. --rotate
# therefore demands an explicit typed confirmation.
set -euo pipefail

VAULT="${VAULT:-hartland}"
SECRET_NAME="${SECRET_NAME:-hebe-receipts-signing-key}"
SEED_BYTES=32

MODE=ensure
case "${1:-}" in
  --rotate) MODE=rotate ;;
  "") ;;
  *) echo "usage: $0 [--rotate]" >&2; exit 2 ;;
esac

TMP="$(umask 077; mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
SEEDFILE="$TMP/seed"

say() { printf '==> %s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

command -v az >/dev/null 2>&1 || die "az CLI not found"
az account show >/dev/null 2>&1 || die "not logged in to Azure — run: az login"

EXISTS=0
az keyvault secret show --vault-name "$VAULT" --name "$SECRET_NAME" >/dev/null 2>&1 && EXISTS=1

if [ "$EXISTS" = 1 ] && [ "$MODE" = ensure ]; then
  # Validate the stored value rather than blindly reporting success — a wrong length here
  # crash-loops hebe at boot with "Ed25519 seed must be 32 bytes", long after this script ran.
  LEN=$(az keyvault secret show --vault-name "$VAULT" --name "$SECRET_NAME" --query value -o tsv \
        | tr -d '\n' | wc -c | tr -d ' ')
  if [ "$LEN" = "$SEED_BYTES" ]; then
    say "'$SECRET_NAME' already present in vault '$VAULT' and is $SEED_BYTES bytes — nothing to do."
    exit 0
  fi
  die "'$SECRET_NAME' exists but is $LEN bytes, not $SEED_BYTES. hebe will refuse it at boot.
     Inspect it, then re-run with --rotate once you are sure no receipts depend on it."
fi

if [ "$EXISTS" = 1 ] && [ "$MODE" = rotate ]; then
  cat <<'WARN'

  !! ROTATING hebe's receipts signing key !!

  Every receipt already signed under the current key will FAIL verification afterwards.
  The receipt chain in the hebe_dev schema is append-only; it cannot be re-signed.
  Only proceed if this instance has no receipts worth verifying (e.g. a fresh instance).

WARN
  printf '  Type ROTATE to continue: '
  read -r CONFIRM
  [ "$CONFIRM" = "ROTATE" ] || die "aborted"
fi

# Exactly 32 printable ASCII chars; -A keeps it on one line, then strip the trailing newline.
openssl rand -base64 24 | tr -d '\n' > "$SEEDFILE"
ACTUAL=$(wc -c < "$SEEDFILE" | tr -d ' ')
[ "$ACTUAL" = "$SEED_BYTES" ] || die "generated seed is $ACTUAL bytes, expected $SEED_BYTES"
say "generated a ${SEED_BYTES}-byte seed"

az keyvault secret set --vault-name "$VAULT" --name "$SECRET_NAME" \
  --file "$SEEDFILE" --encoding utf-8 --output none
say "stored in Key Vault '$VAULT' as '$SECRET_NAME'"

# Round-trip check: the value ESO will read must be byte-identical to what hebe needs.
az keyvault secret show --vault-name "$VAULT" --name "$SECRET_NAME" --query value -o tsv \
  | tr -d '\n' > "$SEEDFILE.rt"
cmp -s "$SEEDFILE" "$SEEDFILE.rt" \
  || die "vault round-trip altered the seed bytes — do NOT proceed; hebe would fail at boot"
say "vault round-trip verified byte-exact ($SEED_BYTES bytes)"

cat <<NEXT

==> done. The seed is in the vault only; it is never printed and never committed.
    next: land the ClusterExternalSecret (olymp) so it reaches hebe as the
          'receipts.signing_key' field of the hebe-dev Secret in ns kantheon.
NEXT
