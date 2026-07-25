# SD-P2 · S1 — Modeler beat (Beats 1 + M)

> Narrative: [`../00-demo-narrative.md`](../00-demo-narrative.md) Beats 1/M. Product
> surfaces: A1-W2 (lineage) + A1-W3 (Studio Modeler comfort) — consume, never patch
> (SD-D2). Artifact of this stage: **`../beats/beat-m.md`** — the click-by-click beat
> sheet with screenshots — plus the byte-compare check.

- [ ] **T1 — Viewer beat (Beat 1) walk.** Rig up, `post-delta` workspace… no — **`pre-delta`**
  (Beat 1 precedes the authoring; the star shows 7 cubelets, no plan objects). Open Viewer:
  md star renders; er perspective renders; drill `marketplaceSales` → member detail
  `revenue` → **Lineage** affordance → cubelet→er→db chain visible. Record each step +
  screenshot in `beat-1` section of the beat sheet. Any render gap → `../findings.md` +
  issue (tag `fo-a1-demo`).
- [ ] **T2 — Script the Beat-M door sequence.** From `pre-delta`, author via doors/⌘K
  ONLY (no raw text typing on stage): Version dimension (+2 members) → SalesChannel
  (+3 members) → planRevenue measure → revenuePlan cubelet (grain picks the 4 members;
  measure picks planRevenue). Write down the exact door/menu/field sequence — every click
  named as the UI names it — in `beat-m.md`. Where a def has no door affordance (possible:
  dimension member add), the fallback is the TextDrawer typed-edit for THAT def, narrated
  honestly — record which path each def takes.
- [ ] **T3 — Byte-compare check.** `rig/check-beat-m.sh`: after a Beat-M run, diff the
  workspace's four md files against the committed delta (P1.S1.T7 SHA). Zero-diff = PASS
  (D-6 byte-identical emission — this check IS the demo's strongest claim; if formatting
  differs, the fix is in the *sequence* (T2) or a finding, never hand-editing).
- [ ] **T4 — TextDrawer moment.** In the sequence, after the cubelet lands: open
  TextDrawer on `cubelets.ttrm`, confirm the canonical text; screenshot for the beat
  sheet ("the graph is a view" line anchors here).
- [ ] **T5 — Remove-with-consequences cameo.** Attempt remove on measure `revenue`:
  the drawer must name dependents (the 3 sales cubelets + lexicon labels + the queries
  reading it) and refuse/require consequence acknowledgment; **cancel** (never remove). Record
  exact dialog text in the beat sheet — the narration quotes it.
- [ ] **T6 — Reset discipline.** SD-R1 → Beat 1 + Beat M + T3 check, twice back-to-back;
  same result both times; wall-clock the beat (target ≤ 6 min inside the show).
- [ ] **T7 — Non-builder run.** Someone who didn't build it runs Beats 1+M from
  `beat-m.md` alone, cold. Gaps found → fix the sheet, re-run. Check the stage boxes in
  `00-task-management.md`.

## Verify block

```sh
rig/reset.sh && rig/workspace-state.sh pre-delta
# (run the beat per beat-m.md)
rig/check-beat-m.sh        # ZERO-DIFF PASS
```
