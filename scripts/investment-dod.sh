#!/usr/bin/env bash
# IE-P2·S2.4·T2 — `just investment-dod`: the estate answers, and it answers DIFFERENTLY after a
# correction and an addition.
#
# ## What this proves that the unit suites cannot
#
# kantheon's `conform-investment-queries` runs the seven programs' SOURCE text on psql. That is a
# different thing from what a person does, in three ways this script covers and that one does not:
#
#   1. It goes through the DOOR — Calcite parse, plan.v1 encode, unparse, worker — so it sees the
#      text the estate actually executes. S2.3·D18 and D19 both lived only there.
#   2. It goes through the BFF with a BEARER, so identity, routing and the program resolver are on
#      the path.
#   3. It WRITES, through the same ledger the connector writes through, and then re-reads. A read
#      suite cannot show that a correction leaves the portfolio's holdings unchanged while its
#      money moves — which is the single most demo-visible property of the whole estate.
#
# ⛔ AFTER A WRITE, "UNCHANGED" IS NEVER EVIDENCE. A door that never sees the write answers every
# "nothing moved" check correctly. So each write is also asserted through the door as something
# that MUST have changed — the replacement present with its new amount, the original gone, the
# deposit listed — and the "unchanged" checks are kept as the rules they are, not as proof.
#
# Its own suite (scripts/tests/investment-dod.test.mjs) drives it against a stub BFF that answers
# wrongly on purpose, which is the only way to know each of these checks can fail.
#
# ## Modes
#
#   IE_DOD_MODE=full      read + the three write drills   (a local estate, or a THROWAWAY portfolio)
#   IE_DOD_MODE=readonly  read only                       (hartland, against a real book)
#
# Exactly one of those two words; anything else is refused before a single request is sent.
#
# ⛔ `full` WRITES TO THE LEDGER, and a ledger is append-only: the two drills leave three permanent
# rows behind (a reversal, a replacement, a deposit). Point it at a portfolio you are willing to
# leave marked. It refuses to run `full` without `IE_DOD_PORTFOLIO` set explicitly for that reason —
# there is no default, because a default here is a way to write to the wrong book.
#
# Env:
#   IE_DOD_BFF        base URL of studio-bff        (e.g. http://127.0.0.1:7330)
#   IE_DOD_BEARER     a bearer the BFF verifies
#   IE_DOD_DSN        psql DSN for the `entry` database (the counts this script checks the door against)
#   IE_DOD_PORTFOLIO  the portfolio to read, and in `full` mode to write to
#   IE_DOD_MODE       full | readonly                (default readonly)
#   IE_DOD_TOP_N      the estate's governance cap on rows per answer, if it has one — hartland sets
#                     `VALIDATE_DEFAULT_TOP_N=200` (IE-P3·S3.0·T1; it was 100). The validator injects a
#                     LIMIT on every plan, so a SINGLE read of a long ledger is a window on it: set
#                     this and the single-read checks expect `min(book, cap)`; leave it unset for an
#                     uncapped estate. It also sizes the PAGED read, which must see the whole ledger:
#                     pages of `cap − 1` rows (200 − 1 when unset). Read the live value from validate's
#                     `/status`, or from `olymp/clusters/hartland/apps/validate/values.yaml`.
#   IE_DOD_HOLD_ONLY  1 to journal the CORRECTION and STOP before committing it, leaving the batch
#                     held in the Inbox for a person to preview and commit. That is the rehearsal
#                     shape of the beat: S2.4·D6 was ruled (a) — a correction is PROPOSED as a batch
#                     and COMMITTED BY A HUMAN in the Inbox, which is the path Dan took at IE-P1·S1.5
#                     and the only correction path the Studio actually has. The script asserts up to
#                     the hold, then prints the exact command for the second half (below).
#   IE_DOD_MOVEMENT   the movement whose correction a person has ALREADY committed — the second half
#                     of a HOLD_ONLY run. Nothing is journalled for it: the run asserts that
#                     correction, through the book and through the door, and then runs the addition
#                     and refusal drills. `full` only.

set -euo pipefail

fail() { printf '\n\033[31m✗ %s\033[0m\n' "$*" >&2; exit 1; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
step() { printf '\n\033[1m── %s\033[0m\n' "$*"; }

BFF="${IE_DOD_BFF:?IE_DOD_BFF is required (studio-bff base URL)}"
BEARER="${IE_DOD_BEARER:?IE_DOD_BEARER is required}"
DSN="${IE_DOD_DSN:?IE_DOD_DSN is required (psql DSN for the entry database)}"
PORTFOLIO="${IE_DOD_PORTFOLIO:?IE_DOD_PORTFOLIO is required — name the portfolio explicitly}"
MODE="${IE_DOD_MODE:-readonly}"
HOLD_ONLY="${IE_DOD_HOLD_ONLY:-}"
NAMED="${IE_DOD_MOVEMENT:-}"
TOP_N="${IE_DOD_TOP_N:-}"
TODAY="$(date -u +%F)"

# ⛔ EXACTLY `readonly` or `full`, before anything is sent. The test used to be `= readonly` with
# everything else falling through to the write drills, so `read-only`, `ro` or `READONLY` wrote
# three permanent rows to whichever book the portfolio named.
case "$MODE" in
    readonly|full) ;;
    *) fail "IE_DOD_MODE must be exactly 'readonly' or 'full', not '$MODE' — nothing was sent" ;;
esac
if [ -n "$NAMED" ]; then
    [ "$MODE" = "full" ] || fail "IE_DOD_MOVEMENT asserts a committed correction and then runs the addition drill — it needs IE_DOD_MODE=full"
    [ -z "$HOLD_ONLY" ] || fail "IE_DOD_MOVEMENT (assert a committed correction) and IE_DOD_HOLD_ONLY (journal a new one and stop) cannot both be set"
fi
# The cap sizes the paged read, so it has to be a number a page can be built from.
if [ -n "$TOP_N" ]; then
    { [[ "$TOP_N" =~ ^[0-9]+$ ]] && [ "$TOP_N" -ge 2 ]; } || fail "IE_DOD_TOP_N must be an integer >= 2, not '$TOP_N' — nothing was sent"
