# SD-P3 · S2 — Planner beat choreography (Beat P)

> Narrative Beat P steps 1–8 turned into a rehearsable gesture script. Pre-flight: S1
> walk green (the same flow already proven at API level — this stage proves it **in the
> UI, with the stage numbers**). Artifact: `../beats/beat-p.md` — gesture-by-gesture,
> every expected on-screen number quoted from `data/plan/expected/stage-numbers.md`.

- [ ] **T1 — Steps 1–2: open + check-out + the headline spread.** Maya profile: open the
  form (read-only; actual overlay visible) → Start editing (reservation banner) → type
  the FY26 Marketplace total **$755M** → spread cascades. Record: the pre-gesture seed
  total, the post-spread per-month row for one category (from the oracle), the provenance
  highlight behavior. Screenshot each state.
- [ ] **T2 — Step 3: pins + compensation.** Pin Jan+Feb 2026 at their seeded values →
  re-type the total → verify compensation flows around pins (oracle: recompute expected
  Mar–Dec values with the pin-sum rule — grid-core's own test fixtures show the formula;
  put the two pinned + two compensated cell values in the beat sheet). Open the op-chain
  inspector on one compensated cell; screenshot the chain.
- [ ] **T3 — Step 4: block scale.** Electronics × Jul–Dec 2026 block +12% — one gesture;
  expected six cell values in the sheet. (If the shipped gesture vocabulary names/scopes
  differ, follow the product's names — the narrative adapts, not the product.)
- [ ] **T4 — Step 5: zero-base cameo.** Navigate to the seeded zero-base plane (P1.S2.T4
  choice): typed entry with explicit zero-base marks; spread into it must demand the
  seed gesture (nothing silent). Quote the exact UI copy in the sheet.
- [ ] **T5 — Step 6: preview + check-in.** Preview: 4 chips ✓, expansion rows old→new
  (spot-check 3 rows vs oracle) → Check in → success; pins re-pinned at new values;
  EntryRecordCard visible (§7 record surface). Record-id noted for the Beat-D T5 hook.
- [ ] **T6 — Step 7: the Dan contrast + round close.** Profile 2 (Dan): same form →
  "checked out by Maya Chen" read-only banner (screenshot — this is a headline slide);
  Maya: release + mark done; Dan: round dashboard slice green + add the round note.
- [ ] **T7 — Full-beat reset discipline + timing.** SD-R1 → Beat P steps 1–8 twice,
  identical numbers, ≤ 10 min; then the **joint run** with SD-P2.S2.T5 (plan_vs_actual
  now full). Non-builder run from the sheet; fix gaps; check all boxes.

## Verify block

```sh
rig/reset.sh
# run Beat P per beats/beat-p.md with a stopwatch; compare every quoted number
node rig/acceptance-walk-demo.mjs   # still green after the UI session (no state poison)
```
