# Phase 3 — Dry-run & the showcase cluster — overview

> **Phase-3 entry point.** Plans: [`../plan-demo-build.md`](../plan-demo-build.md) (§ Phase 3 — the
> spec these stages expand) · [`../test-fixture-hartland-replan.md`](../test-fixture-hartland-replan.md)
> (BM-10 — the shared `hartland-pg` fixture + per-surface repoint deltas) · the olymp
> **`olymp/clusters/hartland/plan-cluster.md`** (H1–H5, gates G1–G5 — Phase 3 **is** this plan with
> the second-world/fixture deltas folded in). Decisions:
> [`../08-czech-mirror-and-catalog-delta.md`](../08-czech-mirror-and-catalog-delta.md) (BM-1/2/6/9/10;
> Q-BM-3a one CNPG/two DBs; Q-BM-4a CZ personas; Q-BM-6 one-locale-per-delivery/no cameo; Q-BM-7 retire
> `tpcds-query` DB keep dump; Q-BM-8 S7 = messy hero import + hartland_cz serve).
>
> **Deliverable (deployable):** the `hartland` showcase cluster serving **both worlds** (`hartland_us`
> EN/USD + `hartland_cz` CZ/CZK) through **one** TTR-M model, demo-ready per the **E-5 bar**, with a full
> **dry-run of the 07-f arc passing twice consecutively, zero operator intervention, in the delivery
> locale** — plus a completeness review that every task implied by the prior design is owned.

## Repo ownership legend

| Tag | Repo | Phase-3 surface |
|---|---|---|
| **[O]** | **olymp** (GitOps) | `clusters/hartland/`, `platform/data/hartland-pg/`, `test-contexts/*`, per-cluster `platform/auth/` CES, `nightly-ecosystem.yml` |
| **[H]** | **Collite/hartland** (demo home, BM-9) | `run-set/` (the `hartland-query` oracle rows, both worlds); `design/` (cs mirror of 07-f, if a CZ delivery is planned) |
| **[K]** | **kantheon** (code-only) | `deployment/test/bp-dsk-run-set.txt`, `.github/workflows/integration-nightly.yml`; new Proteus goldens are **referenced, not authored here** |

Model + agents (`[H]` `model/`, `agents/`) are authored in Phase 2 and **consumed** here (Ariadne source).

## Stage table

| Stage | Goal | Maps to | Repos | File |
|---|---|---|---|---|
| **3.0** | Task-completeness review → requirement→owning-task matrix; sign-off gate before H2+ | (new) | [O][H][K] | [`tasks-p3-s0-task-review.md`](tasks-p3-s0-task-review.md) |
| **3.1** | Fork bp-dsk, trim to the E-3 roster, pin images | plan-cluster **H1** | [O] | [`tasks-p3-s1-fork-foundation.md`](tasks-p3-s1-fork-foundation.md) |
| **3.2** | The shared `hartland-pg` component on ALL THREE clusters + restore both dumps + seed sanity on both | plan-cluster **H2**, generalized (BM-10) | [O] | [`tasks-p3-s2-warehouses-fixture.md`](tasks-p3-s2-warehouses-fixture.md) |
| **3.3** | Estate wired for both worlds — Ariadne source, TWO Arges conns + TWO Kyklop maps, both Shems, CZ personas, cs prompts | plan-cluster **H3**, extended | [O] | [`tasks-p3-s3-estate-both-worlds.md`](tasks-p3-s3-estate-both-worlds.md) |
| **3.4** | The `hartland-query` run-set (both worlds) + repoint the olymp test-contexts + matrix + nightly | plan-cluster **H4**, extended (BM-10 §2.1) | [H][O][K] | [`tasks-p3-s4-run-set-repoint.md`](tasks-p3-s4-run-set-repoint.md) |
| **3.5** | demo-reset/pre-show for both worlds; E-5 bar 1–7 per world; the twice-unaided DRY RUN; freeze window | plan-cluster **H5**, extended | [O][H] | [`tasks-p3-s5-dry-run-readiness.md`](tasks-p3-s5-dry-run-readiness.md) |

