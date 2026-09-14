#!/usr/bin/env bash
# IE-P3·S3.3·T1 — `just report-fingerprint`: the report a client receives, held against the book.
#
# ## What it proves that nothing else does
#
# kantheon's suites prove the renderer assembles §4.1 correctly from `period_values`, against
# hand-computed expectations. `investment-dod` proves the door answers the estate's programs. Neither
# opens the workbook a person downloads. This does: it renders `investment-evolution:v1` through
# studio-bff exactly as the Reports tile does, pulls the `.xlsx` back, reads the Summary sheet, and
# compares it — row by row, currency by currency — with the REFERENCE query run on the book itself.
#
# ⛔ The reference runs on **psql**, not through the door, and that is not a shortcut. ⚑IE-15 (a) ruled
# `quarterly_evolution` un-runnable through the door (no date arithmetic, no LAG); a live walk
# re-confirmed the 404 on 2026-09-14. IE-C35's "equal to the program run directly" therefore means the
# statement run directly on the database — which is also the statement kantheon's conformance suite
# holds to hand-computed answers, so agreement here reaches all the way back to those.
#
# The SQL is read out of the SYNCED model (`model/investment/queries/q_investment.ttrm`), not copied
# here: a copy would be a second definition of the report, and the two would drift the first time the
# query changed.
#
# Env:
#   IE_FP_BFF         base URL of studio-bff (e.g. http://studio-bff.kantheon.svc.cluster.local:7330)
#   IE_FP_DSN         psql DSN for the `entry` database (the book the report is checked against)
#   IE_FP_PORTFOLIO   the portfolio to report on
#   IE_FP_AS_OF       the report's as-of date (default: today, UTC)
#   IE_FP_QUARTERS    how many quarter ends (default 4; the template's own bounds are 1..12)
#   IE_FP_MODEL       the synced queries file (default model/investment/queries/q_investment.ttrm)
#   IE_FP_TEMPLATE    the template id (default investment-evolution:v1)
#   IE_FP_TOLERANCE   money tolerance per cell (default 0.01 — S3.1·D7's ruled rounding difference)
#   the bearer: IE_FP_BEARER, or IE_FP_OIDC_TOKEN_URL + _CLIENT_ID + _CLIENT_SECRET (lib/estate-token.sh)
#
# Flags:
#   --save            print the workbook's rows as a fingerprint block, and write them to IE_FP_SAVE_DIR
#                     if set — ⛔ never inside this repository: it is public, and a fingerprint holds a
#                     real portfolio's balances (S3.3·D8). They live in the private project repo.
#   --expect <json>   ALSO compare against kantheon's expectations.json (the fixture estate — T4)

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/estate-token.sh
. "$HERE/lib/estate-token.sh"

fail() { printf '\n\033[31m✗ %s\033[0m\n' "$*" >&2; exit 1; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
step() { printf '\n\033[1m── %s\033[0m\n' "$*"; }

SAVE=""
EXPECT=""
while [ $# -gt 0 ]; do
    case "$1" in
        --save) SAVE=1; shift ;;
        # ⚑ No apostrophe in this message: inside ${…:?word} it opens a quote, and bash then misparses
        # everything after it — the error lands lines later, on the first bare parenthesis.
        --expect) EXPECT="${2:?--expect needs a path to the expectations JSON}"; shift 2 ;;
        *) fail "unknown argument '$1' (--save, --expect <json>)" ;;
    esac
done

BFF="${IE_FP_BFF:?IE_FP_BFF is required (studio-bff base URL)}"
DSN="${IE_FP_DSN:?IE_FP_DSN is required (psql DSN for the entry database)}"
PORTFOLIO="${IE_FP_PORTFOLIO:?IE_FP_PORTFOLIO is required — name the portfolio explicitly}"
AS_OF="${IE_FP_AS_OF:-$(date -u +%F)}"
QUARTERS="${IE_FP_QUARTERS:-4}"
MODEL="${IE_FP_MODEL:-$HERE/../model/investment/queries/q_investment.ttrm}"
TEMPLATE="${IE_FP_TEMPLATE:-investment-evolution:v1}"
TOLERANCE="${IE_FP_TOLERANCE:-0.01}"
# The return is a ratio of two rounded figures and inherits their difference amplified — measured on
# hartland: money equal to the cent, return apart by 0.000008 percentage points. The sheet prints two
# decimals, so a ten-thousandth of a point is invisible to a reader and still orders of magnitude
# tighter than any real error.
RETURN_TOLERANCE="${IE_FP_RETURN_TOLERANCE:-0.0001}"
ENGINE="$HERE/lib/fingerprint.py"

