# Phase 2 — TTR-M model stack · task-list overview

> **Entry point for Phase 2 of the Hartland demo build.** This document indexes the six per-stage
> task lists, records the pre-flight gates, and states the sequencing. It is the executor's map:
> pick a stage, open its file, work the tasks top-to-bottom.
>
> **Plan (spec):** [`../plan-demo-build.md`](../plan-demo-build.md) — the Phase 2 section
> (Stages 2.1–2.6) is the authority for stage goals; this expands each into executable tasks.
> **Decisions:** [`../08-czech-mirror-and-catalog-delta.md`](../08-czech-mirror-and-catalog-delta.md)
> — **BM-2** (ONE model, TWO connections `pg-hartland-us` USD / `pg-hartland-cz` CZK; locale rides
> the `lexicon` layer; currency = a per-connection money label, not a structural difference),
> **BM-5** (explicit `db|er|md|binding|lexicon` stack; `md` = ROLAP star, Product hierarchy
> Category→Class→Brand→Manufacturer→Item), **BM-6** (both Shems, cs prompts in scope),
> **Q-BM-4a** (new CZ personas + roles).
> **Model spec (roster/measures/queries/Shems):**
> `project/kantheon/design/demo-tpcds/05-d-ttrm-spec.md` — D-5 (19 entities), D-6/D-6a (synonyms;
> revenue/qty/returns only, NO net_profit/cost), D-2 (15 `q.hartland.*` queries), both Shem overlays.
>
> **Conventions:** `project/kantheon/implementation/planning-conventions.md` — per-stage files,
> 6–8 tasks, checkboxes, pre-flight, DONE bar, TDD-shaped, **mocked unit/component tests only**
> inside stages (real-DB / cross-repo golden runs are verification notes, not stage blockers).

## Phase deliverable (deployable)

The `Collite/hartland` repo's **`model/`** + **`agents/`** trees: a **single** TTR-M model set —
`model db` (physical) + `model er` (logical) + `model md` (ROLAP star) + `model binding`
(er2db + md2db) + `model lexicon locale en` + `locale cs` — that **loads clean and resolves
against both connections**, exposes the 15 `q.hartland.*` queries with their params, excludes any
`net_profit`/cost path (D-6a), and assembles **both Shems** (`golem-hartland` "Hartland Analytics",
`golem-hartland-finance` "Hartland Finance") with en+cs example questions. This is the
ai-models-analog and the on-stage "customer-onboarding" talking point (D-7).

## TTR-M grounding (verified against the tatrman repo — cite these when writing snippets)

TTR-M is the tatrman modeling language; canonical grammar `packages/grammar/src/TTR.g4`
(≥ 4.4, `model` + `lexicon` + `md` all shipped). Model kinds (`modelCode`):
**`db | er | md | binding | cnc | lexicon`** (+ `query`). Verified fixture / doc references the
per-stage files draw on:

- **db** — `tests/conformance/fixtures/02-table.ttrm` (`model db schema dbo`, `def table` with
  `primaryKey`, inline `def column {type:...}`), `04-column.ttrm`, `05-index.ttrm`,
  `06-constraint.ttrm`, `07-fk.ttrm` (`def fk { from:[...], to:[...] }`).
- **er** — `09-entity.ttrm` (`roles:[fact,dimension]`, `displayLabel:{cs,en}`, inline attributes),
  `10-attribute.ttrm` (`valueLabels`), `11-relation.ttrm` (`from/to/cardinality/join`),
  `26-relation-fk-mapping.ttrm`.
- **binding** — `12-er2db_entity.ttrm`, `13-er2db_attribute.ttrm`, `39-default-schema-er2db.ttrm`,
  `55-schema-binding.ttrm`; md bindings in `docs/manual/en/15-md-model.md` +
  `tests/integration/src/md-binding.test.ts`.
- **md** — `docs/manual/en/15-md-model.md` (the worked example: `def domain/dimension/map/
  hierarchy/measure/cubelet` + `md2db_*`), `docs/features/md/grammar-md-changes.md` (property
  shapes), `docs/features/md/map-catalog.md` (the calc-map catalog for Calendar),
  `tests/integration/src/md-binding.test.ts` (a current-syntax logical+binding pair).
