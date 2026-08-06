# Stage 3.5 — Dry-run, ops & readiness  (= plan-cluster **H5**, extended)

> **Phase 3, Stage 3.5 — the phase exit.** Plans: [`../plan-demo-build.md`](../plan-demo-build.md) (§ Stage 3.5) ·
> [`../test-fixture-hartland-replan.md`](../test-fixture-hartland-replan.md) · **`olymp/clusters/hartland/plan-cluster.md`**
> (Phase **H5** — H5.1 ops recipes, H5.2 the bar). Decisions:
> [`../08-czech-mirror-and-catalog-delta.md`](../08-czech-mirror-and-catalog-delta.md) (**BM-8** one-locale-per-delivery,
> no cameo; cs mirror of 07-f only if a Czech delivery is planned). Design: `06-e-cluster-spec.md` **E-4 + E-5 1–7**;
> `07-f-script.md` R0–R5 + fallbacks **L0–L4**.
>
> **Goal:** demo-ready per the **E-5 bar (both worlds)** + the full **dry-run** — `demo-reset` → the 07-f arc **twice
> consecutively, zero operator intervention, inside 30′, in the delivery locale**. **Repos: [O] olymp** (recipes,
> freeze) · **[H] `Collite/hartland/design/`** (the cs mirror of 07-f, if a CZ delivery is scheduled).
>
> **SV-P4 cross-ref:** this internal dry-run is mirrored externally by **SV-P4 · S7** (`.../tasks-sv-p4-s7-dry-run.md`
> T1/T2) — the outsider's dry acceptance run on **collite-o1 + standing `hartland-pg`** (Stage 3.2), importing the
> messy Czech MSSQL hero then **serving `hartland_cz`** (Q-BM-8a). Same bar mechanics, different driver.

## Depends on

- **Stages 3.2–3.4 DONE** — both worlds served + verified; the run-set is the daily smoke.
- **G1 — pins flipped** (the freeze window requires pinned MP-4 tags).
- **G4** — the constellation waves proven (Pythia RCA / Metis forecast must actually run on stage).

## Pre-flight

- [ ] Stage 3.5 branch: `feat/p3-s5-dry-run-readiness`.
- [ ] The completeness matrix (Stage 3.0) is all-green — every requirement owned before the dry run.
- [ ] Standing-fixture definitions ready to install: "Channel Health" + "Rehearsal" dashboards, the "Monday channel
      health brief" Hebe routine, the pinned rehearsal investigation (07-f L2).
- [ ] The delivery locale(s) decided (BM-8): EN over `hartland_us`, CZ over `hartland_cz`, or both.

## Tasks

- [ ] **T1 — `just demo-reset hartland` — for both worlds (H5.1 T1 — E-4).**
  Truncate **session** state (iris sessions/SSE, Pythia investigations **except** the pinned rehearsal investigation,
  feedback) while **preserving** the S-4 standing fixtures: the **"Channel Health"** + **"Rehearsal"** dashboards, the
  **"Monday channel health brief"** Hebe routine, the Keycloak users (**both persona sets**), and the warehouse
  (read-only, **never dirtied** — the fixture is shared and restored-from-dump, so demo-reset must never touch
  `hartland-pg`). Installed so **either world can be the one delivered** (BM-8). Cross-check the preserve allow-list
  against Stage 3.0 T4.

- [ ] **T2 — Standing-fixture install script (H5.1 T2 — first run + disaster recovery).**
  A script that creates the routine + both dashboards + pins the rehearsal investigation (07-f L2) and does
  export/import of the fixtures (E-4 state backup) so a broken rehearsal restores in minutes. State backup = the demo
  dump (data, from `dump-manifest.md`) + the fixture export. Idempotent; re-runnable on either world.

- [ ] **T3 — `just pre-show hartland` (H5.1 T3 — the 07-f T-60→T-10 sequence).**
  Script the pre-show ladder where possible: `demo-reset` → warm all pods (no cold JVM/first-token on stage) → one
  throwaway Golem turn + one Pythia turn to warm caches → **fire the "Monday channel health brief" routine** (Beat 1
  depends on the inbox item existing) → **LLM provider reachability + latency probe** (Prometheus real keys) →
  print the login checklist (Maya/Markéta browser + a second profile logged in as the CFO persona). Parameterized by
  delivery locale (picks the persona set + prompt bundle).

- [ ] **T4 — Declare + document the freeze window (H5.1 T4 — E-1).**
  Document the freeze procedure in `clusters/hartland/README`: **no chart/image/model changes** (pins move pin-to-pin
  by PR only, G1); the **only** permitted operations are `demo-reset` + the daily `just demo-check hartland`. Note the
  freeze covers the `Collite/hartland` model/run-set too (Ariadne source is pinned to a ref).

