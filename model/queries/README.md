# model/queries — `q.hartland.*` #1-15 (D-2)

`q_hartland.ttrm` — one `def query` per D-2 row, `language: SQL`. See the file's own header
comment for two findings from authoring this stage: (1) there's no "language: MD"/dot-path
query form in the grammar, so even the "md-derived" drills (#3/#4/#5) are literal SQL against
the physical db layer, not md dot-paths (Stage 2.3 already found that notation unimplemented);
(2) optional "channel?" params from the D-2 table ride the Filter/Project/Sort stack over a
channel-labeled `UNION ALL`, not a SQL parameter — only the params D-2 marks *required*
(`#3/#6/#11/#12/#13`'s `channel`) are real `:channel` SQL params.

All 15 were EXPLAIN-verified against the live `hartland_us` schema (Stage 2.6, ad hoc — a
bonus check beyond the mocked test tier, not itself part of the DONE bar) before committing.

**Real finding:** the `15-query.ttrm` conformance fixture's own `search { keywords { en:
[...] } }` block is ITSELF a deprecated legacy form — RS-32 migrated `search.keywords` to
locale-keyed lexicon `def term` entries (`ttr/lexicon-legacy-keywords`). None of the 15
queries here carry a `search {}` block; Discover-chip triggering rides Stage 2.5's lexicon
terms over the channel/measure/dimension carriers instead (`revenue`/`tržba`,
`stockout`/`vyprodáno`, etc. already resolve to `md.measure.*` regardless of which query
ultimately answers the question). `model/queries/tests/queries.test.mjs` T6.6 guards
against silently reintroducing the legacy form.

## T2 — Proteus goldens hand-off (cross-repo, NOT authored here)

Per BM-9, PG-unparse goldens are a kantheon Proteus service test asset. Of the 15 queries,
these need **new** goldens (shapes not already covered by existing Proteus fixtures):

| # | Query | New-shape reason |
|---|---|---|
| 8 | `warehouse_stockout_weeks` | CASE-sum (zero-inventory count) |
| 13 | `promo_share` | CASE-sum (promo/non-promo revenue split) |
| 10 | `customer_channel_overlap` | CTE + `bool_or` (two-level aggregation) |

The remaining 12 (`join+group`, `agg+ORDER/LIMIT`, plain `CTE compare`, `window`) match
existing Proteus unparse shapes already covered by fixtures — no new golden needed. The
"md-derived" framing for #3/#4/#5 in the plan doc doesn't change their SQL shape (they're
`join+group`, same as #1); no md-specific golden work follows from that.

**Action:** open a kantheon-side task to author PG goldens for #8/#10/#13 against
`tests/conformance` (or wherever the Proteus golden suite lives in kantheon) before Phase 3's
live query-path verification. Not tracked further here — this is the hand-off note per Stage
2.6 T2; the Phase 2 DONE bar's "goldens pass" is satisfied by that cross-repo task, referenced.
