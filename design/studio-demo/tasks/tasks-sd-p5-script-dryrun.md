# SD-P5 — Script, rehearsal, readiness (the exit)

> The 07-f discipline scaled to the Studio demo. Pre-flight: P2–P4 done; all beat sheets
> exist; SD-B 1–2, 6 recorded. Exit = plan §Global DONE.

- [ ] **T1 — Freeze the transcript.** `design/studio-demo/demo-transcript-studio.md`:
  [`../00-demo-narrative.md`](../00-demo-narrative.md) finalized with every on-screen
  number replaced by the oracle value (the R0-freeze discipline — `stage-numbers.md` is
  the source; if transcript and oracle ever drift, the oracle wins — say so in the
  header), every ⚑ verdict folded in (Beat-D variant, identity line), the beat→machinery
  Requires lines updated to what was actually built.
- [ ] **T2 — Timing boxes + fallback ladder.** Per beat: target/max times (whole arc
  ≤ 25′) and the fallback moves — **L0** retry the gesture · **L1** the pre-baked
  artifact (pre-graduated `plan_vs_actual` for Beat D; a pre-committed plan
  snapshot/entry record for Beat P; `post-delta` switch for Beat M) · **L2** beat-sheet
  screenshots (last resort, narrated as such). Each fallback REHEARSED in T5, not just
  listed.
- [ ] **T3 — `studio-demo-quirks.md` consolidated.** The running file (task-mgmt rule 7)
  edited into the same shape as [`../../demo-quirks.md`](../../demo-quirks.md): symptom →
  cause → rule. Everything that bit during P1–P4 is in it; a fresh operator reads it
  before touching the rig.
- [ ] **T4 — R1 table read.** Script only, no rig: every [BORA] framing ≤ 3 sentences;
  the two "spoken contrast" lines (recording-grain vs plan-grain; January-agents vs
  today-deterministic) tightened. Edits back into T1's transcript.
- [ ] **T5 — R2 beat drills.** Each beat 3× clean on the rig **+ one deliberately broken
  run per beat** (kill the planner service mid-preview · introduce a validate error you
  didn't stage · reservation already held by dan) drilling its fallback until the switch
  is < 15 s without visible fluster. Log each drill in `readiness/r2-drills.md`.
- [ ] **T6 — R3 stopwatch runs.** Full arc ×2 with per-beat actuals vs the T2 boxes; on
  the best run capture the artifacts: the graduated program, the entry record id, the
  final screenshots for L2. Freeze narration lines that quote UI copy (dialog/chip text)
  against the captured screenshots.
- [ ] **T7 — R4 THE DRY RUN (the exit criterion).** `rig/preshow.sh` → the full arc
  **twice consecutively, zero operator intervention, ≤ 25′ each**, in the delivery
  locale. A run needing a keyboard save-the-day or an unscripted explanation = FAIL →
  fix the gap (fixture/recipe/script) → re-run. Record as `readiness/r4-<date>.md` with
  SD-B 1–7 all checked.
- [ ] **T8 — Wrap.** CZ mirror iff a CZ delivery is scheduled (straight translation,
  same oracle numbers ×FX — else record the N/A disposition) · `findings.md` issues all
  filed + linked · corpus STATUS → `done` · update the repo README design-table row +
  `00-task-management.md` progress log · hand the freeze rule forward (post-R4: rig
  changes only via reset + re-dry-run).

## Verify block

```sh
rig/preshow.sh
# R4: two consecutive unaided arcs, stopwatch ≤25' each — operator-touch counter 0
ls design/studio-demo/readiness/r4-*.md   # exists, SD-B 1–7 checked
```