## Pre-flight gates (track; do NOT start H2+ without them — from `plan-cluster.md`, extended)

- [ ] **G1 — MP-4 release tags cut** [K]: the showcase runs **pinned tags only** (E-1). Bring-up (3.1) may
      start `:testing`; the flip to pins happens before rehearsals (3.5). Gates the freeze window.
- [ ] **G2 — `Collite/hartland` populated** [H]: `model/` (db/er/md/binding/lexicon en+cs) + both Shems +
      `run-set/` — i.e. **Phase 2 done**. Gates 3.3/3.4.
- [ ] **G3 — both demo dumps in staging** [H]: `tpcds-staging/hartland/us/` **and** `.../cz/` re-dated +
      catalogued + seeded (= **Phase 1 done**, `data/recon/dump-manifest.md` pinned). Gates 3.2 restore +
      seed sanity, and the whole BM-10 fixture. **This is the fixture's source of truth.**
- [ ] **G4 — constellation waves proven on bp-dsk** (SCOPE-1): themis + pythia (wave 4), hebe (wave 6),
      Iris-P4 scope, Metis/Charon integration. Gates 3.3 DONE.
- [ ] **G5 — Q-12 hardware decided** (Bora/ops): where `hartland` physically runs; reuse the bp-dsk
      request-shrink values from day one. Gates 3.1 T1.

**BM-10 fixture note.** The showcase cluster's own CNPG (H2.1) is **not bespoke** — it is the single
`platform/data/hartland-pg/` component (Q-BM-3a: one CNPG, two DBs) **also composed into bp-dsk and
collite-o1**. Deploying the fixture + repointing the *raw-SQL* contexts (`theseus-runquery`,
`hartland-query` SQL leg) needs only **G3 (Phase 1)**; repointing the *model/agent* contexts
(`golem-hartland`, `pythia-rca`, `themis-routing`) and the S5 conformance tier needs **G2 (Phase 2)** too.

## SV-P4 cross-references (server corpus — reference only, do NOT re-author here)

The Bilingual-Mirror fixture ripples into two pending server-side stages. These task lists are owned in
`project/server/design-corpus/implementation/tasks/`; Phase 3 supplies the standing data they consume.

- **SV-P4 · S5** (`tasks-sv-p4-s5-golem-conformance.md`, **T5**) — the conformance core tier's reference
  model **switches to the hartland model (CZ), data = `hartland_cz`** (`test-fixture-hartland-replan.md`
  §2.2). Real teeth: Czech-diacritic fuzzy match, `tržba/obrat` synonyms, CZK money grounding, cs
  `valueLabels`. **Cross-ref in Stage 3.3** (the model/Shems those fixtures resolve against are what 3.3
  wires live) and **3.4** (oracle rows pinned from Phase-1 R0). Fixture-size call (full CZ DB on kind vs
  curated row-subset) is S5·T2's, not ours.
- **SV-P4 · S7** (`tasks-sv-p4-s7-dry-run.md`, **T1/T2**) — the outsider dry acceptance run's scratch host
  = **`collite-o1` with `hartland-pg` standing** (from Stage 3.2's collite-o1 overlay). Q-BM-8a: the
  outsider **imports the messy Czech MSSQL hero** (S3/S4 fixture) for the derivation showcase, then
  **serves `hartland_cz`** for the query/agent/governed-answer/maker-loop/conformance legs. **Cross-ref in
  Stage 3.2** (collite-o1 overlay is S7's dependency) and **3.5** (S7 is the external mirror of our
  internal dry-run).

## Sequencing

Stage **3.0 runs first and gates H2+** (the sign-off checkpoint). **3.1** needs only G5. **3.2** needs
3.1 + G3 (restore/seed-sanity). **3.3** needs 3.2 + G2 + G4 (DONE). **3.4** needs 3.3 + G3 (oracle rows).
**3.5** needs everything + G1 (pins) — its twice-unaided dry-run (E-5 item 7) is the single exit criterion
the demo date hangs on. Stream/lane: set in the effort STATUS.md at task-list time (`dev`/`senior2` for
the kantheon slices; the olymp `[O]` slices track in `plan-cluster.md`).
