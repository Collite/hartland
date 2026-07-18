# Hartland as the ecosystem test fixture — e2e re-plan (BM-10)

> **Companion to `08-czech-mirror-and-catalog-delta.md` (BM-10) and `plan-demo-build.md`**,
> drafted 2026-07-18 (S11, Bora brief: "all the tests to use the (Czech) hartland data … review
> the pending e2e tests (like SV-P4-S7) and re-plan them … hartland postgres (CZ+EN) on all
> clusters — bp-dsk, collite-o1, hartland"). This document (1) specifies the **shared
> `hartland-pg` deployment** on all three clusters, and (2) gives the **per-surface re-plan
> delta** for every pending e2e / nightly test that should move onto hartland. It does **not**
> rewrite the target task lists; it is the set of edits to apply to them (SV-P4 in
> `project/server/…`, the nightlies in olymp/kantheon) once Bora signs off.

---

## 0. The decision, stated once

`hartland_us` (EN, USD) + `hartland_cz` (CZ, CZK) — the two worlds Phase 1 builds — become the
**standard warehouse for all e2e / integration / nightly tests**, on **every cluster**. Tests
default to **CZ**; EN is available where an assertion is language-agnostic or specifically
checks the US world. This replaces the current per-context ad-hoc data (`tpc-ds-1g`, the erp
fixture) with one governed, story-seeded dataset shared by the demo and the suite — so the two
never drift, and the suite exercises Czech locale handling (cs lexicon, diacritic resolution,
CZK) for real.

**Source of truth:** the Phase-1 versioned demo dumps in `tpcds-staging/hartland/{us,cz}/`. When
Phase 1 re-freezes R0, the fixture is re-restored from the new dumps (one values bump + Job
re-run per cluster).

---

## 1. The shared deployment — `hartland-pg` on all three clusters

A new platform component, authored once in olymp and composed into each cluster's data tier
(this is the generalization of the demo's H2.1 CNPG to bp-dsk + collite-o1 as well).

- **`platform/data/hartland-pg/`** — a CNPG `Cluster` (mirrors `test-pg`: 1 instance, PVC sized
  for ~2× the two restored DBs) hosting **both** `hartland_us` and `hartland_cz` (Q-BM-3a: one
  CNPG, two DBs).
- **Roles + secrets:** `hartland_us_readonly` / `hartland_cz_readonly` via CNPG `managed.roles`;
  vault credentials; **`ClusterExternalSecret`s `pg-hartland-us-ro` / `pg-hartland-cz-ro`** whose
  `namespaceSelector`s match the test-harness run namespaces (exactly as
  `clusterexternalsecret-pg-tpcds-ro.yaml` does today — ESO materializes the cred when infra-up
  labels the run namespace `olymp.collite/managed-by=test-harness`).
- **Restore Job** per cluster (pattern: the `tpcds-load` Job, but `pg_restore -Fc` from
  `tpcds-staging/hartland/{us,cz}/<dump>`; idempotent drop+recreate; dump version pinned in
  values). Restores **both** DBs.
- **Composed into:**
  - **bp-dsk** — the dev bench (`data` ns), alongside the existing `test-pg`.
  - **collite-o1** — the nightly scratch cluster (nightly-testing memory; the SV-P4·S7 dry-run
    host).
  - **hartland** — the showcase cluster (this is the demo's own `hartland-pg`, H2.1 — now the
    same component, not a bespoke one).

**Sequencing:** needs the Phase-1 dumps (both worlds) = **G3**. Deploying the fixture and
repointing the *raw-SQL* contexts needs only Phase 1; repointing the *model/agent* contexts
(golem, pythia, themis, conformance) also needs **Phase 2** (the hartland model + Shems served
by Ariadne on that cluster).

---

## 2. Per-surface re-plan

### 2.1 olymp test-contexts (the nightly + on-demand run-set)

Today (`olymp/test-contexts/`): `smoke`, `theseus-runquery`, `tpcds-query`, `themis-routing`,
`golem-erp`, `pythia-rca`. The data-bearing ones reach `tpc-ds-1g`/erp on the standing `test-pg`
via `pg-tpcds` (Arges `extraEnv`) + the `pg-tpcds-ro` ClusterExternalSecret. Re-plan:

| Context | Change | Needs |
|---|---|---|
| **`tpcds-query` → `hartland-query`** | New context: Arges `extraEnv` wires **`pg-hartland-cz`** (+`pg-hartland-us`) instead of `pg-tpcds`; oracle assertions = the 15 `q.hartland.*` on CZK (US ×FX). This is the same run-set Phase 3 / `plan-cluster.md` H4 defines — **generalized to run on every cluster, not just the showcase**. Q-BM-7 decides whether the old `tpcds-query`/`tpc-ds-1g` is retired or kept as a benchmark regression. | Phase 1 (data), the model's `q.hartland.*` (Phase 2) for the higher tiers |
| **`theseus-runquery`** | Repoint its query to hartland_cz (this is the context the **scheduled nightly** runs, per `bp-dsk-run-set.txt`) — the leanest smoke, so it moves first. | Phase 1 |
| **`golem-erp` → `golem-hartland`** | The reference Golem answers over the **hartland model / CZ data** (Marketplace/Brno questions) instead of the erp shem. `context.yaml` + shem wiring + oracle. | Phase 2 (golem-hartland Shem + model) |
| **`pythia-rca`** | Repoint the RCA to hartland: Pythia finds **Brno DC** (CZ) / Memphis DC (EN) unaided — the seeded meltdown is the canonical RCA fixture. | Phase 1 (seeds) + Phase 2 (model) |
| **`themis-routing`** | Route the scripted questions to the **`hartland`** area(s) + the gap/visibility cases (both personas). | Phase 2 (area + Shems) |
| **`smoke`** | Unchanged (no warehouse). | — |
| **run-set matrix** | `kantheon/deployment/test/bp-dsk-run-set.txt` + the nightly `integration-nightly.yml` (`theseus-runquery`) update to the hartland context names. The nightly master (`olymp/.github/workflows/nightly-ecosystem.yml`, nightly-testing arc) inherits them. | after the contexts land |

**Fixture-secret ripple:** each repointed context's Arges values restate the connection env and
depend on `pg-hartland-{us,cz}-ro` in the run namespace (mirror the `pg-tpcds-ro` selector
extension). One edit per context's `arges.values.yaml` + the two ClusterExternalSecrets from §1.

### 2.2 SV-P4 · S5 — reference Golem + conformance core tier

`tasks-sv-p4-s5-golem-conformance.md` T5 authors the core tier over a **`pilot-mini` reference
model**. Re-plan: **the reference model = the hartland model (CZ), data = `hartland_cz`.**
- T5's grounding/resolve fixtures gain *real* teeth: Czech-diacritic fuzzy match, `tržba/obrat`
  synonym resolution, CZK money grounding, the cs `valueLabels` — all exercised against live
  hartland_cz rather than a synthetic mini-model.
- The conformance suite (in **tatrman**, `:conformance:`) ships the hartland model + a pinned
  slice/dump as its fixture data (or points at the standing `hartland-pg` on the kind/S2
  cluster). Keep the fixture **small and deterministic** — either a curated row-subset dump or
  the full CZ DB with the oracle rows pinned from Phase-1 R0.
- Unchanged: the matcher grammar, runner, CI gating (T2/T4/T6). Only the *model + data under
  test* switch to hartland.
- Note (from S5 findings): the reference-Golem-vs-product-Golem question is still open for Bora;
  either way it answers over hartland_cz.

### 2.3 SV-P4 · S7 — the dry acceptance run

`tasks-sv-p4-s7-dry-run.md` T1/T2: the outsider brings "their database (or a stand-in with the
hero-like schema)" and runs the quickstart (import → refine → serve → agent → governed answer →
maker loop → conformance green) on a scratch cluster. Re-plan:
- **Scratch cluster = `collite-o1`** (already the booked scratch host; nightly-testing) with
  **`hartland-pg` standing** (from §1).