fi
# ⛔ The paged read's page is the cap MINUS ONE. studio-bff asks the pipeline for `limit + 1` rows — the
# probe row that sets `truncated` — so a page of exactly the cap would ask for cap + 1 and be cut every
# time. At cap − 1 the estate grants each page whole and `truncated` alone says whether there is more.
PAGE_ROWS=$(( ${TOP_N:-200} - 1 ))
# Every id below is spliced into SQL text. None of the estate's ids carries a quote, so one that does
# is a typo — and would otherwise become a different statement.
case "$PORTFOLIO$NAMED" in *"'"*) fail "a portfolio or movement id containing a quote: '$PORTFOLIO' '$NAMED'" ;; esac

for tool in curl jq psql; do command -v "$tool" >/dev/null || fail "$tool is not on PATH"; done

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# ── the door ─────────────────────────────────────────────────────────────────────────────────────

# `request <program> <params-json> [limit] [offset]` → the HTTP status on stdout (curl's `000` when
# nothing answered), the body in $WORK/run.json. It never fails: what an answer means is the caller's
# decision. `offset` rides the body only when it is not 0 — §2.1's row window, IE-P3·S3.0.
request() {
    local body http
    body="$(jq -nc --arg p "$1" --argjson params "$2" --argjson limit "${3:-10000}" --argjson offset "${4:-0}" \
        '{program: $p, params: $params, limit: $limit} + (if $offset > 0 then {offset: $offset} else {} end)')"
    rm -f "$WORK/run.json"
    http="$(curl -sS -o "$WORK/run.json" -w '%{http_code}' \
        -X POST "$BFF/api/query/run" \
        -H "authorization: Bearer $BEARER" \
        -H 'content-type: application/json' \
        --data "$body" 2>"$WORK/curl.err" || true)"
    printf '%s' "${http:-000}"
}

# `run <program> <params-json> [limit] [offset]` → the §2.2 answer, or a non-zero exit naming the
# BFF's own code.
run() {
    local http code
    http="$(request "$1" "$2" "${3:-10000}" "${4:-0}")"
    if [ "$http" != "200" ]; then
        code="$(jq -r '.code // "?"' "$WORK/run.json" 2>/dev/null || echo '?')"
        printf 'HTTP %s %s — %s\n' "$http" "$code" "$(jq -r '.message // ""' "$WORK/run.json" 2>/dev/null || cat "$WORK/curl.err")" >&2
        return 1
    fi
    cat "$WORK/run.json"
}

# `run_all <program> <params-json>` → the program's WHOLE answer, read through the row window (§2.1
# `limit` + `offset`, PAGE_ROWS rows a page) as one §2.2-shaped answer with a `pages` count. IE-P3·S3.0·T7.
#
# ⛔ Two ways a paged read goes wrong WITHOUT an error, and both are refused here, naming themselves:
#   · a BFF that IGNORES `offset` (one older than the row window) answers page one for every page, so
#     the drill would count page one over and over;
#   · a page carrying `top_n_applied` was CUT by the estate below what the drill asked — its cap is lower
#     than IE_DOD_TOP_N says, and the page did not end where the data did. Paging on would be guessing.
run_all() {
    local program="$1" params="$2" offset=0 pages=0 page rc first="" page_first notice
    local acc="$WORK/pages.json"
    echo '[]' >"$acc"
    while :; do
        page="$(run "$program" "$params" "$PAGE_ROWS" "$offset")" || return 1
        pages=$((pages + 1))
        notice="$(jq -r '[.messages[]? | select(.code == "top_n_applied") | .text][0] // empty' <<<"$page")"
        if [ -n "$notice" ]; then
            printf 'page %s of %s (from row %s) was cut by the estate: "%s" — its cap is below the declared IE_DOD_TOP_N=%s\n' \
                "$pages" "$program" "$offset" "$notice" "${TOP_N:-200 (the default)}" >&2
            return 1
        fi
        rc="$(jq -r '.rowCount' <<<"$page")"
        page_first="$(jq -c '.rows[0] // null' <<<"$page")"
        if [ "$pages" -eq 1 ]; then
            first="$page_first"
        elif [ "$page_first" = "$first" ] && [ "$first" != "null" ]; then
            printf 'page %s of %s (from row %s) repeats page 1 — the BFF ignored `offset`: studio-bff predates the row window (IE-P3·S3.0)\n' \
                "$pages" "$program" "$offset" >&2
            return 1
        fi
        jq -c --slurpfile acc "$acc" '$acc[0] + [.]' <<<"$page" >"$acc.next" && mv "$acc.next" "$acc"
        { [ "$(jq -r '.truncated' <<<"$page")" = "true" ] && [ "$rc" -gt 0 ]; } || break
        offset=$((offset + rc))
        [ "$pages" -lt 10000 ] || { echo "$program: 10000 pages and the answer has not ended" >&2; return 1; }
    done
    jq -c '{columns: .[0].columns, rows: (map(.rows) | add), pages: length}
           | .rowCount = (.rows | length) | .truncated = false' "$acc"
}

# ⛔ EVERY COLUMN IS READ BY NAME, never by position. A query rewrite that reorders a projection must
# not silently move this script onto a different number (kantheon T1.18 makes a rename loud; this
# makes the script indifferent to a reorder). `need` fails, naming the column, when one is missing.
JQ_LIB='
  def need($cols): (.columns | map(.name)) as $n | ($cols - $n) as $m
    | if ($m | length) > 0 then error("the answer has no column \($m | join(", "))") else . end;
  def objs: (.columns | map(.name)) as $n | [.rows[] | [$n, .] | transpose | map({(.[0]): .[1]}) | add];
  def num: if . == null then null else tonumber end;'

