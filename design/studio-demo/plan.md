# SD — Tatrman Studio demo on Hartland · Phased plan

> **Planning artefact (2026-07-23).** Inputs: [`00-demo-narrative.md`](./00-demo-narrative.md)
> · [`architecture.md`](./architecture.md) · [`contracts.md`](./contracts.md) · the closed
> FO-A1/FO-A2 corpora · this repo's demo corpus. Task lists:
> [`tasks/00-task-management.md`](./tasks/00-task-management.md). A **phase** ships something
> demonstrable, a **stage** something testable, a **task** is atomic (house convention).
> **Flags SD-⚑1…5 ALL RULED 2026-07-23** (verdicts in the task-management table): A first on
> Bora's machine (Rancher Desktop docker) → cluster graduation C after; identity relaxed for
> A (dev-auth fine, Keycloak checked at C); ⚑3 per P0 probe; Satellite R out for A.

## 0. Overall plan

```
SD-P0 pre-flight (merge/version truth, capability probes, rig skeleton, ⚑ verdicts recorded)
  ▼
SD-P1 model delta + data + fixtures (the plan world exists and reconciles with R0)
  ├────────────► SD-P2 Modeler + Designer beats build (Beats 1/M/D runnable)
  └────────────► SD-P3 Planner beat build (Beat P runnable end-to-end)
                    ▼            (P2 ∥ P3 — different surfaces, same fixtures)
SD-P4 rig hardening + identity (+P4b cluster graduation IFF SD-⚑1 = C)
  ▼
SD-P5 script, rehearsal ladder, dry-run, readiness bar (SD-B) — the exit
```

**Global pre-flight (verify at P0, do not assume):**
- FO-A1 merged: PRs **tatrman#104 + tatrman-platform#13** were OPEN (paired) at planning
  time — the demo builds on their **merged** state.
- FO-A2 pushed: the `fo-a2` lineage (P0 `1cd2c7f` … P5) was **UNPUSHED** (Bora pushes) at
  planning time.
- The Hartland demo dumps restorable (`data/recon/dump-manifest.md`).

**Global DONE (the effort exit):** SD-B items 1–7 green and recorded · the final transcript
+ `studio-demo-quirks.md` committed · `rig/` reproducible from README alone · findings
routed per contracts §9 · this corpus' STATUS updated to `done`.

## SD-P0 · Pre-flight & probes — [`tasks/tasks-sd-p0-preflight.md`](./tasks/tasks-sd-p0-preflight.md)

**Deliverable.** Branch `studio-demo` in this repo; a written **capability-probe report**
(`design/studio-demo/probes.md`) answering, from the *actual merged code*: (1) A1 loop
posture — does draft preview-run execute against live Postgres (⚑3 evidence)? (2) planner
service boot config — datasource, ports, auth expectations; (3) launcher registration
mechanics; (4) model-load path for a Worker workspace clone. Rig skeleton (`rig/up.sh`
boots shell + both services + PG, empty). SD-⚑1…5 put to Bora with the probe evidence;
verdicts recorded in architecture §7.

