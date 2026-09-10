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
# ## Modes
#
#   IE_DOD_MODE=full      read + the three write drills   (a local estate, or a THROWAWAY portfolio)
#   IE_DOD_MODE=readonly  read only                       (hartland, against a real book)
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

set -euo pipefail

BFF="${IE_DOD_BFF:?IE_DOD_BFF is required (studio-bff base URL)}"
BEARER="${IE_DOD_BEARER:?IE_DOD_BEARER is required}"
DSN="${IE_DOD_DSN:?IE_DOD_DSN is required (psql DSN for the entry database)}"
PORTFOLIO="${IE_DOD_PORTFOLIO:?IE_DOD_PORTFOLIO is required — name the portfolio explicitly}"
MODE="${IE_DOD_MODE:-readonly}"
TODAY="$(date -u +%F)"

fail() { printf '\n\033[31m✗ %s\033[0m\n' "$*" >&2; exit 1; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
step() { printf '\n\033[1m── %s\033[0m\n' "$*"; }

for tool in curl jq psql; do command -v "$tool" >/dev/null || fail "$tool is not on PATH"; done

# ── the door ─────────────────────────────────────────────────────────────────────────────────────

# `run <program> <params-json>` → the §2.2 answer, or a non-zero exit naming the BFF's own code.
run() {
    local program="$1" params="${2:-{\}}" body http code
    body="$(jq -nc --arg p "$program" --argjson params "$params" '{program: $p, params: $params, limit: 10000}')"
    http="$(curl -sS -o /tmp/ie-dod-run.json -w '%{http_code}' \
        -X POST "$BFF/api/query/run" \
        -H "authorization: Bearer $BEARER" \
        -H 'content-type: application/json' \
        --data "$body")"
    if [ "$http" != "200" ]; then
        code="$(jq -r '.code // "?"' /tmp/ie-dod-run.json 2>/dev/null || echo '?')"
        printf 'HTTP %s %s — %s\n' "$http" "$code" "$(jq -r '.message // ""' /tmp/ie-dod-run.json)" >&2
        return 1
    fi
    cat /tmp/ie-dod-run.json
}

# The value of one named column in row 0 — BY NAME, never by position. A query rewrite that reorders
# a projection must not silently move this script onto a different number (kantheon T1.18 makes the
# rename itself loud; this makes the script indifferent to a reorder).
col() { jq -r --arg c "$2" '(.columns | map(.name) | index($c)) as $i | if $i == null then "«no column \($c)»" else (.rows[0][$i] | tostring) end' <<<"$1"; }
rows() { jq -r '.rowCount' <<<"$1"; }

q() { psql "$DSN" -X -q -t -A -c "$1"; }

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
db_txns="$(q "
  SELECT count(*) FROM investment_transaction t
   WHERE t.portfolio_ref = '$PORTFOLIO'
     AND t.reversal_of IS NULL
     AND NOT EXISTS (SELECT 1 FROM investment_transaction r WHERE r.reversal_of = t.external_id)")"
[ "$door_txns" = "$db_txns" ] || fail "transactions_recent says $door_txns effective rows, the book says $db_txns"
ok "the door and the book agree: $db_txns effective movements"

# ⚑ positions_at answers with SEVEN columns since S2.3·D18, the seventh being `line_rank` (0 =
# holding, 1 = cash). Asserted, because it is a declared part of the answer now and a silent return
# to six would mean the sort key had gone back to being hoisted anonymously.
[ "$(jq -r '.columns[-1].name' <<<"${ANSWER[positions_at]}")" = "line_rank" ] \
    || fail "positions_at's last column is not line_rank — S2.3·D18 has regressed"
ok "positions_at declares its sort key (line_rank)"

# ⚑ quarterly_evolution is EXPECTED to fail, by ruling (⚑IE-15 = a): it needs a quarter-end grid
# derived from as_of and the wire format has no date arithmetic. Asserted as a refusal, so the day
# it starts working is a day this script tells someone.
if run "q.investment.quarterly_evolution" "{\"portfolio_id\":\"$PORTFOLIO\",\"as_of\":\"$TODAY\",\"quarters\":4}" >/dev/null 2>&1; then
    fail "quarterly_evolution COMPILED — ⚑IE-15 was ruled (a) on the premise that it cannot; re-read the ruling"
fi
ok "quarterly_evolution refuses, as ⚑IE-15 ruled it would"

if [ "$MODE" = "readonly" ]; then
    printf '\n\033[1mreadonly mode — the three write drills were skipped.\033[0m\n'
    printf 'Run with IE_DOD_MODE=full against a THROWAWAY portfolio to exercise the ledger.\n'
    exit 0
fi

# ── 2. the correction drill ──────────────────────────────────────────────────────────────────────

step "2. correcting one movement (reverse-and-replace)"

BEFORE_ROWS="$(q "SELECT count(*) FROM investment_transaction WHERE portfolio_ref = '$PORTFOLIO'")"
BEFORE_QTY="$(col "${ANSWER[positions_at]}" quantity)"
BEFORE_CASH="$(col "${ANSWER[cash_balance]}" cash_balance)"

# A movement that has never been corrected — `-rev` present means the chain is already one deep and
# the substrate would (correctly) refuse a second correction before we got to the drill that tests it.
MOVEMENT="$(q "
  SELECT t.external_id FROM investment_transaction t
   WHERE t.portfolio_ref = '$PORTFOLIO' AND t.leg = 'security' AND t.operation = 'buy'
     AND t.reversal_of IS NULL
     AND NOT EXISTS (SELECT 1 FROM investment_transaction r WHERE r.reversal_of = t.external_id)
     AND NOT EXISTS (SELECT 1 FROM investment_transaction v WHERE v.external_id = t.external_id || '-rev')
   ORDER BY t.trade_date DESC LIMIT 1")"
[ -n "$MOVEMENT" ] || fail "no uncorrected security/buy movement on $PORTFOLIO to correct"
OLD_AMOUNT="$(q "SELECT amount FROM investment_transaction WHERE external_id = '$MOVEMENT'")"
NEW_AMOUNT="$(q "SELECT (amount + 1.11)::text FROM investment_transaction WHERE external_id = '$MOVEMENT'")"
ok "correcting $MOVEMENT: $OLD_AMOUNT → $NEW_AMOUNT"

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
    http="$(curl -sS -o /tmp/ie-dod-post.json -w '%{http_code}' -X POST "$BFF$path" \
        -H "authorization: Bearer $BEARER" -H 'content-type: application/json' --data "$body")"
    printf '%s' "$http"
}