# `where <answer> <column> <value>` → the rows whose <column> is <value>, as objects keyed by name.
where() { jq -c --arg c "$2" --arg v "$3" "$JQ_LIB"' need([$c]) | [objs[] | select((.[$c] | tostring) == $v)]' <<<"$1"; }
# `holdings <positions_at answer>` → every line's quantity by line_id: the WHOLE answer, not row 0.
holdings() { jq -c "$JQ_LIB"' need(["line_id", "quantity"]) | [objs[] | [.line_id, (.quantity | num)]] | sort' <<<"$1"; }
# `cash_by_ccy <cash_balance answer>` → every currency's balance.
cash_by_ccy() { jq -c "$JQ_LIB"' need(["currency", "cash_balance"]) | [objs[] | [.currency, (.cash_balance | num)]] | sort' <<<"$1"; }
rows() { jq -r '.rowCount' <<<"$1"; }
# Two decimals are the same number, however each side spells it ("1601.27", 1601.27, "1601.270000").
num_eq() { jq -en --arg a "$1" --arg b "$2" '($a | tonumber) == ($b | tonumber)' >/dev/null 2>&1; }

# `micros <decimal>` → the value in millionths, as an integer. Money that is SUBTRACTED is compared as
# money: a double cannot hold 12345.67, and `after − before` in floating point is not the deposit.
micros() {
    [[ "$1" =~ ^(-?)([0-9]+)(\.([0-9]{1,6}))?$ ]] || { echo "not a decimal of at most 6 places: '$1'" >&2; return 1; }
    local frac="${BASH_REMATCH[4]}000000"
    printf '%s%d\n' "${BASH_REMATCH[1]}" "$((10#${BASH_REMATCH[2]} * 1000000 + 10#${frac:0:6}))"
}

q() { psql "$DSN" -X -q -t -A -c "$1"; }

# The effective ledger, counted in the book with the rule inlined: no reversal row, and no row that a
# reversal cancels.
book_effective() {
    q "
  SELECT count(*) FROM investment_transaction t
   WHERE t.portfolio_ref = '$PORTFOLIO'
     AND t.reversal_of IS NULL
     AND NOT EXISTS (SELECT 1 FROM investment_transaction r WHERE r.reversal_of = t.external_id)"
}
book_rows() { q "SELECT count(*) FROM investment_transaction WHERE portfolio_ref = '$PORTFOLIO'"; }
# What the door should return from the book's `n` effective rows: all of them, or the cap.
capped() { if [ -n "$TOP_N" ] && [ "$1" -gt "$TOP_N" ]; then echo "$TOP_N"; else echo "$1"; fi; }

# ── 1. the seven programs, through the door ──────────────────────────────────────────────────────

step "1. the estate answers (IE-C28 §3.8b)"

declare -A ANSWER
for spec in \
    "positions_current:{\"portfolio_id\":\"$PORTFOLIO\"}" \
    "cash_balance:{\"portfolio_id\":\"$PORTFOLIO\",\"as_of\":\"$TODAY\"}" \
    "transactions_recent:{\"portfolio_id\":\"$PORTFOLIO\",\"since\":\"2000-01-01\"}" \
    "positions_at:{\"portfolio_id\":\"$PORTFOLIO\",\"as_of\":\"$TODAY\"}"
do
    name="${spec%%:*}"; params="${spec#*:}"
    answer="$(run "q.investment.$name" "$params")" || fail "$name did not answer"
    ANSWER[$name]="$answer"
    ok "$(printf '%-22s rows %-6s cols %s' "$name" "$(rows "$answer")" "$(jq -r '.columns | length' <<<"$answer")")"
done

# ⛔ The door's count is checked against the DATABASE's, with the effective-ledger rule inlined. The
# programs and this query are two independent statements of the same rule; if they ever disagree,
# one of them is wrong and a suite that only asked the door would believe whichever it asked.
door_txns="$(rows "${ANSWER[transactions_recent]}")"
db_txns="$(book_effective)"

# ⛔ THE WHOLE LEDGER, THROUGH THE ROW WINDOW — IE-P3·S3.0·T7, on Bora's S2.4·D9 ruling ("set the
# default to 200 and page over it"). Wherever the estate caps answers a single read is a WINDOW on the
# ledger; paging reads all of it, and THIS is the count that has to equal the book's — the full one,
# not `min(book, cap)`. Checked for repeats as well as the count: a page boundary over a sort that can
# tie shows one movement twice and loses another, and the total still matches (kantheon T1.19 is what
# keeps every program's sort total). Before the single-read check, so that an estate capping below the
# declared cap is named as exactly that.
ALL_TXNS="$(run_all "q.investment.transactions_recent" "{\"portfolio_id\":\"$PORTFOLIO\",\"since\":\"2000-01-01\"}")" \
    || fail "transactions_recent could not be read WHOLE through the row window (see above)"
paged="$(rows "$ALL_TXNS")"
paged_pages="$(jq -r '.pages' <<<"$ALL_TXNS")"
paged_distinct="$(jq -r "$JQ_LIB"' need(["transaction_id"]) | [objs[].transaction_id] | unique | length' <<<"$ALL_TXNS")" \
    || fail "the paged answer has no transaction_id column"
[ "$paged" = "$db_txns" ] \
    || fail "transactions_recent read through the row window says $paged effective rows in $paged_pages page(s); the book holds $db_txns"
[ "$paged_distinct" = "$paged" ] \
    || fail "the paged read shows $paged rows but only $paged_distinct distinct movements — a page boundary repeated one and skipped another"
ok "the door and the book agree at the FULL count: $paged effective movements, read in $paged_pages page(s) of up to $PAGE_ROWS rows"

# ⛔ THE ESTATE MAY CAP THE ANSWER, AND ON hartland IT DOES — S2.4·D9. `validate` enforces a TopN
# rule by INJECTING a `LIMIT <cap>` into every plan that has none, and the cap is a hard ceiling:
# `effectiveCap = min(requested, serviceDefault)`, so a caller can ask for fewer rows and never for
# more. hartland sets it to 100 on purpose — its own values file calls it "the governance beat in the
# demo narrative".
#
# ⛔ It is applied SILENTLY. `RuleEnforcer` appends a message for a column rule and none for TopN, so
# the answer comes back with `truncated: false` (the BFF's own limit was never reached) and 100 rows
# of 835, presented as the whole ledger. That is the comparison below existing: without it the door
# says "here is the effective ledger" and a reader has no way to know it is a tenth of one.
expected_txns="$(capped "$db_txns")"
if [ "$door_txns" != "$expected_txns" ]; then
    if [ -z "$TOP_N" ] && [ "$door_txns" -lt "$db_txns" ]; then
        echo "   ⚑ the door returned FEWER rows than the book holds, and no IE_DOD_TOP_N was declared." >&2
        echo "     This estate probably caps answers. Check it and re-run with the cap declared:" >&2
        echo "       kubectl --context hartland -n ttr-server get deploy validate \\" >&2
        echo "         -o jsonpath='{.spec.template.spec.containers[0].env[*]}' | tr '}' '\\n' | grep TOP_N" >&2
    fi
    fail "transactions_recent says $door_txns effective rows, expected $expected_txns (the book holds $db_txns)"
