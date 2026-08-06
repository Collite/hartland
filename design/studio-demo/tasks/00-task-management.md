# SD — Studio demo · Task management

> The umbrella over the SD mini-task-lists. Structure: **Plan → Phase → Stage → task list
> of 6–8 atomic tasks**. Plans: [`../plan.md`](../plan.md) · [`../architecture.md`](../architecture.md)
> · [`../contracts.md`](../contracts.md) · the narrative [`../00-demo-narrative.md`](../00-demo-narrative.md).

## Rules for the implementer (read before every session)

1. **Check checkboxes as you go** — each task the moment it's done, in the task-list file
   itself. Never batch at the end; the checkbox state is the coordination surface.
2. **TDD where there is code or data**: the task lists put the test/oracle task BEFORE the
   build task. Write the assert first, watch it fail, then build. (Beat choreography tasks
   are "rehearse + beat-sheet" instead of tests — the beat sheet is their artifact.)
3. **Never patch product code** (SD-D2). A defect in tatrman/tatrman-platform → file the
   issue, add it to `../findings.md`, take the honest-degradation path, move on.
4. **Every on-screen number traces to the seed oracle** (`data/plan/expected/`). If a beat
   shows a number the oracle doesn't predict, that's a task failure, not a shrug.
5. **Frozen inputs:** FO-A1/A2 contracts, the Hartland demo dumps, the Keycloak realm
   file. You configure them; you do not edit them. Contract-shaped problems → ⚑ Bora.
6. **Branch discipline:** all repo work on `studio-demo`; commits DCO-signed; Bora pushes/
   merges (house convention).
7. **When you learn something that bit you**, append it to `../studio-demo-quirks.md`
   immediately (it is a P5 deliverable but a running file from P0).
8. **Flags:** SD-⚑1…5 (architecture §7). Defaults let you proceed through P3; check the
   verdict table below before starting P2.S2 (⚑3) and P4 (⚑1/⚑2).

## Flag verdict table (fill in as Bora rules)

| Flag | Question | Default | Verdict | Date |
|---|---|---|---|---|
| SD-⚑1 | runtime home A / A+C | A, C stretch | **A + C RULED (Bora): start A on Bora's machine, Rancher Desktop docker; then graduate to the hartland cluster** | 2026-07-23 |
| SD-⚑2 | identity in A: dev-auth / local Keycloak | local Keycloak | **RELAXED (Bora): anything works for A (dev-auth fine); Keycloak verified only at C graduation** | 2026-07-23 |
| SD-⚑3 | Beat-D variant: draft-live-run / graduate-then-run | per P0 probe | **RULED: per P0 probe — probe verdict decides, no further ruling needed** | 2026-07-23 |
| SD-⚑4 | Satellite R in v1 script | out | **OUT for A (Bora); reconsider at C graduation** | 2026-07-23 |
| SD-⚑5 | freeze-window calendar clear for P4b | n/a unless C | **ACKNOWLEDGED (Bora presents + watches interactions); check calendar when C work starts** | 2026-07-23 |

## The lists

### SD-P0 — Pre-flight & probes
- [ ] [`tasks-sd-p0-preflight.md`](./tasks-sd-p0-preflight.md) (7 tasks)

### SD-P1 — The plan world
- [ ] [`tasks-sd-p1-model-delta.md`](./tasks-sd-p1-model-delta.md) (7 tasks)
- [ ] [`tasks-sd-p1-seed-fixtures.md`](./tasks-sd-p1-seed-fixtures.md) (8 tasks)

### SD-P2 — Modeler + Designer beats  *(may run ∥ SD-P3 after P1)*
- [ ] [`tasks-sd-p2-s1-modeler-beat.md`](./tasks-sd-p2-s1-modeler-beat.md) (7 tasks)
- [ ] [`tasks-sd-p2-s2-designer-beat.md`](./tasks-sd-p2-s2-designer-beat.md) (7 tasks)

### SD-P3 — Planner beat  *(may run ∥ SD-P2 after P1)*
- [ ] [`tasks-sd-p3-s1-service-loop.md`](./tasks-sd-p3-s1-service-loop.md) (8 tasks)
- [ ] [`tasks-sd-p3-s2-stage-choreography.md`](./tasks-sd-p3-s2-stage-choreography.md) (7 tasks)

### SD-P4 — Rig hardening + identity
- [ ] [`tasks-sd-p4-rig-identity.md`](./tasks-sd-p4-rig-identity.md) (7 tasks)
- [ ] *(P4b — cluster graduation: task list authored ONLY if SD-⚑1 = C, as an olymp-side list)*

### SD-P5 — Script, rehearsal, readiness
- [ ] [`tasks-sd-p5-script-dryrun.md`](./tasks-sd-p5-script-dryrun.md) (8 tasks)

## Progress log

| Date | Session | What moved | Notes |
|---|---|---|---|
| 2026-07-23 | planning | corpus + task lists authored | awaiting Bora: ⚑ verdicts + A1 merge / A2 push |