for tool in curl jq psql python3; do command -v "$tool" >/dev/null || fail "$tool is not on PATH"; done
[ -f "$MODEL" ] || fail "no model file at $MODEL — this reads the reference query from the SYNCED model"

[[ "$AS_OF" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || fail "IE_FP_AS_OF must be YYYY-MM-DD, not '$AS_OF'"
[[ "$QUARTERS" =~ ^[0-9]+$ ]] && [ "$QUARTERS" -ge 1 ] && [ "$QUARTERS" -le 12 ] \
    || fail "IE_FP_QUARTERS must be 1..12 (the template's own bounds), not '$QUARTERS'"
# Ids are spliced into SQL; none of the estate's carries a quote, so one that does is a typo.
case "$PORTFOLIO" in *"'"*) fail "a portfolio id containing a quote: '$PORTFOLIO'" ;; esac

# ⛔ An `as_of` that IS a quarter end is refused, and the refusal is the finding (S3.1·D2): the
# reference query derives its grid from `date_trunc`, so it reports that day TWICE — once whole, once
# as the partial row — while the renderer follows IE-C30's "≤" and reports it once. Comparing them on
# such a date would report a defect that is a ruled difference. Any other day, the two agree exactly.
quarter_end() {
    python3 - "$1" <<'PY'
import sys
from datetime import date, timedelta
d = date.fromisoformat(sys.argv[1])
print("yes" if (d + timedelta(days=1)).month % 3 == 1 and (d + timedelta(days=1)).day == 1 else "no")
PY
}
[ "$(quarter_end "$AS_OF")" = "no" ] || fail \
    "IE_FP_AS_OF=$AS_OF is a quarter end, where the reference reports the day twice and the renderer once (S3.1·D2) — use any other day"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

BEARER="$(estate_token IE_FP)" || fail "no bearer for studio-bff"

# ── 1. render it, the way the Reports tile does ──────────────────────────────────────────────────

step "1. render $TEMPLATE through studio-bff"

ARGS="$(jq -nc --arg p "$PORTFOLIO" --arg a "$AS_OF" --arg q "$QUARTERS" \
    '{portfolio_id: $p, as_of: $a, quarters: $q}')"
http="$(curl -sS -o "$WORK/render.json" -w '%{http_code}' -X POST "$BFF/api/reports/render" \
    -H "authorization: Bearer $BEARER" -H 'content-type: application/json' \
    --data "$(jq -nc --arg t "$TEMPLATE" --argjson args "$ARGS" '{templateId: $t, args: $args}')" || true)"
if [ "$http" != "200" ]; then
    # The renderer's own code and sentence survive the hop (IE-P3·S3.2) — print them, not a summary.
    fail "render failed: HTTP $http $(jq -r '.code // "?"' "$WORK/render.json" 2>/dev/null) — $(jq -r '.message // ""' "$WORK/render.json" 2>/dev/null)"
fi
ARTIFACT="$(jq -r '.artifactId // empty' "$WORK/render.json")"
[ -n "$ARTIFACT" ] || fail "the render answered no artifactId: $(head -c 400 "$WORK/render.json")"
ok "rendered $(jq -r '.sizeBytes // "?"' "$WORK/render.json") bytes, artifact $ARTIFACT"

http="$(curl -sS -o "$WORK/report.xlsx" -w '%{http_code}' \
    "$BFF/api/reports/artifacts/$ARTIFACT?asOf=$AS_OF" -H "authorization: Bearer $BEARER" || true)"
[ "$http" = "200" ] || fail "downloading the artifact failed: HTTP $http"
# A workbook is a zip; anything else means an error body arrived wearing a workbook's name.
head -c 2 "$WORK/report.xlsx" | grep -q 'PK' || fail "the artifact is not a zip — $(head -c 200 "$WORK/report.xlsx")"
ok "downloaded $(wc -c <"$WORK/report.xlsx" | tr -d ' ') bytes"

python3 "$ENGINE" sheet "$WORK/report.xlsx" >"$WORK/workbook.csv" || fail "could not read the Summary sheet"
ok "the Summary holds $(($(wc -l <"$WORK/workbook.csv") - 1)) quarter rows"

# ── 2. the same question, put to the book ────────────────────────────────────────────────────────

step "2. the reference query, on the book"

# The reference SQL, lifted from the synced model: everything between `sourceText: """` and its
# closing fence, inside `def query quarterly_evolution`.
awk '
    $0 ~ /def query quarterly_evolution[[:space:]]*\{/ { inq = 1 }
    inq && /sourceText:[[:space:]]*"""/ { insql = 1; next }
    insql && /^[[:space:]]*"""[[:space:]]*$/ { exit }
    insql { print }
' "$MODEL" >"$WORK/reference.sql"
[ -s "$WORK/reference.sql" ] || fail "no quarterly_evolution sourceText in $MODEL"

# Its three parameters, bound as literals. The door binds these natively; psql needs them spliced,
# and the ids were refused a quote above.
sed -e "s/{portfolio_id}/'$PORTFOLIO'/g" -e "s/{as_of}/'$AS_OF'/g" -e "s/{quarters}/$QUARTERS/g" \
    "$WORK/reference.sql" >"$WORK/reference.bound.sql"
grep -q '{[a-z_]*}' "$WORK/reference.bound.sql" && fail \
    "the reference query has a parameter this script does not bind: $(grep -o '{[a-z_]*}' "$WORK/reference.bound.sql" | sort -u | tr '\n' ' ')"

psql "$DSN" -X -q -t -A -F',' -f "$WORK/reference.bound.sql" >"$WORK/reference.csv" \
    || fail "the reference query did not run on the book"
python3 "$ENGINE" reference "$WORK/reference.csv" >"$WORK/reference.canonical.csv" \
    || fail "the reference answered a shape this cannot read"
ok "the book answers $(($(wc -l <"$WORK/reference.canonical.csv") - 1)) quarter rows"

# ── 3. do they agree? ────────────────────────────────────────────────────────────────────────────

step "3. the workbook against the book"

python3 "$ENGINE" compare "$WORK/workbook.csv" "$WORK/reference.canonical.csv" \
    --tolerance "$TOLERANCE" --return-tolerance "$RETURN_TOLERANCE" --label-a workbook --label-b book \
    || fail "the report a client receives does not match the book"

if [ -n "$EXPECT" ]; then
    # The third side, on the fixture estate: kantheon's hand-computed expectations (IE-C28).
    python3 "$ENGINE" expect "$WORK/workbook.csv" "$EXPECT" "$PORTFOLIO" \
        || fail "the workbook does not match the hand-computed expectations"
fi

# Whether a path — which need not exist yet — falls inside THIS repository.
inside_this_repo() {
    local target repo
    target="$(python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$1")"
    repo="$(python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$HERE/..")"
    case "$target/" in "$repo"/*) return 0 ;; esac
    return 1
}

if [ -n "$SAVE" ]; then
    slug="$(printf '%s' "$TEMPLATE" | tr ':' '-')-$(printf '%s' "$PORTFOLIO" | tr ':' '-')-$AS_OF.csv"
    # ⛔ RULED by Bora 2026-09-14 (IE-P3·S3.3·D8): a fingerprint is a REAL portfolio's quarterly balances,
    # and this repository is PUBLIC. So it is never written in here — the rehearsal fingerprints live in
    # the private project repository.
    #
    # `--save` therefore PRINTS the block, always: the run that matters happens in a pod whose filesystem
    # goes away with the Job, and `drill-in-cluster.sh` lifts the block out of the log into the private
    # repo. A file is written only where IE_FP_SAVE_DIR points — and refused inside this repository.
    if [ -n "${IE_FP_SAVE_DIR:-}" ]; then
        dest="$IE_FP_SAVE_DIR/$slug"
        if inside_this_repo "$dest"; then
            fail "IE_FP_SAVE_DIR ($IE_FP_SAVE_DIR) is inside this repository, which is PUBLIC — a fingerprint holds a real portfolio's balances (S3.3·D8). Point it at the private project repo."
        fi
        mkdir -p "$(dirname "$dest")"
        cp "$WORK/workbook.csv" "$dest"
        ok "fingerprint saved: $dest"
    fi
    printf -- '-----BEGIN FINGERPRINT %s-----\n' "$slug"
    cat "$WORK/workbook.csv"
    printf -- '-----END FINGERPRINT-----\n'
fi

printf '\n\033[32mthe report matches the book — %s, %s quarters to %s\033[0m\n' "$PORTFOLIO" "$QUARTERS" "$AS_OF"