fi
if [ "$expected_txns" != "$db_txns" ]; then
    ok "the door and the book agree at the cap: $door_txns of $db_txns effective movements (TopN $TOP_N)"
    # ⛔ Said out loud every run. Since IE-P3·S3.0 the estate says it too — a capped answer carries
    # `top_n_applied` — and WHETHER it did is itself a check: an estate that caps silently is still
    # running the validate/query images S2.4·D9 was found on.
    if jq -e '[.messages[]? | select(.code == "top_n_applied")] | length > 0' <<<"${ANSWER[transactions_recent]}" >/dev/null; then
        printf '     \033[33m⚑ the estate capped this single read at %s rows, and SAID so (top_n_applied).\033[0m\n' "$TOP_N"
        printf '       %s of %s movements were left out of it; the paged read above has every one.\n' \
            "$((db_txns - TOP_N))" "$db_txns"
    else
        printf '     \033[33m⚑ the estate CAPPED this answer at %s rows and reported truncated=false, SILENTLY.\033[0m\n' "$TOP_N"
        printf '       %s of the portfolio'"'"'s %s effective movements were withheld with no warning (S2.4·D9) —\n' \
            "$((db_txns - TOP_N))" "$db_txns"
        printf '       this estate'"'"'s validate/query predate the row window (IE-P3·S3.0).\n'
    fi
else
    ok "the door and the book agree: $db_txns effective movements"
fi

# ⚑ positions_at's LAST column is `line_rank` since S2.3·D18 (0 = holding, 1 = cash). Asserted,
# because it is a declared part of the answer now and a silent drop would mean the sort key had gone
# back to being hoisted anonymously.
[ "$(jq -r '.columns[-1].name' <<<"${ANSWER[positions_at]}")" = "line_rank" ] \
    || fail "positions_at's last column is not line_rank — S2.3·D18 has regressed"
ok "positions_at declares its sort key (line_rank)"

# ⛔ THE DOOR'S PRICE IS THE BOOK'S PRICE, to 6 dp. `positions_at` casts `last_price` to FLOAT as a
# workaround for Collite/tatrman-server#83 — an unconstrained NUMERIC was read at scale 0, so 2.1031
# came back as 2 — and nothing offline can say when that cast may come off. This is the check that
# can: every holding line's price against the book's latest `investment_asset_price` on or before
# today. A line the book has never priced must be unpriced at the door too.
price_lines="$(jq -r "$JQ_LIB"' need(["line_id", "last_price", "line_rank"])
    | objs[] | select((.line_rank | tostring) == "0") | [.line_id, (.last_price // "" | tostring)] | @tsv' \
    <<<"${ANSWER[positions_at]}")" || fail "positions_at does not carry the columns the price check reads"
priced=0
while IFS=$'\t' read -r line_id door_price; do
    [ -n "$line_id" ] || continue
    case "$line_id" in *"'"*) fail "positions_at answered a line id containing a quote: $line_id" ;; esac
    book_price="$(q "
  SELECT p.price FROM investment_asset_price p
   WHERE p.isin = '$line_id' AND p.price_date <= '$TODAY'
   ORDER BY p.price_date DESC LIMIT 1")"
    [ -z "$door_price" ] && [ -z "$book_price" ] && continue
    if [ -z "$door_price" ] || [ -z "$book_price" ] || ! jq -en --arg a "$door_price" --arg b "$book_price" \
        '(($a | tonumber) * 1000000 | round) == (($b | tonumber) * 1000000 | round)' >/dev/null 2>&1; then
        fail "positions_at prices $line_id at ${door_price:-NULL}; the book's latest price on or before $TODAY is ${book_price:-none}. A whole number where the book has decimals is Collite/tatrman-server#83's scale-0 read"
    fi
    priced=$((priced + 1))
done <<<"$price_lines"
ok "every holding's last_price is the book's latest price, to 6 dp ($priced priced line(s))"

# ⚑ quarterly_evolution is EXPECTED to be refused, by ruling (⚑IE-15 = a): it needs a quarter-end
# grid derived from as_of and the wire format has no date arithmetic. Asserted as THAT refusal — the
# status and the code — because a 401, a 5xx or a dropped connection is also "not 200", and proves
# nothing about the ruling. The day it starts working, this script tells someone.
qevo_http="$(request "q.investment.quarterly_evolution" "{\"portfolio_id\":\"$PORTFOLIO\",\"as_of\":\"$TODAY\",\"quarters\":4}")"
qevo_code="$(jq -r '.code // "?"' "$WORK/run.json" 2>/dev/null || echo '?')"
[ "$qevo_http" != "200" ] || fail "quarterly_evolution COMPILED — ⚑IE-15 was ruled (a) on the premise that it cannot; re-read the ruling"
[ "$qevo_http" = "404" ] && [ "$qevo_code" = "PROGRAM_NOT_COMPILABLE" ] \
    || fail "quarterly_evolution answered HTTP $qevo_http $qevo_code, expected 404 PROGRAM_NOT_COMPILABLE — any other failure is not the ruled refusal"
ok "quarterly_evolution refuses with 404 PROGRAM_NOT_COMPILABLE, as ⚑IE-15 ruled it would"

if [ "$MODE" = "readonly" ]; then
    printf '\n\033[1mreadonly mode — the three write drills were skipped.\033[0m\n'
    printf 'Run with IE_DOD_MODE=full against a THROWAWAY portfolio to exercise the ledger.\n'
    exit 0
fi

# ── 2. the correction drill ──────────────────────────────────────────────────────────────────────

step "2. correcting one movement (reverse-and-replace)"