CORRECTION="$(batch correct update "{\"external_id\":\"$MOVEMENT\"}" "{\"amount\":\"$NEW_AMOUNT\"}")"
[ "$(post "/api/entry/batches?intent=hold" "$CORRECTION")" = "201" ] || fail "the correction was not journalled: $(cat /tmp/ie-dod-post.json)"
[ "$(post "/api/entry/preview" "$CORRECTION")" = "200" ] || fail "preview refused: $(cat /tmp/ie-dod-post.json)"
jq -e '.rejects | length == 0' /tmp/ie-dod-post.json >/dev/null || fail "preview rejected rows: $(cat /tmp/ie-dod-post.json)"
[ "$(post "/api/entry/commit" "$CORRECTION")" = "200" ] || fail "commit refused: $(cat /tmp/ie-dod-post.json)"
ok "previewed and committed as the caller of this script"

# ⛔ The id law is `-rev` / `-rep`, with NO DIGIT. The task list said `-rev1` / `-rep1`; the code
# says `"$origId-rev"` (LedgerApplyProgram) and so does the S2.2 fixture book
# (`conseq:200619142:SUB:900013-rep`). Asserted as the code spells it — S2.4·D4.
AFTER_ROWS="$(q "SELECT count(*) FROM investment_transaction WHERE portfolio_ref = '$PORTFOLIO'")"
[ "$((AFTER_ROWS - BEFORE_ROWS))" = "2" ] || fail "a correction added $((AFTER_ROWS - BEFORE_ROWS)) rows, expected 2 (reversal + replacement)"
[ "$(q "SELECT count(*) FROM investment_transaction WHERE external_id = '$MOVEMENT-rev'")" = "1" ] || fail "no reversal row '$MOVEMENT-rev'"
[ "$(q "SELECT count(*) FROM investment_transaction WHERE external_id = '$MOVEMENT-rep'")" = "1" ] || fail "no replacement row '$MOVEMENT-rep'"
[ "$(q "SELECT reversal_of FROM investment_transaction WHERE external_id = '$MOVEMENT-rev'")" = "$MOVEMENT" ] || fail "the reversal does not link to the movement"
ok "+2 rows: $MOVEMENT-rev (linked) and $MOVEMENT-rep"

