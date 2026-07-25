# HB-P4 — Script, rehearsal, readiness (the exit)

> Pre-flight: P3 sheets complete; HB-B items 2–6 individually green. Exit = plan §Global
> DONE (HB-B 1–8 recorded).

- [ ] **T1 — Freeze the transcript.** `../demo-transcript-hebe.md` from the narrative:
  every quoted fact oracle-pinned (memory-answers · deliveries · run-set figures); ⚑
  verdicts folded in; Requires lines updated to as-built; the close's three-demo framing
  aligned with the SD transcript's close (one shared vocabulary — FO-33 + this corpus'
  register).
- [ ] **T2 — Timing boxes + fallback ladder.** Per beat: target/max (arc ≤ 20′). L0 =
  retry/re-ask once · L1 = the pre-baked artifact (pre-fired delivery on the phone ·
  pre-created routine · canned AWAITING_AGENT thread · receipts screenshot) · L2 = beat
  sheets. Every L1 artifact actually pre-baked and stored (`../beats/artifacts/`).
- [ ] **T3 — `hebe-demo-quirks.md` consolidated** into the house symptom→cause→rule shape
  (everything from P0–P3, incl. the phone-TLS ruling, the pinned wordings and why, the
  Telegram egress notes).
- [ ] **T4 — The local fallback proof (architecture §3).** One task, strictly bounded:
  local Hebe boots on the presenter machine (local/server profile), workspace seeded from
  the same fixtures, Beat 2 runs green. Record which script lines survive fallback (the
  sheet's fallback column) — and which die (OBO/posture/cost). NO further fallback
  engineering.
- [ ] **T5 — R1 table read.** [BORA] framings ≤ 3 sentences; the three signature lines
  locked (doorbell-not-dashboard · two-kinds-of-knowing · "the platform doesn't trust
  Hebe — it authenticates her").
- [ ] **T6 — R2 beat drills.** Each beat 3× clean + its broken run (P3.S2.T7 iris-bff
  kill · a memory miss → L0 re-ask · Telegram down → L1 pre-fired) until every fallback
  switch < 15 s. Log `../readiness/r2-drills.md`.
- [ ] **T7 — R3 + R4.** R3 stopwatch runs (capture final screenshots + the L1 artifacts
  from the best run). **R4 dry run: HB-R2 pre-show → the full arc twice consecutively,
  ≤ 20′ each, zero operator intervention** — fact variance = fail → fix fixture/wording →
  re-run. Record `../readiness/r4-<date>.md` with HB-B 1–8 checked.
- [ ] **T8 — Wrap.** CZ mirror iff scheduled (HB-D6) else disposition · findings filed ·
  STATUS → done · repo README design-table row + task-mgmt progress log updated · freeze
  rule forward (post-R4: cluster + fixtures frozen; only HB-R1/R2 permitted).

## Verify block

```sh
# R4: two consecutive unaided arcs ≤20' — operator-touch counter 0
ls design/hebe-demo/readiness/r4-*.md      # exists, HB-B 1–8 checked
ls design/hebe-demo/beats/artifacts/       # L1 artifacts present
```