BEFORE_ROWS="$(book_rows)"
BEFORE_HOLDINGS="$(holdings "${ANSWER[positions_at]}")" || fail "positions_at cannot be read by line_id and quantity"
BEFORE_CASH="$(cash_by_ccy "${ANSWER[cash_balance]}")" || fail "cash_balance cannot be read by currency"

if [ -n "$NAMED" ]; then
    # The second half of a HOLD_ONLY run: a person has committed the correction in the Inbox, and this
    # run asserts THAT one rather than picking a movement of its own.
    MOVEMENT="$NAMED"
    [ "$(q "SELECT count(*) FROM investment_transaction WHERE external_id = '$MOVEMENT' AND portfolio_ref = '$PORTFOLIO' AND reversal_of IS NULL")" = "1" ] \
        || fail "IE_DOD_MOVEMENT=$MOVEMENT is not a movement of $PORTFOLIO"
    [ "$(q "SELECT count(*) FROM investment_transaction WHERE external_id = '$MOVEMENT-rev' AND reversal_of = '$MOVEMENT'")" = "1" ] \
        || fail "the correction of $MOVEMENT has not been committed — there is no $MOVEMENT-rev in the book. Commit it in the Inbox (/e/inbox?state=held), then re-run"
else
    # The movement to correct: the latest security/buy of the portfolio that
    #   · is not itself a reversal (reversal_of IS NULL);
    #   · is not a REPLACEMENT an earlier correction wrote. `X-rep` keeps X's trade date and has no
    #     reversal of its own, so without this clause a re-run picks the previous run's `X-rep` —
    #     legal ledger behaviour (it yields `X-rep-rev` / `X-rep-rep`), but it re-corrects the last
    #     run's row instead of reaching the next buy;
    #   · has never been corrected: no row reverses it. That clause is the chain guard — the substrate
    #     refuses a second correction of X because `X-rev` exists, and `X-rev` is exactly the row
    #     whose reversal_of is X.
    MOVEMENT="$(q "
  SELECT t.external_id FROM investment_transaction t
   WHERE t.portfolio_ref = '$PORTFOLIO' AND t.leg = 'security' AND t.operation = 'buy'
     AND t.reversal_of IS NULL
     AND t.external_id NOT LIKE '%-rep'
     AND NOT EXISTS (SELECT 1 FROM investment_transaction r WHERE r.reversal_of = t.external_id)
   ORDER BY t.trade_date DESC, t.external_id DESC LIMIT 1")"
    [ -n "$MOVEMENT" ] || fail "no uncorrected security/buy movement on $PORTFOLIO to correct"
fi
OLD_AMOUNT="$(q "SELECT amount FROM investment_transaction WHERE external_id = '$MOVEMENT'")"
# The drill's correction is always `amount + 1.11` of the original, which an append-only ledger never
# rewrites — so a named re-run states what the committed replacement must carry by the same rule that
# built the held batch.
NEW_AMOUNT="$(q "SELECT (amount + 1.11)::text FROM investment_transaction WHERE external_id = '$MOVEMENT'")"

# §5 `row-proposal`. `key` identifies, `values` restates; `baseRowVersion` is null — see T5's note,
# the read path does not expose one and the import precedent (DR-S1.3) is to send null.
# One §5 `row-proposal`, one proposal.
#
# ⚑ `pluginId` and `pluginVersion` are REQUIRED — nullable, but PRESENT — exactly as `key`,
# `baseRowVersion` and `effectiveDate` are on a proposal. Omitting them is `BATCH_SCHEMA_INVALID`,
# not a default. Found by running this against a real substrate, which is the only place it shows.
#
# ⛔ The target is `{ entity, lowering: "v1" }`, and BOTH halves of that were learned by running it.
#
#   { table: "investment_transaction" }              -> NO_APPLY_PROGRAM
#   { table: "investment.transaction" }              -> SQLSTATE 42P01, relation does not exist
#   { entity: "investment.transaction", lowering: "v1" }  -> correct
#
# `programs.json` registers the ledger program under the ENTITY qname, so a physical table name
# finds no program; but a `{table}` target is used VERBATIM as a relation name, so putting the qname
# in the table slot finds the program and then asks PostgreSQL for a table called
# `investment.transaction`. Only the entity form does both jobs — §5's `oneOf` exists for exactly
# this, and `writability.json` is what lowers it to `investment_transaction`.
#
# ⚑ The authored form kantheon ships spells its own target `{ "table": "investment.transaction" }`,
# which is the SECOND of those three — so a batch assembled from it would fail the same way. That is
# S2.4·D6's third leg: the form path has never been run end to end.
#
# ⛔ And nothing inside the jq program below may contain an APOSTROPHE: it is a single-quoted shell
# string, so one closes it and the rest of the function becomes unquoted shell. That cost a syntax
# error at a line forty lines further down than the mistake.
batch() {
    jq -nc --arg id "$1" --arg op "$2" --argjson key "$3" --argjson values "$4" '
      { batchId: ("ie-dod-" + (now | floor | tostring) + "-" + $id),
        kind: "row-proposal",
        target: { entity: "investment.transaction", lowering: "v1" },
        modelVersion: "investment-v1",
        proposals: [ { op: $op, key: $key, values: $values, baseRowVersion: null, effectiveDate: null } ],
        source: { type: "form", ref: "investment-dod", pluginId: null, pluginVersion: null } }'
}

post() {
    local path="$1" body="$2" http
    http="$(curl -sS -o "$WORK/post.json" -w '%{http_code}' -X POST "$BFF$path" \
        -H "authorization: Bearer $BEARER" -H 'content-type: application/json' --data "$body" || true)"
    printf '%s' "${http:-000}"
}

if [ -n "$NAMED" ]; then
    ok "asserting the correction of $MOVEMENT that was committed in the Inbox: $OLD_AMOUNT → $NEW_AMOUNT"
