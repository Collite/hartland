# SD — Tatrman Studio demo on Hartland · Architecture

> **Effort SD** (Studio demo), planned 2026-07-23. The demo of **FO-A1** (Studio Modeler +
> Studio Designer, arc closed 2026-07-22) and **FO-A2** (Studio Planner, arc closed
> 2026-07-22) on the **Hartland** world. This corpus *consumes, never reopens*: the FO design
> (`project/common/frontends-offering/design.md`, FO-1…33), the A1 corpus
> (`…/designer/authoring/`), the A2 corpus (`…/studio-planning/planner/`), and the Hartland
> demo corpus (this repo, `design/`). Demo assets live **here** (BM-9: `Collite/hartland` is
> the single home for demo assets; tatrman/tatrman-platform stay code-only). Companions:
> [`00-demo-narrative.md`](./00-demo-narrative.md) · [`contracts.md`](./contracts.md) ·
> [`plan.md`](./plan.md) · [`tasks/`](./tasks/).

## 1. What is being built

Not software — **a runnable demo**: a rehearsable, resettable environment + fixtures +
script proving the FO-A1/A2 arcs on the Hartland story. Five deliverable families:

1. **The plan-model delta** — `Version` dimension + `planRevenue` measure + `revenuePlan`
   cubelet added to the Hartland TTR-M model (contracts §3), authored *twice*: once for
   real (committed, feeds everything), once *live on stage* (Beat M re-enacts it from the
   pre-delta state).
2. **The plan data store** — `hartland_plan`: cube storage + the A2 substrate tables
   (journal, entry records, reservations), seeded from FY2025 actuals (contracts §4/§5).
3. **The Designer program** — `q.hartland.plan_vs_actual` (TTR-P), plus its staged-error
   variant for the validate beat (contracts §6).
4. **The demo rig** — the Studio shell + `ttr-designer-server` + `:services:studio-planner`
   + Postgres, one-command up/reset (contracts §7; SD-⚑1 decides local vs cluster).
5. **The script + readiness** — the transcript (final of `00-demo-narrative.md`), a
   `studio-demo-quirks.md`, the reset/pre-show recipes, and the E-5-style bar + dry-run
   (plan SD-P5).

**Not in this effort:** any change to FO-A1/A2 code beyond configuration (defects found go
back to the owning arcs as issues, never fixed inside the demo build) · the analysis plane
(Server 1.1.0, parked) · Studio Data Entry beats (FO-P3 product — a *pocket* at most, only
if zero extra build) · Iris↔Studio embedding (parked, FO §11) · CZ delivery build (script
mirror only if scheduled, BM-8 discipline).

## 2. The demo estate (component view)

```
                       Browser (profile 1: Maya · profile 2: Dan)
                          │  https (rig TLS per §5 / SD-⚑1)
                          ▼
              ┌───────────────────────────────────────────────┐
              │  Studio shell + launcher   (tatrman, open)     │
              │  tiles: Viewer · Modeler · Designer · Planner  │
              ├───────────────┬───────────────┬───────────────┤
              │ Viewer/Modeler│   Designer    │    Planner     │
              │ @tatrman/     │ designer-     │ @tatrman/      │
              │ designer +    │ authoring     │ studio-planner │
              │ designer-     │ (A1-W4 loop)  │ + grid-core    │
              │ authoring     │               │ (A2-W1/2/4)    │
              └──────┬────────┴──────┬────────┴──────┬────────┘
                     │ ModelDataSource│ ttrp/* doors  │ CubeEntryClient (FO-8 one door)
                     ▼               ▼               ▼
          Worker workspace     ttr-designer-server   :services:studio-planner (A2-W3)
          (hartland model =    (WS: getGraph, run,   cube door · reservations · preview/
          the git clone,       validate; A1 §1–4)    commit · form-load · round reads
          edit half)                 │               │
                                     ▼               ▼
                               [run connection]   PostgreSQL
                               hartland_us  ◄──── hartland_plan   (contracts §4)
                               (READ-ONLY actuals) (the ONLY writable store)
```

Identity: Keycloak realm `kantheon` (the Hartland personas, unchanged) when the rig is
cluster-attached; FO-29 dev-mode locally — SD-⚑2. **The Hartland warehouses stay
read-only** in every variant; all writes land in `hartland_plan` (and the model repo via
the authoring write path — Worker workspace, not the served `demo-p2` branch; see §4).

## 3. Runtime home (SD-⚑1 — RULED 2026-07-23: **A then C**)