# The whole point of the effective ledger: three rows in the book, ONE row in the answer.
AFTER_TXNS="$(run "q.investment.transactions_recent" "{\"portfolio_id\":\"$PORTFOLIO\",\"since\":\"2000-01-01\"}")" || fail "transactions_recent stopped answering"
[ "$(rows "$AFTER_TXNS")" = "$door_txns" ] || fail "the effective ledger moved from $door_txns to $(rows "$AFTER_TXNS") rows — a correction must not change the COUNT"
seen="$(jq -r --arg m "$MOVEMENT" '[.rows[] | select(.[0] == $m or .[0] == ($m + "-rep") or .[0] == ($m + "-rev"))] | length' <<<"$AFTER_TXNS")"
[ "$seen" = "1" ] || fail "the corrected movement appears $seen times in the effective ledger, expected exactly 1"
ok "the ledger still shows the movement exactly once, and the count is unchanged ($door_txns)"

AFTER_POS="$(run "q.investment.positions_at" "{\"portfolio_id\":\"$PORTFOLIO\",\"as_of\":\"$TODAY\"}")" || fail "positions_at stopped answering"
[ "$(col "$AFTER_POS" quantity)" = "$BEFORE_QTY" ] || fail "correcting an AMOUNT changed the holding: $BEFORE_QTY → $(col "$AFTER_POS" quantity)"
ok "the holding is unchanged ($BEFORE_QTY) — money moved, units did not"

# ── 3. the addition drill ────────────────────────────────────────────────────────────────────────

step "3. adding an external-flow deposit"