else
    ok "correcting $MOVEMENT: $OLD_AMOUNT → $NEW_AMOUNT"
    CORRECTION="$(batch correct update "{\"external_id\":\"$MOVEMENT\"}" "{\"amount\":\"$NEW_AMOUNT\"}")"
    [ "$(post "/api/entry/batches?intent=hold" "$CORRECTION")" = "201" ] || fail "the correction was not journalled: $(cat "$WORK/post.json")"
    if [ -n "$HOLD_ONLY" ]; then
        # ⛔ Ruled (a): the commit is a PERSON'S. The batch is held; it is now in the Inbox, where
        # someone previews it, reads the two rows it proposes, and commits it under their own name.
        # The script stops here rather than doing it for them, because the point of the beat is that
        # a human decided — and a script that committed "to be sure" would remove the only thing
        # being shown. The second half is a run NAMING this movement: a plain re-run would pick its
        # own movement and assert nothing about the one the person committed.
        rerun="IE_DOD_MODE=full IE_DOD_PORTFOLIO=$(printf '%q' "$PORTFOLIO") IE_DOD_MOVEMENT=$(printf '%q' "$MOVEMENT")"
        [ -z "$TOP_N" ] || rerun="$rerun IE_DOD_TOP_N=$TOP_N"
        ok "held for the Inbox — preview and commit it there, as $MOVEMENT"
        printf '\n\033[1mheld: the correction of %s (%s → %s) is waiting in the Inbox.\033[0m\n' "$MOVEMENT" "$OLD_AMOUNT" "$NEW_AMOUNT"
        printf 'Open /e/inbox?state=held, preview it and commit it. Then, with the same IE_DOD_BFF, IE_DOD_BEARER\n'
        printf 'and IE_DOD_DSN, run the second half — it asserts that correction through the door, then runs the\n'
        printf 'addition and refusal drills:\n\n'
        printf '  %s just investment-dod\n\n' "$rerun"
        printf 'Without IE_DOD_MOVEMENT a re-run asserts nothing about this correction: before the commit it\n'
        printf 'corrects %s itself (and the held batch is then refused), after it it corrects another movement.\n' "$MOVEMENT"
        exit 0
    fi
    [ "$(post "/api/entry/preview" "$CORRECTION")" = "200" ] || fail "preview refused: $(cat "$WORK/post.json")"
    jq -e '.rejects | length == 0' "$WORK/post.json" >/dev/null || fail "preview rejected rows: $(cat "$WORK/post.json")"
    [ "$(post "/api/entry/commit" "$CORRECTION")" = "200" ] || fail "commit refused: $(cat "$WORK/post.json")"
    ok "previewed and committed as the caller of this script"
fi

# ⛔ The id law is `-rev` / `-rep`, with NO DIGIT. The task list said `-rev1` / `-rep1`; the code
# says `"$origId-rev"` (LedgerApplyProgram) and so does the S2.2 fixture book
# (`conseq:200619142:SUB:900013-rep`). Asserted as the code spells it — S2.4·D4.
AFTER_ROWS="$(book_rows)"
if [ -z "$NAMED" ]; then
    [ "$((AFTER_ROWS - BEFORE_ROWS))" = "2" ] || fail "a correction added $((AFTER_ROWS - BEFORE_ROWS)) rows, expected 2 (reversal + replacement)"
fi
[ "$(q "SELECT count(*) FROM investment_transaction WHERE external_id = '$MOVEMENT-rev'")" = "1" ] || fail "no reversal row '$MOVEMENT-rev'"
[ "$(q "SELECT count(*) FROM investment_transaction WHERE external_id = '$MOVEMENT-rep'")" = "1" ] || fail "no replacement row '$MOVEMENT-rep'"
[ "$(q "SELECT reversal_of FROM investment_transaction WHERE external_id = '$MOVEMENT-rev'")" = "$MOVEMENT" ] || fail "the reversal does not link to the movement"
BOOK_REP="$(q "SELECT amount FROM investment_transaction WHERE external_id = '$MOVEMENT-rep'")"
num_eq "$BOOK_REP" "$NEW_AMOUNT" || fail "the book's replacement $MOVEMENT-rep carries $BOOK_REP, not the corrected $NEW_AMOUNT"
if [ -z "$NAMED" ]; then
    ok "+2 rows: $MOVEMENT-rev (linked) and $MOVEMENT-rep at $NEW_AMOUNT"
else
    ok "the book holds $MOVEMENT-rev (linked) and $MOVEMENT-rep at $NEW_AMOUNT"
fi

# The whole point of the effective ledger: three rows in the book, ONE row in the answer — and it is
# the REPLACEMENT. Found by the `transaction_id` column, for every id of the chain: the original and
# the reversal must be gone, the replacement present with the new amount. ("At most one of the three"
# is also what the pre-correction answer says, so it is not a check that the write was seen.)
AFTER_TXNS="$(run "q.investment.transactions_recent" "{\"portfolio_id\":\"$PORTFOLIO\",\"since\":\"2000-01-01\"}")" || fail "transactions_recent stopped answering"
# Unchanged whether or not the cap binds: a correction replaces one effective row with one effective
# row, so neither the true count nor the capped view of it may move.
[ "$(rows "$AFTER_TXNS")" = "$door_txns" ] || fail "the effective ledger moved from $door_txns to $(rows "$AFTER_TXNS") rows — a correction must not change the COUNT"
orig="$(where "$AFTER_TXNS" transaction_id "$MOVEMENT")" || fail "transactions_recent has no transaction_id column"
rev="$(where "$AFTER_TXNS" transaction_id "$MOVEMENT-rev")"
rep="$(where "$AFTER_TXNS" transaction_id "$MOVEMENT-rep")"
[ "$(jq length <<<"$orig")" = "0" ] \
    || fail "the door still shows the ORIGINAL $MOVEMENT after its correction — it is not reading the book the correction was written to, or the reversal is not cancelling"