**Bora's ruling:** both variants — **start with A on Bora's machine (macOS, Rancher
Desktop's docker engine)**, then **graduate to the hartland cluster (C)**. C is a real
later phase, not a stretch; its olymp task list is authored when P4b opens.

- **A · Local demo rig (first).** Bora's machine, containers via **Rancher Desktop
  docker** (note: RD's k3s/moby quirks from olymp README apply — locally-built images are
  directly usable; give RD enough VM memory before the PG restore):
  `pnpm` dev-or-built Studio + `ttr-designer-server` + `:services:studio-planner` (the
  A2 `acceptance-walk.mjs` operator path is the seed of this rig) + Postgres containing
  `hartland_plan` **and a restored `hartland_us`** (from the versioned demo dump —
  `data/recon/dump-manifest.md`), so Designer preview-run hits real data with zero cluster
  coupling. Identity per SD-⚑2 ruling: **anything works for A** — dev-auth (FO-29) is the
  default; the Beat-0 "same login" line gets its A-variant narration; real Keycloak/SSO is
  verified at C graduation, not before.
- **C · On the `hartland` cluster (SD-P4b, after A is demo-ready).** New olymp apps (studio FE,
  designer-server, studio-planner svc), `hartland_plan` DB on the central CNPG, Keycloak
  client `studio`, HTTPRoute `studio.20-218-224-115.nip.io`. Real SSO with the January
  personas — the strongest "one login" beat — but it touches the showcase cluster, so it
  is **forbidden inside any Kantheon-demo freeze window** and lands only via olymp PRs.
  This variant's olymp slices are listed but NOT task-listed until SD-⚑1 confirms.

**Why not "cluster-first":** the Studio images/charts don't exist yet in the hartland
estate roster; the Kantheon demo's freeze discipline (E-1) must survive this effort; and
every A1/A2 proof to date ran in the local/dev posture — the demo should stand on proven
ground first, then graduate.

## 4. Data & model flow (the "twice-authored" discipline)

- **The plan-delta is committed** to this repo (`model/md/…`, contracts §3) on a demo
  branch (`studio-demo`) — the Planner, the plan seed, and `plan_vs_actual` all build on
  it. The **stage re-enactment** (Beat M) starts from a workspace checkout *without* the
  delta (demo-reset restores that state) and re-authors it live; the doors' emission is
  byte-compared against the committed text in rehearsal (D-6 — the strongest possible
  "the graph is a view" proof).
- **Seed**: FY2025 actuals aggregated `hartland_us` → `revenuePlan` grain (month ×
  category × channel, `version='actual'`) + an FY26 `plan-fy26` starting shape
  (contracts §5). Deterministic script, oracle-checked against R0 figures (the FY25
  Marketplace total must reconcile with `data/recon/R0.md` — same numbers the January
  audience saw).
- **Round state**: version `plan-fy26` OPEN; Maya's slice = Marketplace plane
  (reservation scope per contracts §5.4).
- **demo-reset (Studio)**: restore `hartland_plan` from the seeded dump · release all
  reservations · reopen the version · clear drafts/prefs · reset the Beat-M workspace to
  pre-delta. Never touches `hartland_us`/`_cz` (inherited invariant).

## 5. Tech stack (nothing new)

Everything is the shipped A1/A2 stack: React 19 + vitest/@testing-library (TS side),
Kotlin/Ktor JDK 21 + kotest + Testcontainers PG16 (service side), `@xyflow/react` v12
canvases, Arrow IPC results, pnpm workspaces + the P2 dependency-rules gates. Demo-specific
code is **scripts and fixtures only** (seed SQL/mjs, reset scripts, form/ttrl fixtures,
compose/values files). If a beat seems to need product code, that is a finding for the
owning arc (§1 scope rule), or an honest-degradation variant of the beat.

## 6. Decisions

- **SD-D1 · Demo assets live in `Collite/hartland`** (BM-9 extension): this corpus under
  `design/studio-demo/`, fixtures under `data/plan/` + `model/` delta + `run-set/studio/`.
- **SD-D2 · The demo consumes closed arcs.** A1/A2 contracts are frozen inputs; defects →
  issues on the owning repos; the demo may *configure* and *stub-per-shipped-CAP* but
  never patch product semantics. (The shipped A2-CAP-201/202/203 seams are *features* of
  the story — "ratification swaps the implementation, not the contract" — not gaps to
  hide.)
- **SD-D3 · Plan grain = month × category × channel** (+`Version`), storage == load grain
  v1: 10 TPC-DS categories × 12 months × 3 channels = 360 plan cells — big enough to make
  spreading real, small enough to stay legible on a projector; recording-grain contrast
  is a spoken beat, not a data problem.
- **SD-D4 · Beat M is re-enacted, not improvised** — the twice-authored discipline (§4)
  with a byte-compare rehearsal check.
- **SD-D5 · Local-first (A), then cluster graduation (C)** — RULED by SD-⚑1: A on Bora's
  machine (Rancher Desktop docker) first; C is a committed later phase (see §3).
- **SD-D6 · One locale per delivery** (BM-8 inherited); EN first; the CZ mirror is an
  SD-P5 conditional task.
- **SD-D7 · Same personas as January** (Maya/Dan · Markéta/Tomáš) — continuity is the
  selling line ("same login, different day"); no new Keycloak users unless Satellite R's
  scoped-write persona is ruled in (SD-⚑4).

## 7. Flags — ALL RULED by Bora 2026-07-23 (verdict table: `tasks/00-task-management.md`)

- **SD-⚑1 · Runtime home = A then C.** Start on Bora's machine with Rancher Desktop's
  docker; graduate to the hartland cluster afterward (§3). P4b's olymp task list is
  authored when P4b opens.
- **SD-⚑2 · Identity in A = anything (relaxed).** Dev-auth is fine for A; local Keycloak
  optional if trivial. Real Keycloak/SSO is checked **only at C graduation** — the
  Beat-0 SSO narration runs in its A-variant until then.
- **SD-⚑3 · Designer preview-run posture = per SD-P0 probe** (confirmed). The probe of
  draft `ttrp/run` vs the A1-CAP-003 stub decides the Beat-D variant; record it in the
  verdict table when known.
- **SD-⚑4 · Satellite R = OUT for A**; reconsider at C graduation (a cluster-real
  write-RLS refusal is worth more there anyway).
- **SD-⚑5 · Freeze window = acknowledged.** Bora presents the demos himself and watches
  the interactions; check the Kantheon-demo freeze calendar when C work starts.
