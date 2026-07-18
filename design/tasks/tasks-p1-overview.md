# Phase 1 — Two-world dataset · task-list overview

> **Entry point for Phase 1 of the Hartland demo build.** This document indexes the six
> per-stage task lists, records the pre-flight gates, and states the sequencing. It is the
> executor's map: pick a stage, open its file, work the tasks top-to-bottom.
>
> **Plan (spec):** [`../plan-demo-build.md`](../plan-demo-build.md) — Phase 1 section is the
> authority for stage goals; this expands each stage into executable tasks.
> **Decisions:** [`../08-czech-mirror-and-catalog-delta.md`](../08-czech-mirror-and-catalog-delta.md)
> — BM-1..BM-10 and the Q-BM dispositions (all decided 2026-07-18).
> **Fixture consumer:** [`../test-fixture-hartland-replan.md`](../test-fixture-hartland-replan.md)
> — how the Phase-1 dumps become the ecosystem `hartland-pg` fixture (context for the DONE bars).
>
> **Conventions:** `project/kantheon/implementation/planning-conventions.md` — per-stage files,
> 6–8 tasks, checkboxes, pre-flight, DONE bar, TDD-shaped, mocked unit tests only inside stages
> (integration-flavoured data checks are verification steps, not stage blockers).

## Phase deliverable (deployable)

Two restore-ready, versioned demo dumps — **`hartland_us`** and **`hartland_cz`** — each
re-dated (+23y), carrying the **full bilingual per-item catalog**, CZ fully localized
(towns / addresses / DCs / CZK), the DC-meltdown story seeded in **both** (Memphis DC / Brno DC),
with committed recon baselines and frozen **R0** numbers. All Phase-1 assets are authored in the
**`Collite/hartland`** repo under `data/` (BM-9 — not kantheon).

## Stream / lane

`stream: dev` · `lane: senior2` (the kantheon demo effort's existing lane — set both in the effort
STATUS.md at task-list time, per planning-conventions §0).

## Stage table

| Stage | File | Goal (one line) | Status |
|---|---|---|---|
| **1.1** | [`tasks-p1-s1-catalog-generator.md`](tasks-p1-s1-catalog-generator.md) | Curated taxonomy + deterministic bilingual per-item generator emitting `catalog/{us,cz}.sql`. | `- [ ]` |
| **1.2** | [`tasks-p1-s2-us-catalog.md`](tasks-p1-s2-us-catalog.md) | Apply the catalog to `hartland_us`; prove the seeded story numbers are unchanged. | `- [ ]` |
| **1.3** | [`tasks-p1-s3-cz-bringup.md`](tasks-p1-s3-cz-bringup.md) | Create `hartland_cz`, redate +23y, localize geography (CZ towns/DCs/obce) + CZK. | `- [ ]` |
| **1.4** | [`tasks-p1-s4-cz-catalog-lexicon.md`](tasks-p1-s4-cz-catalog-lexicon.md) | Apply the CZ catalog; emit the cs+en `valueLabels` seed data for the Phase-2 lexicon. | `- [ ]` |
| **1.5** | [`tasks-p1-s5-cz-seed.md`](tasks-p1-s5-cz-seed.md) | Seed the Brno DC meltdown (S1–S4) in `hartland_cz`; verify parity with US. | `- [ ]` |
| **1.6** | [`tasks-p1-s6-dumps-baseline.md`](tasks-p1-s6-dumps-baseline.md) | Dual recon, R0 freeze, versioned `pg_dump` artefacts to `tpcds-staging/hartland/{us,cz}/`. | `- [ ]` |

## Pre-flight gates (must be true before Phase 1 starts)

- [ ] Pristine `tpc-ds-1g` SF1 dump available on `test-pg-1` (bp-dsk `data` ns) — ✔ per `06-e` pipeline step 1.
- [ ] The existing re-dated + seeded US `hartland` DB stands on `test-pg-1` — ✔ per Bora; becomes `hartland_us` (Stage 1.2 T1).
- [ ] `Collite/hartland` repo cloned at `collite-gh/hartland` (stub); `data/` subtree scaffolded per BM-9:
      `data/{redate,localize-cz,catalog,seed,recon}` + `data/README.md` (the pipeline-order doc, supersedes the old `surgery/README.md`).
- [ ] Q-BM sub-decisions decided (all ✔ 2026-07-18): FX-scale CZK (Q-BM-1a), generator + hero curation (Q-BM-2b),
      one CNPG / two DBs (Q-BM-3a), new CZ personas (Q-BM-4a), CZ DCs = Brno + Praha + Ostrava + Plzeň + Hradec Králové (Q-BM-5).
- [ ] Python 3.11+ with `uv` (or venv) for the catalog generator; `psql`/`pg_dump`/`pg_restore` reachable via the
      `kubectl --context dsk -n data exec test-pg-1 -c postgres --` access path (same as the WS-T1 runbook).
- [ ] The committed 2026-07-09 US recon baseline (`data/recon/results/`, the pre-catalog reference) is in git for the
      "story unchanged" diff in Stage 1.2 T3 / 1.6.

## Dependency & sequencing notes

```
1.1 (generator) ──┬──► 1.2 (US catalog apply)  ──────────────────────────┐
                  │                                                        ├──► 1.6 (dumps + R0)
                  └──► 1.3 (CZ bring-up) ──► 1.4 (CZ catalog) ──► 1.5 (CZ seed) ─┘
```

- **1.1 is the fork point.** The generator is the single source both worlds draw from; nothing that applies a catalog
  can start until it exists and its unit tests are green.
- **US path (1.2)** builds on the *existing* `hartland_us` (already redated + Memphis-seeded). It only adds the catalog,
  which must be proven orthogonal to the story (keys/categories/price bands preserved → recon unchanged).
- **CZ path (1.3 → 1.4 → 1.5)** is independent of the US path once 1.1 exists and can run in parallel with 1.2. It builds
  a fresh clone from the **pristine** `tpc-ds-1g` dump: redate → localize → catalog → seed (order matters — geography and
  CZK before catalog labels; seed last so recon calibrates against the localized-but-unseeded baseline).
- **1.6 gates on both paths** (both worlds recon-clean + catalog-green) and produces the two dumps that satisfy Phase 3's
  **G3** and feed the shared `hartland-pg` fixture (BM-10).
- **Cross-phase:** Phase 2 model authoring needs only the US dump (1.1–1.2); validating the cs lexicon (Phase 2 stages
  2.5/2.6) needs the CZ world (1.3–1.4, esp. the Stage 1.4 T-valueLabels output).

## Phase 1 DONE bar (from the plan)

Both dumps restore clean; recon on each matches the frozen R0; catalog integrity + bilingual coverage green on both;
the US story numbers are **unchanged** from the 2026-07-09 baseline (catalog is orthogonal, proven). Both pre-catalog
and pre-seed snapshots retained for DR (Stage 1.6 T5).
