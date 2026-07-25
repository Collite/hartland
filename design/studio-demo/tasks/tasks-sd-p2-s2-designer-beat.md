# SD-P2 · S2 — Designer beat (Beat D)

> Narrative Beat D; product surface A1-W4 (author → validate → preview-run → graduate).
> **Pre-flight: the SD-⚑3 verdict from P0.T3** — this list is written for both variants;
> tasks marked [LIVE] apply to `draft-live-run`, [GRAD] to `graduate-then-run`. Artifact:
> `../beats/beat-d.md`.

- [ ] **T1 — Author sequence.** `post-delta` workspace. On the processing canvas, assemble
  `q.hartland.plan_vs_actual` via ProcessingDoors matching the committed
  `model/queries/q_hartland_plan.ttrm` (P1.S1.T5): plan read + actuals read + join +
  derive variance/variancePct. Record the exact door sequence in `beat-d.md`. Byte-compare
  the emitted text vs the committed program (`rig/check-beat-d.sh`, same pattern as
  check-beat-m).
- [ ] **T2 — The staged error.** Choose + record the one mistake (default: member
  `plan-fy26` mistyped `plan-2026` in the read door). Script: introduce → **validate** →
  problems strip shows the diagnostic (screenshot; quote its exact text in the sheet) →
  fix → validate green. The diagnostic text is narration material — pick a mistake whose
  message reads well.
- [ ] **T3 [LIVE] — Draft preview-run.** Run the DRAFT against the rig's data
  (`hartland_us` actuals + `hartland_plan`): Arrow result in the ResultDrawer; FY25
  actuals populated, plan column half-empty pre-Beat-P (that emptiness is a narration
  beat — "we'll fill this in a minute"). Record expected row/col shape from the seed
  oracle in the sheet.
- [ ] **T3 [GRAD] — Graduate-then-run.** If ⚑3 = graduate-first: validate green →
  graduate → run the *saved* program via the shipped run path → same result assertions.
  The A1-CAP-003 chip, if shown, is narrated honestly ("the draft-run door is a named
  seam") — quote the chip text.
- [ ] **T4 — Graduate + catalog.** saveProgram → catalog + FileRail refresh; the program
  is deep-linkable — copy the deep link, open in a fresh tab, same program + result
  (the Pocket beat). Record the link format.
- [ ] **T5 — Post-Beat-P re-run hook.** Script the "plan column now full" close: after a
  committed Beat-P (coordinate with SD-P3 — first joint run), re-run the program;
  variance vs recovery target visible. Expected numbers from
  `data/plan/expected/stage-numbers.md`. This task closes only when run against a real
  P3 commit (cross-stage checkpoint — note it in the P3 S2 list too).
- [ ] **T6 — Reset + repeat + timing.** SD-R1 → full Beat D twice; identical; ≤ 6 min.
- [ ] **T7 — Non-builder run** from `beat-d.md` alone; fix gaps; check boxes.

## Verify block

```sh
rig/reset.sh
# run beat per beat-d.md, both halves (error → fix → run → graduate)
rig/check-beat-d.sh            # ZERO-DIFF vs committed program
# deep-link from T4 opens to the same result in a fresh session
```
