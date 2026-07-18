# Hartland demo — the build plan (revised, three phases)

> **Master build plan for the Kantheon capabilities demo**, revised 2026-07-18 (S11) to Bora's
> three-phase framing and the **Bilingual-Mirror arc** (`08-czech-mirror-and-catalog-delta.md`).
> It supersedes the implicit "next: /planning" split noted at the end of `00-control-room.md`
> and **absorbs the existing olymp `plan-cluster.md` (H1–H5) as Phase 3's deployment slice**.
>
> **Read first:** `demo-transcript.md` (the design artifact; Appendix A = the US requirements
> rollup), `05-d-ttrm-spec.md` (entity roster, measures, both Shems), `06-e-cluster-spec.md`
> (estate + ops + the E-5 demo-ready bar), `07-f-script.md` (rehearsal ladder R0–R5), the
> control-room decision log, and **`08-czech-mirror-and-catalog-delta.md` (BM-1..BM-8 + the
> open Q-BM questions this plan assumes the leans for)**.
>
> **Unit convention** (`planning-conventions.md`): a **phase** ships something deployable, a
> **stage** something testable, a **task** is atomic. Full per-stage task lists are written
> **after Bora signs off this plan + the delta** (Bora's Q4 = "design-delta + plan first"). This
> document stops at stage goals + ~6 task titles each. **Stream/lane:** `dev` /
> `senior2` (the kantheon demo effort's existing lane) for Phases 1–2; Phase 3's olymp slice
> tracks in `plan-cluster.md`. Set both in the effort STATUS.md at task-list time.

---

## Where the work lives (BM-9 — hartland repo is the home; kantheon is code-only)

**`Collite/hartland`** (cloned at `collite-gh/hartland`, currently a stub) holds **all** demo
assets — data scripts, model, run-set, agents/Shems, and a copy of the demo design docs.
**olymp** keeps the GitOps cluster overlay. **kantheon** keeps only *code* (the constellation
services + any new Proteus goldens). Proposed hartland repo tree:

```
Collite/hartland/
├── model/                     # BM-5 — the TTR-M model ("model lives in a model folder", Bora)
│   ├── db/                    #   model db (physical schema subset)
│   ├── er/                    #   model er + er2db binding
│   ├── md/                    #   model md (star) + md2db / md2er binding
│   ├── lexicon/               #   model lexicon locale en / locale cs
│   └── queries/               #   q.hartland.* #1–15
├── agents/                    # ai-models-analog: hartland agent def (Ariadne source)
│   └── golem/shems/           #   golem-hartland + golem-hartland-finance overlays
│       └── prompts/{en,cs}/   #   both prompt bundles (cs now in scope, BM-6)
├── data/                      # ALL data build (was kantheon/surgery/ — moved per BM-9)
│   ├── redate/                #   run-redate.sh (+23y)
│   ├── localize-cz/           #   CZ geography + CZK + reasons (hartland_cz only)
│   ├── catalog/               #   taxonomy + bilingual generator + 03-catalog UPDATEs (us, cz)
│   ├── seed/                  #   02-seed-incident — Memphis DC (us) / Brno DC (cz)
│   ├── recon/                 #   recon battery + committed baselines (was design/recon)
│   └── README.md              #   the data-pipeline order (supersedes surgery/README.md)
├── run-set/                   # hartland-query run-set (both worlds) — was "kantheon-owned"
└── design/                    # demo design docs copied here (transcript, control room,
                               #   08-delta, this plan) — the demo's self-contained home
```

| Repo | Phase 1 (data) | Phase 2 (model) | Phase 3 (cluster/dry-run) |
|---|---|---|---|
| **`Collite/hartland`** | `data/` — catalog, seeds, localize, recon, dumps (**both worlds**) | `model/` + `agents/` — db/er/md/binding/lexicon + both Shems | `run-set/` consumed by the cluster; design docs |
| **olymp** (`clusters/hartland/`) | — | — | H1–H5 bring-up (extended for 2 connections) — `plan-cluster.md`, Ariadne source = hartland repo |
| **kantheon** (code only) | — | Proteus goldens for new query shapes (service test assets) | constellation services (consumed, not built here) |

Data dump artefacts land in the `tpcds-staging` SeaweedFS bucket under `hartland/us/` and
`hartland/cz/` (extends S-10).

### Cross-cutting deliverable — `hartland-pg` on every cluster (BM-10)

The Phase-1 dumps don't only feed the showcase cluster: the hartland dataset becomes the
**ecosystem's standard e2e/nightly test fixture**. A shared **`hartland-pg`** (both DBs,
read-only, restored from the Phase-1 dumps) is deployed on **bp-dsk, collite-o1, and hartland**,
and the pending e2e tests (nightly contexts, SV-P4 S5/S7) repoint to it — defaulting to **CZ**.
This is authored once as an olymp platform component and gates on **Phase 1** (raw-SQL contexts)
and **Phase 2** (model/agent contexts). Full specification + per-surface deltas:
**`test-fixture-hartland-replan.md`**. The showcase cluster's own H2.1 CNPG (Phase 3) *is* this
shared component, not a bespoke one.

---

## Phase summary

| Phase | Deliverable | Gated by |
|---|---|---|
| **Phase 1 — Two-world dataset** | `hartland_us` **and** `hartland_cz` databases: re-dated, carrying the **full bilingual per-item catalog**, CZ fully localized (towns/addresses/DCs/CZK), the DC-meltdown story seeded in **both**; versioned demo dumps of each. Built in **`Collite/hartland/data/`**. | pristine `tpc-ds-1g` dump (have it) |
| **Phase 2 — TTR-M model stack** | **`Collite/hartland/model/`** + `agents/`: one `db`+`er`+`md`+`binding`+`lexicon(en,cs)` model loading clean against **both** connections; `q.hartland.*` #1–15; both Shems (en+cs). | Phase 1 (a seeded DB to resolve against) |
| **Phase 3 — Dry-run & cluster** | The `hartland` showcase cluster serving **both worlds**, demo-ready per the E-5 bar, a full **dry-run** of the arc passing twice unaided (in the delivery locale); a completeness review of every prior-design task. | Phases 1+2; G1/G4 (pins, waves) from `plan-cluster.md` |

---

# Phase 1 — The two-world dataset

**Deliverable (deployable):** two restore-ready, versioned demo dumps — `hartland_us` and
`hartland_cz` — each re-dated (+23y), catalog-rich (meaningful bilingual products), fully named
(US: TN/Memphis; CZ: CZ-towns/Brno, CZK), and story-seeded (DC meltdown S1–S4), with committed
recon baselines and frozen R0 numbers.

**Pre-flight:** pristine `tpc-ds-1g` dump available (✔, `06-e` pipeline step 1); the existing
re-dated+seeded `hartland` (US) DB on `test-pg-1` (✔ per Bora — becomes `hartland_us`); Q-BM-1/2/5
decided (FX-scale CZK, generator+hero, Brno+Praha+Ostrava+Plzeň+Hradec Králové). All scripts
authored in **`Collite/hartland/data/`** (BM-9 — not kantheon).

### Stage 1.1 — Catalog taxonomy & bilingual generator
*Goal:* a deterministic, reproducible generator that maps every `i_item_sk` → a believable
bilingual product, from a curated taxonomy — the single source both worlds draw from.
- T1: Curate the taxonomy: 10 TPC-DS categories → classes → brands → manufacturers → product
  lines (en + cs names for each level; hero brands per Q-BM-2).
- T2: Per-item attribute rules: name, `i_item_id`/SKU/EAN-style code, packaging (`i_container`),
  size (`i_size`), brand/manufacturer/class assignment — deterministic on `hash(i_item_sk)`.
- T3: **Invariants harness:** assert the generator preserves `i_item_sk`, category, and price
  band for every row (seeds/recon depend on these).
- T4: Bilingual output: en table for US, cs table for CZ (diacritics correct; same key → mirror
  product, localized name/brand/packaging).
- T5: Emit as idempotent SQL `UPDATE` scripts (`data/catalog/`) — one per world, hash-keyed.
- T6: Unit tests (mocked DB): determinism (same seed → same output), key-preservation, FK
  integrity, bilingual coverage (no NULL cs/en names).

### Stage 1.2 — US catalog application (`hartland_us`)
*Goal:* the existing US world gains the meaningful catalog without disturbing the seeded story.
- T1: Rename/confirm the existing `hartland` DB on test-pg-1 as **`hartland_us`** (or alias);
  snapshot pre-catalog dump for rollback.
- T2: Run `data/catalog/us` UPDATEs on `hartland_us`.
- T3: Re-run recon variants (r01/r02/r05/r08/r13) — confirm the story numbers are **unchanged**
  by the catalog rewrite (keys/categories preserved).
- T4: Spot-verify hero products/brands appear in the category-drill query (#3) and top-items (#5).
- T5: Commit the refreshed US recon baseline next to the 2026-07-09 set.
- T6: Verification: catalog integrity report (row counts, NULL scan, FK check) green.

### Stage 1.3 — CZ world bring-up & geography localization (`hartland_cz`)
*Goal:* a Czech-grounded clone of the physical world — same schema, CZ places, CZK.
- T1: `createdb hartland_cz` + restore the **pristine** `tpc-ds-1g` dump; `data/redate/run-redate.sh
  <..> 23 hartland_cz` (+23y, as US).
- T2: Localize geography: `store` → CZ towns (Praha HQ, Brno, Ostrava, Plzeň, Olomouc, Liberec);
  `warehouse` → 5 CZ DCs with **Brno DC := the ex-NULL/meltdown warehouse** (mirror S-8a).
- T3: Localize `customer_address` → Czech obce + PSČ + kraj (deterministic map from US states/
  cities so per-region distributions stay stable — the "regional branch dies even" property holds).
- T4: **CZK conversion** per Q-BM-1 (lean: FX-scale monetary fact/dim columns ×~23, round to
  price points) — `ext_sales_price`, list/wholesale (physical only; excluded from model), any
  money-typed dim columns; document the FX constant.
- T5: Localize return reasons (`r_reason`) → Czech strings, keeping "Nedorazilo včas" clear of
  the other reasons (mirror S-9's delivery-timing isolation).
- T6: Verification (mocked/DB): schema parity vs `tpc-ds-1g`, redate correctness, CZK scaling
  audit, geography FK integrity.

### Stage 1.4 — CZ catalog & cs value-labels
*Goal:* the Czech per-item catalog, mirroring US keys with localized content.
- T1: Run `data/catalog/cz` UPDATEs on `hartland_cz`.
- T2: Verify mirror integrity: every `i_item_sk` present in both worlds maps to the same
  taxonomy node, localized name/brand/packaging/size.
- T3: Produce the `valueLabels` seed data (cs+en) for coded dims used by the lexicon (Phase 2)
  — categories, reasons, DC names, container/size codes.
- T4: Spot-verify CZ hero products in the category-drill and top-items queries.
- T5: Commit the CZ catalog-integrity report.
- T6: Verification: bilingual coverage lint (no untranslated on-screen dimension member).

### Stage 1.5 — Seed the story in `hartland_cz` (Brno DC meltdown)
*Goal:* the same authored ground truth (C-3a/BM-7), DC = Brno, verified to the same shape.
- T1: Re-point the seed scripts (`data/seed/02-seed-incident`) at `hartland_cz` / Brno DC.
- T2: S1 inventory zero-streak (wks 31–47/2025, Brno, ~70% items); S2 ~60% Marketplace-line
  deletion (wks 32–48, Brno) + matching `catalog_returns`; S3 "Nedorazilo včas" skew (wks 33–49).
- T3: Apply the Q-4-frozen magnitude (same % as US; CZK absolute).
- T4: Run the recon variants on `hartland_cz`: confirm −10..12% Marketplace H2-2025, 17-week Brno
  streak, reason-skew pops — **parity with US** (BM-7).
- T5: Red-herring check: Web flat, demographics flat, promo dense, geography even (all in CZK).
- T6: Verification: side-by-side US↔CZ story-shape diff (percentages match within tolerance).

### Stage 1.6 — Dual baseline, R0 freeze & versioned dumps
*Goal:* frozen numbers + the two restore artefacts the cluster (Phase 3) consumes.
- T1: Final recon on both worlds; assemble the **R0 number table** per world (transcript App. A
  ⟨R0⟩ slots) — US in USD, CZ in CZK (×FX of the same figures under Q-BM-1a).
- T2: `pg_dump -Fc hartland_us` → `tpcds-staging/hartland/us/<demo-dump>`.
- T3: `pg_dump -Fc hartland_cz` → `tpcds-staging/hartland/cz/<demo-dump>`; pin both versions.
- T4: Regenerate `demo-transcript.md` ⟨R0⟩ values (US) + a CZ R0 appendix.
- T5: Disaster-recovery note: both pre-catalog and pre-seed snapshots retained.
- **Phase 1 DONE bar:** both dumps restore clean; recon on each matches the frozen R0; catalog
  integrity + bilingual coverage green on both; the US story numbers are unchanged from the
  2026-07-09 baseline (catalog is orthogonal, proven).

---

# Phase 2 — The TTR-M model stack (one model, two worlds)

**Deliverable (deployable):** the `Collite/hartland` repo — a single TTR-M model set
(`db`+`er`+`md`+`binding`+`lexicon(en,cs)`) that **loads clean and resolves against both
connections**, exposes the 15 `q.hartland.*` queries, and assembles **both Shems** with en+cs
example questions. This is the ai-models-analog and the on-stage "customer-onboarding" talking
point (D-7).

**Pre-flight:** Phase 1 stage 1.1–1.2 landed (a catalog-rich, seeded DB to resolve against — the
US dump suffices for model authoring; CZ validates the lexicon); `@tatrman/*` toolchain
available; TTR-M grammar ≥ 4.4 (lexicon + md — confirmed present); CZ personas' roles known
(Q-BM-4a). The `Collite/hartland` repo exists (stub); scaffold its tree per BM-9 (model in the
top-level `model/` folder), mirroring ai-models for the `agents/` side (Q-10).

### Stage 2.1 — Repo scaffold + `model db` (physical)
*Goal:* the repo tree exists (BM-9); the physical schema is modeled in `model/db/`; both
connections declared.
- T1: Scaffold the BM-9 tree: `model/{db,er,md,lexicon,queries}`, `agents/golem/shems/…`,
  `data/…`, `run-set/`, `design/`; `agents/` side mirrors ai-models (Q-10).
- T2: `model/db` — the demo subset of TPC-DS tables (facts: store/web/catalog sales + 3 returns
  + inventory; dims: date, item, customer, customer_address, store, warehouse, promotion,
  reason, the demographics/income dims): tables, columns, types, PK/FK.
- T3: Declare the two connections: `pg-hartland-us` (USD), `pg-hartland-cz` (CZK).
- T4: Exclude `net_profit`/cost columns at the `db` layer per D-6a (or mark unmapped downstream).
- T5: `pnpm -r build` / model-load smoke: `db` model parses + resolves.
- T6: Unit tests: schema completeness vs the physical dump; PK/FK resolution; no dangling refs.

### Stage 2.2 — `model er` (logical) + `er2db` binding
*Goal:* the 19 curated entities and relationships, mapped to the physical schema.
- T1: `model er` — the D-5 entity roster (19 in) with attributes + relationships.
- T2: `er2db` binding for every entity/attribute → table/column.
- T3: Synonym/measure families from D-6 recorded as `er` structure (revenue → ext_sales_price
  sums, DC/warehouse, stockout, SKU/product/article → item, return rate) — the lexical part
  moves to Stage 2.5.
- T4: Channel vocabulary structure: catalog_*⇒Marketplace, web_*⇒Web, store_*⇒Stores.
- T5: Model-load: `ResolveArea("hartland")` + er2db resolve green on `pg-hartland-us`.
- T6: Unit tests: entity/relationship resolution; er2db completeness; measures-policy (no profit
  measure reachable).

### Stage 2.3 — `model md` — dimensions, hierarchies, domains, maps
*Goal:* the conformed dimensions of the star, with the Product hierarchy the catalog lit up.
- T1: `def domain`s (Money — per-locale unit; Date; Quantity; coded domains for category/reason/
  container/size).
- T2: `def dimension`s: **Calendar** (Y→Q→M→W→D via calc `map`s), **Product**
  (Category→Class→Brand→Manufacturer→Item), Customer, Store, Distribution Centre, Promotion,
  Return Reason.
- T3: `def hierarchy` + `def map` per dimension (table-backed for Product/Store/DC; calc-backed
  for Calendar per the MD brief's Time example).
- T4: Dimensional attributes (Product Code, Week, etc.) with domains.
- T5: Model-load: dot-path resolution smoke (`product.electronics.<class>`, `calendar.2025.november`).
- T6: Unit tests: hierarchy level ordering; map cardinality (1:N/1:1, no M:N); domain typing.

### Stage 2.4 — `model md` — cubelets + measures + `md2db` binding
*Goal:* the fact cubelets and measures wired to the physical facts; the star is queryable.
- T1: `def measure`s: revenue (`sum` over ext_sales_price), quantity, order/line counts, return
  amount, on-hand qty — with `aggregation:` and per-locale Money domain.
- T2: `def cubelet`s (shape `wide`): Store-sales, Web-sales, Marketplace-sales, the three
  returns, weekly Inventory — each measures × its conformed attributes.
- T3: `md2db_cubelet` / `md2db_domain` / `md2db_map` bindings → the physical facts/dims.
- T4: Currency: the Money domain's unit resolves per connection (USD on us, CZK on cz) — verify
  the same measure renders both.
- T5: Model-load: cubelet resolution + a drill query (`marketplace.2025.november.revenue`) on
  both connections.
- T6: Unit tests: cubelet↔fact binding completeness; measure aggregation correctness vs fixtures;
  conformed-dimension sharing across cubelets.

### Stage 2.5 — `model lexicon` (en + cs)
*Goal:* the bilingual naming layer — the locale mechanism BM-2 rides on.
- T1: `model lexicon locale en` — terms/patterns/examples over er/db/md carriers (channel
  synonyms, revenue/turnover, stockout, return-rate, product/SKU).
- T2: `model lexicon locale cs` — Czech terms (tržba/obrat/utržit; sklad/distribuční centrum;
  vyprodáno; reklamace) over the same carriers; diacritics per contract §7.
- T3: `valueLabels` (en+cs) for coded dims from Stage 1.4 T3 (categories, reasons incl.
  "Nedorazilo včas", DC names, container/size codes).
- T4: Inline `lexicon { terms: [...] }` sugar on the headline measures/dimensions where cleaner.
- T5: Model-load: cs and en resolution both green; a cs question form resolves to the same target
  as its en twin.
- T6: Unit tests: term→target resolution (no missing/wrong-model/duplicate), fuzzy cs-diacritic
  match, bilingual value-label coverage.

### Stage 2.6 — Preferred queries + both Shems
*Goal:* the 15 queries and the two assembled Shems, en+cs, hitting pattern plans.
- T1: `q.hartland.*` #1–15 (D-2) expressed on the model — drills (#3/#4/#5) via md dot-paths;
  CASE-sum shapes within proven Proteus unparse space; year params default 2021–2026.
- T2: Proteus golden PG unparse per query (new goldens for CASE-sum + md-derived shapes).
- T3: `golem-hartland` Shem overlay ("Hartland Analytics", area `hartland`, en+cs
  example_questions, counter_examples, D-6a exclusion).
- T4: `golem-hartland-finance` Shem overlay (F-1: CFO-only visibility, query subset).
- T5: Persona roles per Q-BM-4 wired into `visibility_roles`.
- T6: Verification (mocked): every example_question (en+cs) resolves to a pattern plan; both
  Shems assemble; **Phase 2 DONE bar** — model loads clean against **both** connections,
  ResolveArea green, ListQueries returns 15 with params, goldens pass, no profit column
  reachable, cs+en lexicon resolves.

---

# Phase 3 — Dry-run & the showcase cluster

**Deliverable (deployable):** the `hartland` showcase cluster (olymp `clusters/hartland`)
serving **both worlds**, demo-ready per the **E-5 bar**, with a full **dry-run** of the arc
passing twice unaided — plus a completeness review that every task implied by the prior design
(07-f ops, satellites, E-4) is accounted for.

**Pre-flight gates** (from `plan-cluster.md`, extended): **G1** MP-4 tags cut · **G2**
`Collite/hartland` **populated** (model + run-set = Phase 2 done) · **G3** *both* demo dumps in
staging (= Phase 1 done) · **G4** constellation waves proven on bp-dsk (themis/pythia wave 4,
hebe wave 6, Iris P4, Metis/Charon) · **G5** Q-12 hardware. *(All Q-BM sub-decisions resolved
2026-07-18 — one CNPG/two DBs, single-locale-per-delivery — so no design gate remains.)*

> Phase 3 **is** the olymp `plan-cluster.md` (H1–H5), with the deltas below folded in. Keep the
> olymp `[O]` task lists in `plan-cluster.md`; keep kantheon-side task lists (run-set,
> rehearsals) in `project/kantheon/implementation/`. This section is the master index + the
> second-world/dry-run/review additions.

### Stage 3.0 — Task-completeness review (Bora: "review all the other tasks")
*Goal:* nothing from the prior design is dropped before the dry run.
- T1: Inventory every actionable item across `demo-transcript.md` App. A, `06-e` E-4/E-5,
  `07-f` R0–R5 + fallbacks L0–L4, the satellites (G governance, D Discover, SPLIT, ε coda).
- T2: Cross-check each against Phases 1/2/3 stages; list orphans.
- T3: Fold orphans into the right stage or a `plan-cluster.md` task; record the mapping.
- T4: Confirm the fixtures (S-3/S-4 dashboards, routine, personas) are each owned by a task.
- T5: Produce the completeness matrix (requirement → owning task) as the Phase-3 entry doc.
- T6: Sign-off checkpoint with Bora before H2+ starts.

### Stage 3.1 — Cluster fork & foundation  → **plan-cluster.md H1**
Fork bp-dsk, trim to the E-3 roster, pin the image policy. (No delta; the second world touches
data/wiring, not the fork.)

### Stage 3.2 — The two warehouses  → **plan-cluster.md H2, extended**
*Goal:* both demo databases serve read-only — via the **shared `hartland-pg` component** (BM-10).
- Per H2.1/H2.2: the `hartland` CNPG is the **`platform/data/hartland-pg/`** component from
  `test-fixture-hartland-replan.md` §1 (Q-BM-3a: one CNPG, two DBs) — the *same* component also
  composed into bp-dsk + collite-o1, not a bespoke one.
- **Δ:** provision **both** `hartland_us` and `hartland_cz`, each with a read-only role +
  ClusterExternalSecret (`pg-hartland-{us,cz}-ro`); restore both demo dumps; **seed sanity on
  both** (H2.3 run twice — Memphis streak on us, Brno streak on cz).

### Stage 3.3 — Estate wired for both worlds  → **plan-cluster.md H3, extended**
*Goal:* the constellation answers over either world through one model.
- Per H3.1: Ariadne model Git source = `Collite/hartland` (Q-9 single-source check).
- **Δ:** **two** Arges connections `pg-hartland-us` + `pg-hartland-cz`; **two** Kyklop
  `world.table-connections` mappings (same model tables → each DB).
- Per H3.2: both Shems register; **Δ Q-BM-4:** Keycloak realm gains the CZ personas alongside
  Maya/Dan; **Δ:** cs prompt bundle mounted (BM-6).
- **Δ DONE:** every example_question resolves through the full live path on **both** connections
  (en over us, cs over cz); persona visibility contrast holds.

### Stage 3.4 — The `hartland-query` run-set (both worlds)  → **plan-cluster.md H4, extended**
*Goal:* the query surface proven mechanically for each world.
- Per H4: the run-set lives in **`Collite/hartland/run-set/`** (BM-9 — was "kantheon-owned"),
  pointed at the standing cluster; oracle rows for all 15 queries.
- **Δ:** oracle rows for **both** worlds (US in USD, CZ in CZK = US ×FX per Q-BM-1a); `just
  demo-check hartland` runs both worlds; the E-5 item-5 routing/forecast probes run per world.

### Stage 3.5 — Dry-run, ops & readiness  → **plan-cluster.md H5, extended**
*Goal:* demo-ready + the full dry-run Bora asked for.
- Per H5.1: `demo-reset` / `pre-show` recipes + standing-fixture install (preserve S-4 fixtures)
  — installed for **both** worlds so either can be the one delivered (BM-8).
- Per H5.2: the E-5 bar 1–7 checked **per world**. **Δ BM-8 (no cameo):** a Czech delivery uses
  a **cs mirror of `07-f`/the transcript** — a straight translation of the same beats (fixture
  names, questions, narration in Czech); author it if a Czech delivery is planned.
- **Dry-run (the exit criterion):** `demo-reset` → the full 07-f arc **twice consecutively, zero
  operator intervention, inside 30′** (E-5 item 7 / R4), **in the delivery locale**; capture
  R2/R3 artefacts + the L4 recording on-cluster. If both locales may be delivered, the dry-run
  passes in each.
- **Phase 3 DONE bar:** demo-ready declared; both worlds served + verified; the completeness
  matrix (3.0) all-green; freeze window in force until show day.

---

## Dependencies & sequencing

- **Phase 1** starts now — pristine dump in hand; US stages (1.1–1.2) build on the existing
  `hartland_us`; CZ stages (1.3–1.5) are independent and can run in parallel with US once the
  generator (1.1) exists. 1.6 (dumps) gates Phase 3's G3.
- **Phase 2** needs a catalog-rich seeded DB from Phase 1 (US dump is enough to author; CZ is
  needed to *validate* the cs lexicon — so 2.5/2.6 gate on Phase 1 CZ). Phase 2 completion = G2.
- **Phase 3** needs Phases 1+2 (G2+G3) plus the olymp/bp-dsk gates G1/G4/G5 and the new G6.
  Stage 3.0 (review) runs first and gates H2+.
- **Cross-repo (BM-9):** `Collite/hartland` owns Phases 1 **and** 2 **and** the run-set (`data/`,
  `model/`, `agents/`, `run-set/`, `design/`); olymp owns the H1–H5 bring-up (Phase 3) and reads
  the hartland repo for the model + run-set; kantheon holds only code (services + new Proteus
  goldens). The olymp `plan-cluster.md` stays the pointer doc for the `[O]` slices.

## Open

All Q-BM sub-decisions were **resolved 2026-07-18** (see `08-czech-mirror-and-catalog-delta.md`,
"Sub-decisions — ALL DECIDED"): FX-scale CZK · generator + hero curation · one CNPG/two DBs ·
new CZ personas · Brno+Praha+Ostrava+Plzeň+Hradec Králové · one-locale-per-delivery (no cameo).
Remaining true opens are **build-time**, not design: Q-9 (Ariadne single- vs multi-source), Q-10
(hartland repo tree concretes — the BM-9 sketch is the starting point), Q-12 (cluster hardware),
and — only if a Czech delivery is scheduled — authoring the **cs mirror of `07-f`/the transcript**.

**Test-fixture arc (BM-10, `test-fixture-hartland-replan.md`)** adds two opens: **Q-BM-7**
(retire `tpcds-query`/`tpc-ds-1g` vs keep as a benchmark regression) and **Q-BM-8** (SV-P4·S7
import leg — messy MSSQL hero for import + hartland for serve, vs hartland through import). Both
leaned in the re-plan; resolve before the nightly / SV-P4 task-list edits.