DEPOSIT_ID="ie-dod:$(date -u +%Y%m%dT%H%M%SZ):FLOW:CRE"
DEPOSIT_AMOUNT="12345.67"
ADDITION="$(batch add insert null "$(jq -nc --arg id "$DEPOSIT_ID" --arg p "$PORTFOLIO" --arg a "$DEPOSIT_AMOUNT" --arg d "$TODAY" '
  { external_id: $id, portfolio_ref: $p, leg: "external-flow", operation: "deposit",
    trade_date: $d, amount: $a, currency: "CZK" }')")"
[ "$(post "/api/entry/batches?intent=hold" "$ADDITION")" = "201" ] || fail "the deposit was not journalled: $(cat /tmp/ie-dod-post.json)"
[ "$(post "/api/entry/preview" "$ADDITION")" = "200" ] || fail "preview refused: $(cat /tmp/ie-dod-post.json)"
[ "$(post "/api/entry/commit" "$ADDITION")" = "200" ] || fail "commit refused: $(cat /tmp/ie-dod-post.json)"

ADDED_ROWS="$(q "SELECT count(*) FROM investment_transaction WHERE portfolio_ref = '$PORTFOLIO'")"
[ "$((ADDED_ROWS - AFTER_ROWS))" = "1" ] || fail "the deposit added $((ADDED_ROWS - AFTER_ROWS)) rows, expected 1"
ok "+1 row: $DEPOSIT_ID"

# ⛔ AN EXTERNAL FLOW IS NOT CASH, and this is the assertion that says so out loud. `cash_balance`
# sums the CASH leg only (IE-C25) — a deposit arriving from outside is money the client SENT, and
# the matching cash credit is a separate movement the provider posts. A deposit that moved this
# figure would mean the two legs were being double-counted, which is what S2.2·D1 found in the CTE.
AFTER_CASH="$(run "q.investment.cash_balance" "{\"portfolio_id\":\"$PORTFOLIO\",\"as_of\":\"$TODAY\"}")" || fail "cash_balance stopped answering"
[ "$(col "$AFTER_CASH" cash_balance)" = "$BEFORE_CASH" ] || fail "an external-flow deposit moved cash_balance: $BEFORE_CASH → $(col "$AFTER_CASH" cash_balance) — the cash leg is being double-counted"
ok "cash_balance is unchanged ($BEFORE_CASH) — an external flow is not a cash movement"

# ⚑ The net-flow assertion is made in PSQL, not through the door, and that is not a shortcut:
# `quarterly_evolution` is the one program the door cannot compile (⚑IE-15, ruled (a)), so there is
# no door answer to check. The rule it would check is still checked — against the same CTE the
# program carries — and the day the report renderer computes its own quarter grid (P3·S3.1), this
# moves onto that path.
NET_FLOW="$(q "
  SELECT COALESCE(SUM(CASE WHEN leg = 'external-flow' AND operation = 'deposit' THEN abs(amount)
                           WHEN leg = 'external-flow' AND operation = 'withdrawal' THEN -abs(amount)
                           ELSE 0 END), 0)::text
    FROM investment_transaction t
   WHERE t.portfolio_ref = '$PORTFOLIO' AND t.reversal_of IS NULL
     AND NOT EXISTS (SELECT 1 FROM investment_transaction r WHERE r.reversal_of = t.external_id)
     AND t.trade_date >= date_trunc('quarter', DATE '$TODAY')")"
jq -n --arg n "$NET_FLOW" --arg a "$DEPOSIT_AMOUNT" 'if ($n | tonumber) >= ($a | tonumber) then true else false end' | grep -q true \
    || fail "this quarter's net flow ($NET_FLOW) does not include the deposit ($DEPOSIT_AMOUNT)"
ok "this quarter's net flow includes the deposit (psql — the door cannot compile quarterly_evolution)"

# ── 4. the ledger law ────────────────────────────────────────────────────────────────────────────

step "4. a second correction of the same movement is REFUSED"

# This is the script's proof that it exercised the ledger rather than a table. A chain — correcting a
# correction — is refused rather than guessed at, because reversing the wrong row is worse than
# refusing. 422 LEDGER_CHAIN_UNSUPPORTED (Application.kt).
SECOND="$(batch again update "{\"external_id\":\"$MOVEMENT\"}" "{\"amount\":\"999.99\"}")"
[ "$(post "/api/entry/batches?intent=hold" "$SECOND")" = "201" ] || fail "the second correction was not journalled"
http="$(post "/api/entry/preview" "$SECOND")"
code="$(jq -r '.code // "?"' /tmp/ie-dod-post.json)"
[ "$code" = "LEDGER_CHAIN_UNSUPPORTED" ] || fail "a second correction answered $http $code, expected LEDGER_CHAIN_UNSUPPORTED"
ok "refused with $http LEDGER_CHAIN_UNSUPPORTED"

FINAL_ROWS="$(q "SELECT count(*) FROM investment_transaction WHERE portfolio_ref = '$PORTFOLIO'")"
[ "$FINAL_ROWS" = "$ADDED_ROWS" ] || fail "the refused correction still wrote $((FINAL_ROWS - ADDED_ROWS)) row(s)"
ok "and it wrote nothing"

# ── 5. the table ─────────────────────────────────────────────────────────────────────────────────

step "5. before and after"
printf '\n'
printf '  %-34s %14s %14s\n' '' 'before' 'after'
printf '  %-34s %14s %14s\n' 'rows in the book' "$BEFORE_ROWS" "$FINAL_ROWS"
printf '  %-34s %14s %14s\n' 'effective movements (the door)' "$door_txns" "$(rows "$AFTER_TXNS")"
printf '  %-34s %14s %14s\n' 'holding, first line' "$BEFORE_QTY" "$(col "$AFTER_POS" quantity)"
printf '  %-34s %14s %14s\n' 'cash balance' "$BEFORE_CASH" "$(col "$AFTER_CASH" cash_balance)"
printf '\n'
printf '  \033[1mThree rows were added to the ledger and nothing was overwritten:\033[0m\n'
printf '    %s-rev   the reversal\n' "$MOVEMENT"
printf '    %s-rep   the replacement\n' "$MOVEMENT"
printf '    %s   the deposit\n' "$DEPOSIT_ID"
printf '\n\033[32m✓ investment-dod passed (%s mode)\033[0m\n' "$MODE"