- **Q-BM-8:** the quickstart's **import** leg needs a *messy* schema to show relation-derivation
  — hartland is clean TPC-DS. **Lean (a):** the outsider imports the **messy Czech MSSQL hero**
  (the S3/S4 fixture) to exercise `import-schema`, then the **serve / agent / governed-answer /
  maker-loop / conformance** legs run against **hartland_cz** (the standard data). The two legs
  exercise different clauses of the RO-3 bar; forcing hartland through import would lose the
  derivation showcase.
- T2's conformance clause runs the **hartland** core tier (from §2.2) on the outsider's install.
- Everything else in S7 (outsider booked, no-help rule, findings triage, stretch slots) is
  unchanged.

### 2.4 SV-P4 · S3 / S4 — import-schema (scope boundary, mostly unchanged)

Already built on the messy Czech **MSSQL** hero (its whole point). **Do not** switch its hero to
hartland. **Optional add:** a hartland_cz **clean-PostgreSQL** introspection + determinism smoke
(GI-2 byte-equality on a large clean schema) as an extra component fixture — nice-to-have, not a
re-plan of the stage. Flag only.

---

## 3. What each surface gates on (summary)

- **Phase 1 done (dumps)** → deploy `hartland-pg` on all 3 clusters; repoint the raw-SQL
  contexts (`theseus-runquery`, `hartland-query` at SQL level).
- **Phase 2 done (model + Shems)** → repoint the model/agent contexts (`golem-hartland`,
  `pythia-rca`, `themis-routing`) and land the S5 conformance tier on hartland.
- **S7** → collite-o1 with `hartland-pg` standing + the S5 hartland tier + the messy hero for the
  import leg (Q-BM-8a).

## 4. Ripple back to the demo plan

`plan-demo-build.md` gains one cross-cutting deliverable (added in this revision): **"Fixture —
hartland-pg on every cluster"**, sourced from Phase 1's dumps, consumed by the nightlies and
SV-P4. The showcase cluster's own `hartland-pg` (H2.1) is now just this shared component on the
`hartland` cluster — not a bespoke one.

## 5. Open (decide before these task lists)

- **Q-BM-7** — retire `tpcds-query`/`tpc-ds-1g` vs keep as a benchmark regression. *Lean: retire
  the live nightly context; keep the pristine dump only if a test needs canonical TPC-DS oracle
  rows.*
- **Q-BM-8** — S7 import leg: messy hero for import + hartland for serve (lean a) vs hartland
  through import (loses derivation).
- Reference-Golem-vs-product-Golem (carried from S5 findings) — Bora; orthogonal to the data
  switch but touches S5/S7.
- Fixture size for the tatrman `:conformance:` suite — full CZ DB on the kind cluster vs a
  curated deterministic row-subset dump (decide at S5·T2).