**Pre-flight.** A1 PRs merged; A2 pushed (chase, don't wait silently — flag if stale).
**DONE.** probes.md complete; rig boots; ⚑ verdicts recorded (or explicitly defaulted:
A · local Keycloak · beat variant per probe · R out · calendar clear).

## SD-P1 · The plan world — [`tasks/tasks-sd-p1-model-delta.md`](./tasks/tasks-sd-p1-model-delta.md) · [`tasks/tasks-sd-p1-seed-fixtures.md`](./tasks/tasks-sd-p1-seed-fixtures.md)

**Deliverable.** Contracts §3–§6 exist and prove out: the plan-model delta committed
(+ model test suite still green, lexicon labels en+cs); `hartland_plan` created + seeded;
the seed oracle reconciles with **R0** (Marketplace FY25 $683.4M etc.); the planning form
fixture passes the §8.2 catalogue; `q.hartland.plan_vs_actual` committed; pre-delta/post-
delta workspace states scripted.

**Tests first.** Model: extend `model/md/tests/md.test.mjs` + `model/tests/phase2-done`
harness for the new defs (parse + grain refs resolve) BEFORE authoring the delta. Seed:
oracle CSV asserts written from R0 before the aggregation SQL. Form: validate-form run is
the test.

**DONE.** all model tests green on `studio-demo` · seed idempotent + oracle green ·
`plan_vs_actual` parses (Calcite-clean — remember `demo-quirks.md` §2: `{brace}` params,
no alias GROUP BY, no reserved-word aliases) · SD-R1 reset restores everything in <60 s.

## SD-P2 · Modeler + Designer beats — [`tasks/tasks-sd-p2-s1-modeler-beat.md`](./tasks/tasks-sd-p2-s1-modeler-beat.md) · [`tasks/tasks-sd-p2-s2-designer-beat.md`](./tasks/tasks-sd-p2-s2-designer-beat.md)

**Deliverable.** S1 (Beats 1/M): hartland model renders in the shell (md star + er);
member-lineage drill on `marketplaceSales.revenue` live; the Beat-M authoring sequence
(Version dim → planRevenue → revenuePlan cubelet, via doors/⌘K) rehearsable from
`pre-delta`, with the **byte-compare check** (emitted text == committed delta) scripted as
`rig/check-beat-m.sh`; remove-with-consequences cameo verified on `revenue` (names its
dependents, refuses). S2 (Beat D): `plan_vs_actual` authored on the processing canvas per
the ⚑3-ruled variant; staged validate error + fix; result rows in the ResultDrawer against
seeded data; graduate → catalog + deep-link round-trip.

**Pre-flight.** P1; ⚑3 verdict. **DONE.** both beats runnable start-to-finish by someone
who is not the builder, from the beat sheets (each stage writes its beat sheet:
`design/studio-demo/beats/beat-{m,d}.md` — click-by-click, with screenshots).

## SD-P3 · Planner beat — [`tasks/tasks-sd-p3-s1-service-loop.md`](./tasks/tasks-sd-p3-s1-service-loop.md) · [`tasks/tasks-sd-p3-s2-stage-choreography.md`](./tasks/tasks-sd-p3-s2-stage-choreography.md)

**Deliverable.** S1: `:services:studio-planner` runs against `hartland_plan` with the
`revenuePlan` cube target + the form fixture; the A2 §9 acceptance-walk equivalent passes
**on the demo cube** (open→check-out→seed→preview→check-in→round-done — the shipped
`acceptance-walk.mjs` re-pointed at demo fixtures); entry records + reservation denial +
version reopen verified. S2: the stage choreography — the exact gesture sequence of
narrative Beat P steps 1–8 (typed total $755M, Q1 pins, Electronics block-scale, zero-base
cameo, preview chips, check-in, Dan contrast, done-flag) scripted in
`beats/beat-p.md` with expected on-screen numbers from the seed oracle; two-profile
(Maya/Dan) flow verified.

**Pre-flight.** P1 (fixtures); P0 probe (service config). **DONE.** the full Beat-P loop
twice back-to-back with SD-R1 between — identical numbers both times (determinism is the
demo).

## SD-P4 · Rig hardening + identity — [`tasks/tasks-sd-p4-rig-identity.md`](./tasks/tasks-sd-p4-rig-identity.md)

**Deliverable.** Identity per the ⚑2 ruling: **dev-auth (or whatever is simplest) for
variant A** — maya/dan as distinct app users across all four tiles; real Keycloak/SSO
moves to P4b; `rig/up.sh`/`reset.sh`/`preshow.sh` final (contracts §7/§8) on **Rancher
Desktop docker** (⚑1), cold-start ≤ 10 min incl. RD VM sizing note; operator README
(`rig/README.md`) good enough for a non-builder; TLS story recorded (localhost http is
fine for A). **P4b (RULED IN — cluster graduation, after A is demo-ready):** the olymp
slices — apps + `hartland_plan` on CNPG + Keycloak client `studio` + HTTPRoute + the
real-SSO verification + the Satellite-R reconsideration (⚑4) — planned as a *separate
olymp-side task list authored when P4b opens* (deploy-test pointer-doc convention);
freeze-calendar check (⚑5) is its first task.

**Pre-flight.** P2+P3 (something to harden). **DONE.** SD-B items 1–2, 6 green.

## SD-P5 · Script + rehearsal + readiness — [`tasks/tasks-sd-p5-script-dryrun.md`](./tasks/tasks-sd-p5-script-dryrun.md)

**Deliverable.** The final transcript (this corpus' `00-demo-narrative.md` → frozen
`demo-transcript-studio.md`, R0-style: every number on screen quoted from the seed
oracle); timing boxes + fallback moves per beat (the 07-f discipline, scaled down: L0
retry · L1 pre-graduated program / pre-committed plan snapshot · L2 beat-sheet screenshots
as last resort); `studio-demo-quirks.md` (everything that bit during P1–P4); the rehearsal
ladder — R1 table read → R2 beat drills incl. one deliberately broken run per beat → R3
stopwatch runs → **R4 the dry run: twice consecutively, ≤ 25′, zero intervention** (SD-B
7); readiness recorded per rehearsal in `readiness/`. CZ mirror of the transcript **iff**
a CZ delivery is scheduled (SD-D6), else disposition recorded.

**Pre-flight.** P2–P4. **DONE.** = Global DONE.

## Dependencies & sequencing

- P0 → P1 → (P2 ∥ P3) → P4 → P5; the only cross-stage coupling inside the parallel pair
  is the shared seed (frozen at P1 — a seed change after P2/P3 start re-runs both beat
  verifications). **P4b (cluster graduation) follows P5's dry-run** — graduate a proven
  demo, not a building site; the P5 exit bar is re-run on-cluster after P4b.
- **External:** A1 merge + A2 push (P0 pre-flight, Bora) · SD-⚑3 probe verdict (bites at
  P2.S2) · Kantheon-demo freeze calendar (bars P4b only). All ⚑ rulings are in
  (2026-07-23) — nothing else waits on Bora before P0.
- **Lane suggestion:** one senior lane end-to-end (the effort is fixture/script-heavy,
  not code-heavy); P2 and P3 are the natural fork point if two lanes are available
  (different surfaces, frozen shared fixtures).

## Risks & watch items

- **The merged-state drift risk:** A1/A2 closed days ago on branches; masters move
  (tatrman#62 md-dotpath already landed post-A1). P0 pins the demo to explicit SHAs of
  the merged state; upgrades are deliberate, recorded events.
- **Grammar dialect risk (contracts §3 caveat):** the delta's exact syntax is validated
  at P1.T1 against the real TTR-M grammar; the *shape* is the contract. If `dimension`
  member syntax differs, amend contracts §3, not the beats.
- **Scope magnetism:** the demo will surface product wishes (version admin UI, live cnc,
  plan approval chains). They go to `findings.md` + the owning corpus — the SD scope wall
  is architecture §1.
- **Determinism on stage:** every on-screen number comes from the seed oracle; any beat
  whose numbers can drift (e.g. re-spread after an improvised gesture) gets a "return to
  script" move in the fallback table.
- **The A2 CAP seams** (201/202/203 in-service stubs) are *shipped product posture* —
  the script narrates governance from the verdict chips without claiming PL-door
  ratification that hasn't happened.