[ "$(jq length <<<"$rev")" = "0" ] || fail "the door lists the reversal $MOVEMENT-rev as a movement — a reversal cancels, it never appears"
case "$(jq length <<<"$rep")" in
    1)
        door_rep="$(jq -r '.[0].amount' <<<"$rep")"
        num_eq "$door_rep" "$NEW_AMOUNT" || fail "the door shows $MOVEMENT-rep at $door_rep, not the new amount $NEW_AMOUNT"
        ok "through the door: $MOVEMENT is gone and $MOVEMENT-rep carries the new amount ($NEW_AMOUNT); the count is unchanged ($door_txns)"
        ;;
    0)
        # Absent is only acceptable under a cap: the answer is a WINDOW on the ledger, and the
        # corrected movement can legitimately fall outside it. "Not in the window" and "not in the
        # ledger" are different statements that the door alone cannot tell apart — so the book was
        # asked, above, for the replacement AND its amount. Said rather than passed over: through the
        # door, this run has not seen the correction.
        [ "$expected_txns" != "$db_txns" ] || fail "the corrected movement vanished from the effective ledger — no $MOVEMENT-rep in the door's answer"
        ok "$MOVEMENT-rep fell outside the capped $TOP_N-row window, so the door cannot show it; the book holds it at $NEW_AMOUNT"
        ;;
    *) fail "$MOVEMENT-rep appears $(jq length <<<"$rep") times in the effective ledger" ;;
esac

# Units do not move when money is corrected — every line of the answer, compared by line_id. A RULE,
# not evidence of the write: a door that never saw the correction passes it too, which is why the
# replacement row above is what proves the door saw it.
AFTER_POS="$(run "q.investment.positions_at" "{\"portfolio_id\":\"$PORTFOLIO\",\"as_of\":\"$TODAY\"}")" || fail "positions_at stopped answering"
AFTER_HOLDINGS="$(holdings "$AFTER_POS")" || fail "positions_at cannot be read by line_id and quantity"
if [ -z "$NAMED" ]; then
    [ "$AFTER_HOLDINGS" = "$BEFORE_HOLDINGS" ] || fail "correcting an AMOUNT changed the holdings: $BEFORE_HOLDINGS → $AFTER_HOLDINGS"
    ok "every holding is unchanged ($(jq length <<<"$BEFORE_HOLDINGS") lines) — money moved, units did not"
else
    ok "holdings not compared: the correction was committed before this run, so it has no 'before'"
fi

# ── 3. the addition drill ────────────────────────────────────────────────────────────────────────

step "3. adding an external-flow deposit"

# ⛔ WHAT THE DOOR CAN AND CANNOT SHOW FOR AN EXTERNAL FLOW.
#   CAN:    the MOVEMENT. A deposit is a row of the effective ledger, so transactions_recent must list
#           it — its leg, its operation, its amount — and the effective count must grow by one.
#   CANNOT: its EFFECT on any figure. cash_balance sums the cash leg only (IE-C25), positions_at
#           carries holdings and cash, and the one program that sums flows — quarterly_evolution's
#           net_flow_q — does not run through the door (⚑IE-15). So the effect is checked in psql,
#           as an exact delta, and "cash_balance is unchanged" is kept as the rule it is: a door
#           that never saw the deposit satisfies it just as well.

# Read BEFORE the deposit: the assertion is that the quarter's net flow grew by the amount, and a
# threshold ("at least the amount") is already met by any earlier deposit this quarter.
net_flow() {
    q "
  SELECT COALESCE(SUM(CASE WHEN leg = 'external-flow' AND operation = 'deposit' THEN abs(amount)
                           WHEN leg = 'external-flow' AND operation = 'withdrawal' THEN -abs(amount)
                           ELSE 0 END), 0)::text
    FROM investment_transaction t
   WHERE t.portfolio_ref = '$PORTFOLIO' AND t.reversal_of IS NULL
     AND NOT EXISTS (SELECT 1 FROM investment_transaction r WHERE r.reversal_of = t.external_id)
     AND t.trade_date >= date_trunc('quarter', DATE '$TODAY')"
}
NET_FLOW_BEFORE="$(net_flow)"

