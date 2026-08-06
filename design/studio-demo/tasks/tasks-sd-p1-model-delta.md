# SD-P1 · S1 — The plan-model delta

> Contracts: [`../contracts.md`](../contracts.md) §2–§3. TDD: model tests first. The delta
> is the **committed** artifact Beat M re-enacts (architecture §4 "twice-authored") — treat
> the text as demo-critical: formatting canonical (`@tatrman/format` conventions), comments
> included exactly as in contracts §3.

- [ ] **T1 — Grammar + inventory probe (test-shaping).** Against the pinned tatrman
  grammar (`packages/grammar`, TTR.g4) verify the contracts-§3 syntax for: `def dimension`
  with level/members, closed member sets, `def cubelet` grain refs to a new dimension.
  Confirm no `SalesChannel`/`Version` dimension already exists in `model/md/dimensions.ttrm`.
  Amend contracts §3 text if the dialect differs (shape is fixed; syntax follows grammar).
  Record the check in a comment atop `versions.ttrm`.
- [ ] **T2 — Tests first: extend the model harness.** In `model/md/tests/md.test.mjs` (+
  `model/tests/phase2-done.test.mjs` if it enumerates defs): failing asserts for —
  `Version` dimension exists with members `actual|plan-fy26` · `SalesChannel` with
  `store|web|marketplace` · measure `planRevenue` (Money, additive, sum) · cubelet
  `revenuePlan` with the exact 4-part grain + 1 measure · **all pre-existing defs
  unchanged** (count assert). Run: RED.
- [ ] **T3 — Author the delta.** `model/md/versions.ttrm` (new) + appends to
  `dimensions.ttrm`, `measures.ttrm`, `cubelets.ttrm` per contracts §3. Run T2: GREEN.
- [ ] **T4 — Lexicon labels.** en + cs labels for Version (+members), SalesChannel
  (+members: Store/Prodejny, Web, Marketplace), planRevenue ("Planned revenue"/"Plánovaný
  obrat") following `model/lexicon/{en,cs}/measures.ttrm` conventions; extend
  `model/lexicon/tests/lexicon.test.mjs` (assert first).
- [ ] **T5 — The Designer program.** `model/queries/q_hartland_plan.ttrm` =
  `q.hartland.plan_vs_actual` per contracts §6.1. Calcite discipline from
  [`../../demo-quirks.md`](../../demo-quirks.md) §2: `{brace}` params only, no SELECT-alias
  GROUP BY, no reserved-word aliases. Extend `model/queries/tests/queries.test.mjs`
  (parse assert first).
- [ ] **T6 — The two workspace states.** Script `rig/workspace-state.sh {pre-delta|post-delta}`:
  `pre-delta` = `studio-demo` checkout with the §3 files reverted (a pinned pre-commit or
  `git checkout <sha> -- model/md/...`), `post-delta` = full branch. Idempotent; used by
  SD-R1 reset and the Beat-M byte-compare.
- [ ] **T7 — Commit + green sweep.** Full model test run (`model/tests/` harness) green on
  `studio-demo`; commit the delta as ONE commit (it is the byte-compare reference —
  record its SHA in `../contracts.md` §3 header). Check this list fully.

## Verify block

```sh
node --test model/md/tests/ model/lexicon/tests/ model/queries/tests/   # green
rig/workspace-state.sh pre-delta  && ! grep -q revenuePlan model/md/cubelets.ttrm
rig/workspace-state.sh post-delta &&   grep -q revenuePlan model/md/cubelets.ttrm
```
