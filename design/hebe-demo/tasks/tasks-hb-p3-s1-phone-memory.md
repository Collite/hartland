# HB-P3 · S1 — Beats 0/1/2 (framing · phone · memory)

> Narrative Beats 0–2 → beat sheets `../beats/beat-{0,1,2}.md`: tap-by-tap, expected
> strings, screenshots, timing box, fallback move. Pre-flight: P1 verify green, P2
> fixtures seeded.

- [ ] **T1 — Beat 0 evidence.** Capture the registry contrast for the framing line:
  capabilities list/search showing hebe vs the Themis routing view without it (P0.T5
  method). One screenshot pair into `beat-0.md`; the narration quotes it ("the platform
  can't route to her — look").
- [ ] **T2 — Beat 1 staging.** Script the pre-show fire of `monday-brief` (manual fire via
  console) so the phone holds the message at showtime. Record in `beat-1.md`: the exact
  Telegram message (conclusion text + artifact count + link), the tap → Iris deep-link
  landing (scheduled badge visible), timing.
- [ ] **T3 — The phone-TLS decision.** Test the deep link ON the phone: does Iris open
  (private-CA trust on the phone browser — ops-manual §2 applies to the phone too)?
  Choose + record the choreography: trust the CA on the phone / open the link on the
  desktop instead / show the phone via camera + continue on desktop. This is a plan §Risks
  item — settle it here, in the sheet.
- [ ] **T4 — Beat 2 grading runs.** Run each Beat-2 question 3× against the seeded
  workspace; grade against `memory-answers.md` (facts + source). If a fact misses ≥1 of
  3: strengthen the fixture (more explicit note), never the oracle. Record pass rates in
  the sheet; pick the 2 strongest questions as primary + keep 1 spare.
- [ ] **T5 — Memory browser walk.** The show-the-files moment: browser → `MEMORY.md` +
  a daily note + one hybrid search ("Memphis") with the conclusion note on top.
  Screenshots; the "markdown she can read, not embedding soup" line anchors here.
- [ ] **T6 — Reset discipline.** HB-R1 → Beats 0–2 in sequence, twice; same facts both
  times; combined ≤ 7 min. Log to `../readiness/`.
- [ ] **T7 — Non-builder run** of Beats 0–2 from the sheets alone; fix gaps; check boxes.

## Verify block

```sh
data/hebe/reset-hebe.sh
# pre-show fire → phone message matches deliveries.md; deep link lands per T3 decision
# Beat-2 primaries: 3/3 fact-grade PASS
```