DEPOSIT_ID="ie-dod:$(date -u +%Y%m%dT%H%M%SZ):FLOW:CRE"
DEPOSIT_AMOUNT="12345.67"
ADDITION="$(batch add insert null "$(jq -nc --arg id "$DEPOSIT_ID" --arg p "$PORTFOLIO" --arg a "$DEPOSIT_AMOUNT" --arg d "$TODAY" '
  { external_id: $id, portfolio_ref: $p, leg: "external-flow", operation: "deposit",
    trade_date: $d, amount: $a, currency: "CZK" }')")"
[ "$(post "/api/entry/batches?intent=hold" "$ADDITION")" = "201" ] || fail "the deposit was not journalled: $(cat "$WORK/post.json")"
[ "$(post "/api/entry/preview" "$ADDITION")" = "200" ] || fail "preview refused: $(cat "$WORK/post.json")"
[ "$(post "/api/entry/commit" "$ADDITION")" = "200" ] || fail "commit refused: $(cat "$WORK/post.json")"

ADDED_ROWS="$(book_rows)"
[ "$((ADDED_ROWS - AFTER_ROWS))" = "1" ] || fail "the deposit added $((ADDED_ROWS - AFTER_ROWS)) rows, expected 1"
ok "+1 row: $DEPOSIT_ID"

AFTER_DEP_TXNS="$(run "q.investment.transactions_recent" "{\"portfolio_id\":\"$PORTFOLIO\",\"since\":\"2000-01-01\"}")" || fail "transactions_recent stopped answering"
db_after_dep="$(book_effective)"
[ "$(rows "$AFTER_DEP_TXNS")" = "$(capped "$db_after_dep")" ] \
    || fail "after the deposit transactions_recent says $(rows "$AFTER_DEP_TXNS") effective rows, expected $(capped "$db_after_dep") (the book holds $db_after_dep)"
dep="$(where "$AFTER_DEP_TXNS" transaction_id "$DEPOSIT_ID")" || fail "transactions_recent has no transaction_id column"
if [ "$(jq length <<<"$dep")" = "1" ]; then
    jq -e --arg a "$DEPOSIT_AMOUNT" '.[0] | .leg == "external-flow" and .operation == "deposit" and ((.amount | tonumber) == ($a | tonumber))' \
        <<<"$dep" >/dev/null 2>&1 \
        || fail "the door shows $DEPOSIT_ID as $(jq -c '.[0] | {leg, operation, amount}' <<<"$dep"), not an external-flow deposit of $DEPOSIT_AMOUNT"
    ok "through the door: the deposit is a movement of the ledger (external-flow / deposit, $DEPOSIT_AMOUNT)"
elif [ "$(capped "$db_after_dep")" != "$db_after_dep" ]; then
    # Dated today, the deposit sorts first; it falls outside the window only when the cap's worth of
    # movements is dated today or later. Said, not passed over: the door has not shown it.
    [ "$(q "SELECT count(*) FROM investment_transaction WHERE external_id = '$DEPOSIT_ID'")" = "1" ] || fail "the deposit is not in the book either"
    ok "the deposit fell outside the capped $TOP_N-row window, so the door cannot show it; the book holds it"
else
    fail "the door does not show the deposit $DEPOSIT_ID — it is in the book, so the door is not reading the book it was written to"
fi

# ⛔ AN EXTERNAL FLOW IS NOT CASH. `cash_balance` sums the CASH leg only (IE-C25) — a deposit arriving
# from outside is money the client SENT, and the matching cash credit is a separate movement the
# provider posts. A deposit that moved this figure would mean the two legs were being double-counted,
# which is what S2.2·D1 found in the CTE. Every currency, compared.
AFTER_CASH="$(run "q.investment.cash_balance" "{\"portfolio_id\":\"$PORTFOLIO\",\"as_of\":\"$TODAY\"}")" || fail "cash_balance stopped answering"
AFTER_CASH_SET="$(cash_by_ccy "$AFTER_CASH")" || fail "cash_balance cannot be read by currency"
[ "$AFTER_CASH_SET" = "$BEFORE_CASH" ] || fail "an external-flow deposit moved cash_balance: $BEFORE_CASH → $AFTER_CASH_SET — the cash leg is being double-counted"
ok "cash_balance is unchanged — an external flow is not a cash movement (a rule, not evidence: see above)"

# ⚑ The net-flow assertion is made in PSQL, not through the door, and that is not a shortcut:
# `quarterly_evolution` is the one program the door cannot compile (⚑IE-15, ruled (a)), so there is
# no door answer to check. The rule it would check is still checked — against the same CTE the
# program carries, as `after − before == amount`, exactly — and the day the report renderer computes
# its own quarter grid (P3·S3.1), this moves onto that path.
NET_FLOW_AFTER="$(net_flow)"
before_m="$(micros "$NET_FLOW_BEFORE")" || fail "the net flow before the deposit is not a decimal: $NET_FLOW_BEFORE"
after_m="$(micros "$NET_FLOW_AFTER")" || fail "the net flow after the deposit is not a decimal: $NET_FLOW_AFTER"
amount_m="$(micros "$DEPOSIT_AMOUNT")"
[ "$((after_m - before_m))" = "$amount_m" ] \
    || fail "this quarter's net flow moved from $NET_FLOW_BEFORE to $NET_FLOW_AFTER, not by the deposit's $DEPOSIT_AMOUNT — a wrong date, leg or operation (or another flow written meanwhile)"
ok "this quarter's net flow grew by exactly $DEPOSIT_AMOUNT ($NET_FLOW_BEFORE → $NET_FLOW_AFTER; psql — the door cannot compile quarterly_evolution)"

# ── 4. the ledger law ────────────────────────────────────────────────────────────────────────────

step "4. a second correction of the same movement is REFUSED"

# This is the script's proof that it exercised the ledger rather than a table. A chain — correcting a
# correction — is refused rather than guessed at, because reversing the wrong row is worse than
# refusing. 422 LEDGER_CHAIN_UNSUPPORTED (Application.kt).
SECOND="$(batch again update "{\"external_id\":\"$MOVEMENT\"}" "{\"amount\":\"999.99\"}")"
[ "$(post "/api/entry/batches?intent=hold" "$SECOND")" = "201" ] || fail "the second correction was not journalled"
http="$(post "/api/entry/preview" "$SECOND")"
code="$(jq -r '.code // "?"' "$WORK/post.json" 2>/dev/null || echo '?')"
[ "$code" = "LEDGER_CHAIN_UNSUPPORTED" ] || fail "a second correction answered $http $code, expected LEDGER_CHAIN_UNSUPPORTED"
ok "refused with $http LEDGER_CHAIN_UNSUPPORTED"

FINAL_ROWS="$(book_rows)"
[ "$FINAL_ROWS" = "$ADDED_ROWS" ] || fail "the refused correction still wrote $((FINAL_ROWS - ADDED_ROWS)) row(s)"
ok "and it wrote nothing"

# ── 5. the table ─────────────────────────────────────────────────────────────────────────────────

step "5. before and after"
cash_text() { jq -r 'map("\(.[0]) \(.[1])") | join(", ")' <<<"$1"; }
printf '\n'
printf '  %-34s %14s %14s\n' '' 'before' 'after'
printf '  %-34s %14s %14s\n' 'rows in the book' "$BEFORE_ROWS" "$FINAL_ROWS"
printf '  %-34s %14s %14s\n' 'effective movements (the door)' "$door_txns" "$(rows "$AFTER_DEP_TXNS")"
printf '  %-34s %14s %14s\n' 'holdings (positions_at lines)' "$(jq length <<<"$BEFORE_HOLDINGS")" \
    "$(if [ -n "$NAMED" ]; then echo 'not compared'; elif [ "$AFTER_HOLDINGS" = "$BEFORE_HOLDINGS" ]; then echo 'identical'; else echo 'DIFFERENT'; fi)"
printf '  %-34s %14s %14s\n' 'cash balance' "$(cash_text "$BEFORE_CASH")" "$(cash_text "$AFTER_CASH_SET")"
printf '  %-34s %14s %14s\n' "this quarter's net flow" "$NET_FLOW_BEFORE" "$NET_FLOW_AFTER"
printf '\n'
if [ -n "$NAMED" ]; then
    printf '  \033[1mThe ledger holds the committed correction, and this run added one row:\033[0m\n'
else
    printf '  \033[1mThree rows were added to the ledger and nothing was overwritten:\033[0m\n'
fi
printf '    %s-rev   the reversal\n' "$MOVEMENT"
printf '    %s-rep   the replacement\n' "$MOVEMENT"
printf '    %s   the deposit\n' "$DEPOSIT_ID"
printf '\n\033[32m✓ investment-dod passed (%s mode)\033[0m\n' "$MODE"