- **lexicon** — `62-lexicon.ttrm` (`model lexicon locale cs`, `def term {for, forms}`,
  `def pattern {for, match}`, `def example {for, text}`), `63-lexicon-inline.ttrm` (inline
  `lexicon: { terms:[...] }` sugar), `64-value-labels-aliases.ttrm` (per-locale `valueLabels`
  with `aliases`), `tests/integration/src/lexicon-lsp.test.ts`,
  `docs/features/resolution/plan/contracts.md §7` (resolution codes; Czech diacritics are
  contract-observable).
- **query** — `15-query.ttrm` (`model query`, `def query {language, sourceText:"""…""", parameters,
  search{keywords{en,cs}}}`).
- **area** — `56-area.ttrm` (`def area {description, packages, entities}`).
- **cnc** — pre-loaded by `@tatrman/semantics` (fact/dimension/structural/master/transaction/
  bridge). **Do NOT author it.**

**Toolchain APIs the tests call** (verified):
`parseString(content, label?) → { ast, errors, source }` and `parseFile(path)` in
`@tatrman/parser` (`packages/parser/src/walker.ts`); `parseDirectory(root)` in
`packages/parser/src/index.ts`; `resolveArea(symbols, resolver, entry, root)` →
`ResolvedArea { resolvedPackages, resolvedEntities }` and `AreaTableBuilder` in
`@tatrman/semantics` (`packages/semantics/src/area-table.ts`); the LSP integration harness
(PassThrough-paired `createServerConnection` + `initialize`/`didOpen`) in
`tests/integration/src/*.test.ts`.

> **Verified correctness note carried into every relevant stage — read this once.** TTR-M has
> **no `connection` construct and no per-connection currency `unit` on a `Money` domain**. The
> grammar's `Money` domain is currency-agnostic (`def domain Money { type: decimal }`,
> `15-md-model.md`). Therefore, in the model files themselves: (1) the physical `db`/`er`/`md`/
> binding layers are **identical** for both worlds (same TPC-DS schema, BM-2); (2) the two
> **connections** `pg-hartland-us` / `pg-hartland-cz` are declared as a **repo-level descriptor**
> (`model/connections.toml` or the `modeler.toml` manifest) that Ariadne/Arges consumes at deploy
> time (Phase 3) — they are documentation + wiring input here, resolved *live* only on the
> cluster; (3) the **currency difference is a display fact, not a structural one** — it rides the
> `lexicon` (USD label in `locale en`, CZK label in `locale cs`) and the FX-scaled physical values
> from Phase 1. Model-load "against both connections" therefore means: the one model resolves
> clean, and both connection descriptors point at schema-identical DBs. The stages below reflect
> this reality rather than inventing grammar.

## Stream / lane

`stream: dev` · `lane: senior2` (the kantheon demo effort's existing lane — set both in the effort
STATUS.md at task-list time, per planning-conventions §0).

## Stage table

| Stage | File | Goal (one line) | Status |
|---|---|---|---|
| **2.1** | [`tasks-p2-s1-repo-db.md`](tasks-p2-s1-repo-db.md) | Confirm the `model/` tree; author `model db` (physical TPC-DS subset, no profit/cost); declare both connection descriptors. | `- [ ]` |
| **2.2** | [`tasks-p2-s2-er.md`](tasks-p2-s2-er.md) | `model er` — the 19 D-5 entities + relationships; `er2db` binding; channel/measure structure (no profit measure reachable). | `- [ ]` |
| **2.3** | [`tasks-p2-s3-md-dims.md`](tasks-p2-s3-md-dims.md) | `model md` — domains, conformed dimensions, hierarchies (Product Category→…→Item; Calendar calc-backed), maps. | `- [ ]` |
| **2.4** | [`tasks-p2-s4-md-cubelets.md`](tasks-p2-s4-md-cubelets.md) | `model md` — measures + fact cubelets (`shape: wide`) + `md2db` binding; currency label per connection. | `- [ ]` |
| **2.5** | [`tasks-p2-s5-lexicon.md`](tasks-p2-s5-lexicon.md) | `model lexicon` en + cs (terms/patterns/examples), `valueLabels` (incl. "Nedorazilo včas"), diacritic resolution. | `- [ ]` |
| **2.6** | [`tasks-p2-s6-queries-shems.md`](tasks-p2-s6-queries-shems.md) | `q.hartland.*` #1–15 + both Shems (en+cs example_questions, counter_examples, visibility_roles). | `- [ ]` |

## Pre-flight gates (must be true before Phase 2 starts)

