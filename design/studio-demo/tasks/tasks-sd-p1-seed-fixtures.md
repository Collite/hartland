# SD-P1 · S2 — Seed, store & fixtures

> Contracts: [`../contracts.md`](../contracts.md) §4–§6, §8 (SD-R1). TDD: the oracle
> asserts exist and FAIL before the seed SQL is written. Ground truth for every expected
> number: [`../../../data/recon/R0.md`](../../../data/recon/R0.md).

- [ ] **T1 — Oracle first.** `data/plan/expected/seed-oracle.csv` + a runner
  (`data/plan/tests/test_seed.sql` or `.mjs`): FY2025 `actual` totals per channel must
  equal R0 — Marketplace **$683.4M**, Stores **$1,024.8M**, Web **$365.0M** (exact R0
  figures, cents-level tolerance stated in the file); row-count assert = channels(3) ×
  categories(10) × months(24 actual + 12 plan) × versions as applicable; FY26 seed total
  per channel = FY25 actual (shape-copy rule). Run: RED (no store yet).
- [ ] **T2 — The store DDL.** `data/plan/ddl.sql` per contracts §4.1 (schema `plan`,
  table `plan.revenue_plan`, PK, roles `plan_rw`/`plan_ro`). Applied by `rig/up.sh`.
- [ ] **T3 — Actuals aggregation.** `data/plan/seed-actuals.sql`: `hartland_us`
  store_sales+web_sales+catalog_sales → channel literal (`'store'|'web'|'marketplace'` —
  lowercase, quirks §3.3) · item→`i_category` · day→yyyymm · sum(ext sales price
  consistent with the R0 revenue definition — copy the measure expression from
  `q.hartland.channel_revenue_monthly`, do NOT invent one). Insert as
  `version_code='actual'`, 2024-01…2025-12. Oracle T1: actuals section GREEN.
- [ ] **T4 — Plan seed.** `data/plan/seed-plan.sql`: `plan-fy26` = FY25 actual per cell,
  month shifted +12; the zero-base cameo plane (pick + record ONE (category, channel)
  with genuine FY25 zero or delete its seed rows — header comment documents the choice)
  seeded 0. Oracle GREEN in full.
- [ ] **T5 — Round-state fixture.** `data/plan/round-state.sql` (or via the service API in
  a `.mjs`): version `plan-fy26` OPEN, reservations/drafts/done-flags empty. Note: the A2
  substrate tables belong to the service's migrations — this script only *populates*;
  boot the service once (P0.T4 recipe) before running it.
- [ ] **T6 — The planning form.** `data/plan/forms/revenue-plan-form.ttrl` per contracts
  §6.2 (kind `tatrman.ttrl.cube-planning-form`; rows=categoryName, cols=month, slicers
  SalesChannel + Version=plan-fy26, reference overlay=actual). Test = the shipped
  validate-form (§8.2 six-rule catalogue) passes it; wire that run into the verify block.
- [ ] **T7 — SD-R1 reset.** `rig/reset.sh` per contracts §8: dump the seeded
  `hartland_plan` once (`data/plan/hartland_plan.seeded.dump`), reset = restore + release
  reservations + reopen version + clear drafts/prefs + `workspace-state.sh pre-delta` +
  fixture checklist print. Idempotent, <60 s, never touches `hartland_us`.
- [ ] **T8 — Determinism proof.** Run: seed → oracle → reset → oracle, twice. Byte-identical
  oracle output both rounds. Commit `data/plan/` + record the two **stage numbers** (FY26
  Marketplace seed total; the +10.5% target $755M delta) in `data/plan/expected/stage-numbers.md`.

## Verify block

```sh
rig/up.sh && psql -f data/plan/tests/test_seed.sql      # oracle GREEN
rig/reset.sh && psql -f data/plan/tests/test_seed.sql   # still GREEN, <60s
validate-form data/plan/forms/revenue-plan-form.ttrl    # per the shipped A2 tool — PASS
```
