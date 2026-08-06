# SD-P3 · S1 — Planner service on the demo cube

> Product surface: the whole FO-A2 delivery (grid-core · studio-planner app ·
> `:services:studio-planner`). This stage re-points the shipped **§9 acceptance walk**
> at the demo cube — the walk IS the test harness (TDD here = the walk asserts before the
> config). Consume, never patch (SD-D2). Contracts: A2 §C–§H (frozen) + SD
> [`../contracts.md`](../contracts.md) §4–§5.

- [ ] **T1 — Cube target config.** Wire `:services:studio-planner` to `hartland_plan`
  with cube target `revenuePlan` → `plan.revenue_plan` (storage mapping per the service's
  cube-target config surface — P0.T4 probe documented it). Boot; migrations create the
  substrate tables; `/health`,`/ready` green.
- [ ] **T2 — Walk asserts first.** Copy the shipped `acceptance-walk.mjs` →
  `rig/acceptance-walk-demo.mjs`; re-target: form = `revenue-plan-form.ttrl`, scope =
  Maya's Marketplace slice (contracts §5.3), users = maya + dan bearers (or dev-auth
  equivalents pre-⚑2). Rewrite the walk's expected values from the seed oracle
  (`data/plan/expected/`). Run: legs fail (config not complete) — that's the RED.
- [ ] **T3 — Leg 1–3 green: open → check-out → seed.** loadView returns the base matrix +
  basePresence for the form's grain (categories × months, Marketplace, plan-fy26 +
  actual reference); acquire reservation on the slice; the zero-base plane shows its
  marks.
- [ ] **T4 — Leg 4–6 green: author → preview.** Submit the scripted batch (the stage
  gestures encoded as journal rows: typed total, pins, block scale — grid-core's
  `journal()` output, exactly what Beat P will produce); preview → all four verdict chips
  ✓; storage-grain expansion rows old→new match oracle.
- [ ] **T5 — Leg 7–10 green: check-in → record → round.** Commit with held reservation →
  PlannerEntryRecord persisted (fetch + assert payload: assignments/seeds/leaf-set-hash
  present); reservation contrast (dan's acquire on the same slice → denied with holder
  named); release + done-flag → round dashboard read shows the slice done; version
  reopen/close round-trips.
- [ ] **T6 — Refusal paths.** Assert the named failures behave: commit WITHOUT reservation
  → `NO_CHECKOUT` 409; commit on a LOCKED version → `VERSION_LOCKED` 409; both surfaced
  with the A2 status-page shapes. (These feed Satellite R if ⚑4 flips in.)
- [ ] **T7 — Reset integration.** SD-R1 → full walk green again, twice; identical numbers
  (determinism assert = diff the two walk outputs).
- [ ] **T8 — Record.** Walk output committed as `design/studio-demo/readiness/walk-<date>.txt`;
  findings → `../findings.md`; check boxes.

## Verify block

```sh
rig/up.sh && node rig/acceptance-walk-demo.mjs    # all 10 legs PASS
rig/reset.sh && node rig/acceptance-walk-demo.mjs # PASS again, byte-identical summary
```