- [ ] **Phase 1 Stages 1.1–1.2 landed** — a catalog-rich, seeded `hartland_us` exists to resolve
      against (the US dump suffices to *author* the whole model; see the dependency note below).
- [ ] `@tatrman/*` toolchain available and building: `pnpm install` + `pnpm -r build` green in the
      tatrman workspace; `@tatrman/parser`, `@tatrman/semantics`, `@tatrman/lint`,
      `@tatrman/integration-tests` runnable via `pnpm --filter @tatrman/<pkg> test`.
- [ ] TTR-M grammar **≥ 4.4** confirmed (lexicon + md present) — `head packages/grammar/src/TTR.g4`
      `@grammar-version`; `model md` / `model lexicon locale` accepted (fixtures 62/63/64 parse).
- [ ] `Collite/hartland` repo cloned at `collite-gh/hartland`; the BM-9 tree is **already
      scaffolded** (`model/{db,er,md,lexicon,queries}`, `agents/golem`, `data/`, `run-set/`,
      `design/` all present as of 2026-07-18) — Stage 2.1 T1 **confirms and fills**, it does not
      create from nothing. `model/binding/` is the one folder to add (er2db + md2db `.ttrm` files).
- [ ] CZ personas' roles known (Q-BM-4a): *Markéta Nováková* (Senior Category Manager) + a CZ CFO,
      alongside Maya/Dan (US) — needed for Stage 2.6 `visibility_roles`.
- [ ] The Stage 1.4 T3 **`valueLabels` seed data** (cs+en for categories, reasons incl.
      "Nedorazilo včas", DC names, container/size codes) is committed under `data/catalog/` — the
      Stage 2.5 lexicon consumes it. (Authoring 2.5 can start against the US-side labels; the cs
      side needs Phase-1 CZ — see below.)
- [ ] A `modeler.toml` at the `Collite/hartland` **repo root** (or `model/`) declares the project
      name, `[schemas] declared = ["db","er","md","binding","lexicon"]`, and `[language] preferred`
      — see `tatrman docs/features/v1/design/architecture.md §5` for the manifest schema.

## Dependency & sequencing notes

```
2.1 (db + connections) ─► 2.2 (er + er2db) ─► 2.3 (md dims) ─► 2.4 (md cubelets + md2db) ─► 2.6 (queries + Shems)
                                                                          ▲
                                              2.5 (lexicon en+cs) ────────┘  (2.6 reads term targets)
```

- **2.1 → 2.2 → 2.3 → 2.4 is a strict chain** (each layer binds down to the one below: er2db needs
  db symbols; md2db needs both db columns and md cubelets). Author top-down in text but resolve
  bottom-up.
- **2.5 (lexicon)** carries `for:` references to `er`/`md`/`db` targets, so it depends structurally
  on 2.2–2.4 existing; but its **en half can be authored in parallel** once the carriers exist.
- **US dump suffices to author the entire model** (structure is identical for both worlds, BM-2).
  **CZ is needed only to *validate*** the cs lexicon and cs example-questions — so **Stages 2.5 and
  2.6 gate on Phase 1 CZ** (Stages 1.3–1.4: the localized DB + the cs `valueLabels` seed). Stages
  2.1–2.4 gate on Phase 1 US only.
- **Phase 2 completion = the cluster gate G2** (`plan-cluster.md`): the hartland repo's `model/` +
  `run-set/` are populated. Phase 3's Ariadne source is this repo.

## Phase 2 DONE bar (the phase exit — every stage's DONE bar rolls up to this)

The model **loads clean and resolves against BOTH connections** (`pg-hartland-us`,
`pg-hartland-cz` — schema-identical, so a clean parse+resolve on one + a connection-descriptor
check on both satisfies this at the mocked-test tier; the live both-worlds round-trip is Phase 3
H3); **`ResolveArea("hartland")` is green** (`resolveArea` returns the expected package/entity
closure with zero unresolved refs); **`ListQueries` returns the 15 `q.hartland.*`** with their
declared params; the Proteus goldens for the new CASE-sum / md-derived shapes pass (a **kantheon**
service-side cross-repo dependency — referenced, not owned here); **no `net_profit`/cost column is
reachable** through any er/md/binding path (D-6a); **cs + en lexicon both resolve** (a cs question
form resolves to the same target as its en twin, Czech diacritics observed); **both Shems assemble**
(`golem-hartland`, `golem-hartland-finance`) with every en+cs `example_question` hitting a pattern
plan and the CFO-only visibility contrast holding.