- [ ] **T5 — cs mirror of 07-f / the transcript (BM-8 — [H], only if a CZ delivery is planned).**
  If a **Czech delivery** is scheduled, author the **cs mirror** in `Collite/hartland/design/`: a straight
  translation of the 07-f beats + the transcript — **fixture names, questions, and narration in Czech**, the same
  arc (BM-7 keeps the stories identical, only locale/currency differ; the CZ R0 appendix from Phase-1 1.6 T4 supplies
  the numbers). **No new content, no bilingual beat, no cameo** (BM-8). If only EN is delivered, this task is N-A
  (record the disposition in the completeness matrix). Gate: the presenter can run the CZ arc from the cs script alone.

- [ ] **T6 — E-5 bar 1–7 checked and recorded, per world (H5.2 T1 — E-5).**
  Walk and record each item **per delivered world** (either could be the one delivered, BM-8):
  1. estate green on **pinned tags**; freeze declared · 2. **seed sanity** (Memphis on us / Brno on cz) · 3. `ResolveArea`
  + Shems + full-live-path resolution · 4. all 15 queries return oracle rows live · 5. routing / RCA (finds the
  meltdown DC unaided) / forecast probes · 6. **persona visibility contrast** (CFO two cards, category manager one) ·
  7. the twice-unaided arc (T7). Record results in `data/recon/e5-<world>-<date>.md`.

- [ ] **T7 — THE DRY RUN — the twice-unaided arc (H5.2 T2 / R4 — the phase exit criterion).**
  `demo-reset` → the **full 07-f arc** (Beats 1–6 + the satellites in-scope for the delivery: G governance, D
  Discover, SPLIT, ε coda) run **twice consecutively, zero operator intervention, inside 30′**, **in the delivery
  locale**. Capture the **R2/R3 rehearsal artifacts on-cluster** during those runs: the Rehearsal dashboard pins, the
  completed rehearsal investigation, and the **L4 recording**. If **both** locales may be delivered, the dry-run
  passes in **each** (the cs arc from T5's script). A run that needed a keyboard touch or a spoken clarification the
  docs should answer is a **fail** — fix the gap (fixture/recipe/script) and re-run.

- [ ] **T8 — The rehearsal ladder R1–R3 up to the dry run (07-f §227–229; Stage 3.0 fold).**
  The ladder that precedes T7's R4 had no owning task. Run it in order, in the delivery locale:
  - **R1 (table read)** — script only, no cluster; tighten each `[BORA]` framing to ≤3 sentences.
  - **R2 (beat drills)** — each beat 3× clean on the cluster **+ one deliberately broken run per
    beat** (kill the pod / drop the plan) to drill its `[FALL]` move until the switch is <15 s with
    no visible fluster. This is the **L0–L4 fallback rehearsal** — the substantive gap Stage 3.0
    caught: verbatim-retry (L1), the Rehearsal-dashboard swap (L2), and the recording (L4) are only
    trustworthy if drilled here.
  - **R3 (full stopwatch runs)** — per-beat actuals vs the F-4 boxes; on the best run **capture the
    L2 pins + the completed rehearsal investigation + the L4 recording** (feeds T2's install and
    T7's capture), and **freeze the narration lines** that reference LooseEnds / tree-variance and
    the satellite-G "what does Finance see" Q&A (07-f §240 / satellite G-3).
  R1–R3 gate T7 (R4): the twice-unaided arc is not attempted until the beats and their fallbacks
  are drilled. See `p3-completeness-matrix.md` (R1–R3, G-3, L1).

## DONE bar — Phase 3 (from the plan)

- [ ] **demo-ready declared**; **both worlds** served + verified (E-5 1–7 recorded per delivered world).
- [ ] The dry-run passed **twice consecutively, zero intervention, ≤ 30′**, in the delivery locale (each locale if both).
- [ ] The completeness matrix (Stage 3.0) is **all-green**; every satellite (G/D/SPLIT/ε) exercised or dispositioned.
- [ ] **Freeze window in force** until show day (only `demo-reset` + daily `demo-check` permitted).
- [ ] R2/R3 artifacts + the L4 recording captured on-cluster; the cs mirror authored iff a CZ delivery is planned.

## Verify block

```sh
just pre-show hartland                                  # warms, fires the routine, prints the login checklist
just demo-reset hartland                                # session state cleared; fixtures + warehouse preserved
# fixtures survived the reset:
for f in "Channel Health" "Rehearsal" "Monday channel health"; do assert-fixture-present "$f"; done
# the arc twice, unaided (timed; operator-touch counter must be 0):
run-arc hartland --locale <en|cs> --runs 2 --max-minutes 30 --no-operator   # PASS
just demo-check hartland                                # the freeze-window daily smoke stays green
```
