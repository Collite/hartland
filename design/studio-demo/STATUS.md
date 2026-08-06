---
effort: SD — Tatrman Studio demo on Hartland (FO-A1 Designer + FO-A2 Planner)
repo_home: Collite/hartland/design/studio-demo
code_home: [Collite/hartland (model delta, data/plan, rig/), tatrman + tatrman-platform (consumed read-only at pinned SHAs)]
state: ready
phase: corpus authored 2026-07-23 + **⚑SD-1…5 ALL RULED same day** (A on Bora's machine / Rancher Desktop docker → C graduation; identity relaxed for A; ⚑3 per P0 probe; Satellite R out for A); nothing executed
next: SD-P0 (pre-flight: merge tatrman#104/platform#13, push fo-a2, then probes T3–T5 on RD docker)
blocked_on: ["A1 PRs merge + A2 push (P0 pre-flight, Bora)"]
gates: ["SD-D2: demo consumes closed arcs — product defects route to owning repos", "P4b (cluster graduation) opens only after the P5 dry-run + freeze-calendar check (⚑5)", "real Keycloak/SSO + Satellite-R reconsideration ride P4b, not A"]
updated: 2026-07-23
stream: dev
lane: unassigned (suggestion: one senior lane; P2 ∥ P3 fork if two)
---

The demo of the closed FO-A1 (Studio Modeler + Studio Designer) and FO-A2 (Studio Planner)
arcs on the Hartland world: February-2026 sequel to the January Kantheon demo — *"you
watched agents find the meltdown; now watch people plan the recovery"*. Deterministic
end-to-end (PF P-2), Studio vocabulary only (FO-33/FO-30), demo assets in this repo (BM-9).

Corpus: [`00-demo-narrative.md`](./00-demo-narrative.md) (Beats 0/1/M/D/P + satellites) ·
[`architecture.md`](./architecture.md) (estate, SD-D1…7, ⚑1…5) · [`contracts.md`](./contracts.md)
(plan-model delta, `hartland_plan`, seed oracle vs R0, form, rig, SD-R1/R2 reset, SD-B bar)
· [`plan.md`](./plan.md) (SD-P0…P5) · [`tasks/00-task-management.md`](./tasks/00-task-management.md).
