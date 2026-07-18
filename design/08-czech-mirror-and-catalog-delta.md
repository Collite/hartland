# 08 — Czech-mirror & product-catalog delta (BM arc)

> **Design-delta, drafted 2026-07-18 (S11, Bora brief).** The demo-tpcds design effort
> converged 2026-07-09 (`00-control-room.md`, all workstreams 🟢) for a **US-only, English**
> Hartland demo. Bora's 2026-07-18 brief adds two things the ratified design does not cover — a
> **Czech mirror database** and a **meaningful per-item product catalog** — and asks that the
> whole build be reorganized into three phases with an explicit **db / er / md** TTR-M model
> stack. This document records the new decisions (the **Bilingual-Mirror arc, BM-1..BM-8**) so
> they can be folded into the control-room decision log, and lists the open sub-decisions that
> need Bora's call before the task lists are written. **The revised phased plan is
> `plan-demo-build.md` (companion).**
>
> Nothing here contradicts the ratified P-1..P-3 principles or the seeded-story canon; it
> *widens the world* (two locales) and *deepens the item dimension* (a real catalog). Where a
> BM entry supersedes an earlier decision, it says so.

---

## Scope decisions confirmed by Bora (2026-07-18)

Four framing calls answered up front, each drives the BM entries below:

1. **Model topology = one model, two connections.** A single TTR-M model set served over both
   databases, not two mirrored model sets.
2. **Czech depth = full Czech world + CZK.** Czech towns/addresses/products, CZK currency, the
   meltdown DC re-grounded to a Czech hub. Not a labels-only re-skin.
3. **Catalog scope = full per-item catalog.** Author per-item name/code/brand/manufacturer/
   packaging/size for the whole SF1 `item` population, US & CZ mirror. Not just relabeling the
   dimension hierarchy.
4. **This deliverable = design-delta + revised plan for sign-off.** Task lists follow after
   sign-off (this document + the companion plan).

**Follow-up confirmations (2026-07-18, second pass — Bora):**

5. **Repo = `Collite/hartland`** (cloned at `collite-gh/hartland`, created by Bora, currently a
   stub). It is the **single home for all demo assets** — the TTR-M model (in a top-level
   `model/` folder), every data script (re-date / localize / catalog / seed / recon), the
   `hartland-query` run-set, the agent def + both Shems, and the demo design docs. **Kantheon
   keeps only code** — nothing demo-specific stays in the kantheon repo. → **BM-9**.
6. **Q-BM-6 resolved — no on-stage locale switch / cameo.** The demo is given **entirely in one
   locale/world per delivery**: *English over the US world*, **or** *Czech over the Czech world*
   — which is precisely "one model, two worlds" in the TTR sense. Both worlds are therefore
   **equally demo-ready**; the presenter picks one. → **BM-8 (resolved)**.
7. **Q-BM-1..5 accepted at their leans:** FX-scale CZK (Q-BM-1a), generator + hero-brand curation
   (Q-BM-2b), one CNPG / two DBs (Q-BM-3a), new CZ personas (Q-BM-4a), CZ DCs = Brno (meltdown) +
   Praha + Ostrava + Plzeň + Hradec Králové (Q-BM-5).

---

## TTR-M grounding (why this is cheap to model)

Verified against `tatrman` (grammar 4.4, `docs/features/md/`, resolution `contracts.md §7`): the
model kinds Bora named are **real, shipped TTR-M constructs** — the demo exercises the language,
it doesn't stretch it.

- **`model db | er | md | binding | cnc | lexicon`** are the six model codes (grammar 3.1→4.4).
  `db` (physical), `er` (logical entities/relations), **`md`** (ROLAP multidimensional),
  `binding` (md2db / md2er / er2db mappings), `cnc` (the fact/dimension/… vocabulary already
  pre-loaded by `@tatrman/semantics`), `lexicon` (naming layer).
- **MD vocabulary** (`docs/features/md/md model brief.md`): `def domain`, `def dimension`,
  `def hierarchy` (ordered levels), `def map` (attribute mapping, 1:N / 1:1, table- or
  calc-backed), `def measure` (`domain:`, `aggregation:`), `def cubelet` (measures × attributes,
  fact-table **shape** = `wide` | `long`). Dot-path drill/filter is first-class
  (`marketplace.2025.november.revenue`, `Kaufland.address.zip`) — the brief itself uses Czech
  retail examples.
- **The `lexicon` layer is the locale mechanism** (grammar 4.4, RS-10/RS-11, contracts §7):
  `model lexicon locale <id>` with `def term` / `def pattern` / `def example`, plus inline
  `lexicon { terms: [...] }` sugar on `er`/`db`/`measure`/`dimension`/`cubelet` carriers.
  `valueLabels` accept per-locale `{ cs: …, en: … }` labels **plus aliases**; **Czech
  diacritics are contract-observable** in the fuzzy/resolver cascade. This is exactly the
  en+cs bilingual surface BM-2/BM-3 need — no grammar work, just model authoring.

Consequence: **BM-2's "one model, two connections" is a native fit.** The `db`/`er`/`md`/
`binding` models are physically identical for both worlds (same TPC-DS schema); only the
`lexicon` (en vs cs terms/value-labels) and the money measure's currency unit differ per
connection. There is no second model to keep in sync.

---

## Decision log (BM arc — append to `00-control-room.md`)

- 2026-07-18 · **BM-1 · Two-world dataset.** The demo ships **two databases**: **`hartland_us`**
  (the existing US world — re-dated + seeded + named, already on `test-pg-1` in bp-dsk) and
  **`hartland_cz`** (NEW — a fully Czech-localized mirror). Identical physical TPC-DS schema;
  the **same authored ground truth** (the DC-meltdown story, C-3a) baked into both; different
  localized content and currency. · Why: Bora — demonstrate Kantheon/TTR-M as **locale- and
  platform-agnostic**: one governed model, two believable worlds. · **Supersedes FI-4**
  ("English demo, US grounding") — English/US stays the *primary* narration, Czech is a
  first-class second world, no longer out of scope. · Rejected implicitly: a single-world demo
  (the original scope).

- 2026-07-18 · **BM-2 · One model, two connections** (topology). A **single** TTR-M model set
  (`db` + `er` + `md` + `binding` + `lexicon`) in `Collite/hartland`, served over **both**
  databases via two Arges connections **`pg-hartland-us`** (USD) and **`pg-hartland-cz`** (CZK).
  Physical schema is identical, so `db`/`er`/`md`/`binding` are shared verbatim; per-world
  differences ride the **`lexicon`** layer (en vs cs). · Why: Bora — the platform-agnostic story
  is the point; two model sets would duplicate structure and drift. · Rejected: two mirrored
  model sets (structural duplication); shared-structure-split-MD (unnecessary — the star is
  currency-agnostic, currency is data + a display label, not a structure).
  · **Two TTR-M refinements found at task-list time (2026-07-18, Phase-2 author), grounded in
  the grammar:** (1) TTR-M has **no `connection` construct** — the two connections
  `pg-hartland-us` / `pg-hartland-cz` are a **repo-level descriptor** (`model/connections.toml`)
  consumed by Ariadne/Arges at deploy time (Phase 3), not a model-language object; "one model,
  two connections" = one clean-resolving model over two schema-identical DBs. (2) `md.Money` is a
  **currency-agnostic `decimal` domain** — there is no per-connection currency unit on a measure;
  **USD vs CZK is a data fact** (the Phase-1 FX-scaled values, BM-3/Q-BM-1a) **+ a per-locale
  display label in the `lexicon`**, not a structural difference.

- 2026-07-18 · **BM-3 · Czech world depth = full + CZK.** `hartland_cz` is re-grounded, not
  re-skinned: **stores** in CZ towns (Praha, Brno, Ostrava, Plzeň, Olomouc, Liberec — HQ Praha);
  **customer addresses** = Czech obce + PSČ + kraj; **distribution centres** = CZ hubs with the
  meltdown DC as **Brno DC** (5 CZ DCs — Brno, Praha, Ostrava, Plzeň, Hradec Králové, pending
  Q-BM-5); **currency = CZK**; **labels/reasons** in Czech. The story is **currency- and
  place-invariant** (a % collapse of one warehouse's fulfilment) so the seeded arithmetic and
  the −10..12% headline carry across unchanged. · Why: Bora — a believable Czech retailer, not a
  translated US one. · Rejected: labels-only/keep-USD; hybrid (CZ world, US-named DCs — reads
  odd on stage). · Opens **Q-BM-1** (CZK authoring method) and **Q-BM-5** (DC city set).

- 2026-07-18 · **BM-4 · Full per-item bilingual catalog.** Author per-item attributes for the
  **whole SF1 `item` population** (~18k live rows/version after the SCD dedupe): meaningful
  **product name, SKU/code, brand, manufacturer, product class, packaging, size** — in **both**
  en (US) and cs (CZ). Generated **deterministically** (hash-keyed on `i_item_sk`) from a
  **curated taxonomy** (the 10 clean TPC-DS categories → classes → brands → manufacturers →
  product lines → size/pack variants) so it is reproducible and **preserves the `i_item_sk`
  keys, category assignments, and price ranges the seeds and recon depend on**. Physical `item`
  columns (`i_product_name`, `i_brand`, `i_manufact`, `i_class`, `i_size`, `i_container`,
  `i_item_id`, …) are UPDATEd in place per world. · Why: Bora — "make the products meaningful …
  believable content"; also lights up the MD **Product hierarchy** as a real drill
  (Category→Class→Brand→Manufacturer→Item) instead of dsdgen gibberish. · **Extends C-4/C-5α′**
  (which only relabeled warehouses/stores/reasons) and **D-6** (naming layer) to a full catalog
  build. · **D-6a stands** — `net_profit`/cost columns remain excluded from the model. · Keys
  and category mix are **invariants**: S1/S2 seeds key on warehouse×week (item-agnostic in
  selection), so the catalog rewrite is orthogonal to the story. · Opens **Q-BM-2** (catalog =
  generator-authored vs partly hand-curated hero brands).

- 2026-07-18 · **BM-5 · Explicit db/er/md/binding model stack** (Phase 2). Phase 2 delivers the
  full TTR-M stack, not just the ER/semantic model of `05-d`:
  - **`model db` — hartland-physical**: the demo subset of TPC-DS tables (facts + used dims),
    columns, types, PK/FK. One physical model; both connections bind to it.
  - **`model er` — hartland-logical**: the 19 curated entities (D-5) + relationships, `er2db`
    binding, bilingual labels via `lexicon`.
  - **`model md` — hartland-star** (the new headline): a ROLAP star — **fact cubelets** (Store /
    Web / Marketplace sales, the three returns, weekly inventory) with **measures** (revenue,
    quantity, order/line counts, return amount, on-hand qty) and **conformed dimensions**
    (Calendar Y→Q→M→W→D; **Product** Category→Class→Brand→Manufacturer→Item; Customer; Store;
    Distribution Centre; Promotion; Return Reason) with hierarchies, domains, aggregations;
    fact shape = **wide** (classic TPC-DS star).
  - **`model binding` — md2db** (+ md2er where an entity mediates): ties the star to the
    physical tables; `er2db` completes the picture for the ER layer.
  - **`model lexicon locale en` + `locale cs`**: the bilingual term layer over er/db/md
    carriers + coded-dimension `valueLabels`.
  · The `q.hartland.*` preferred queries (D-2, #1–15) are retained; drill queries (#3 category,
  #4 warehouse, #5 top-items) are re-expressed against the **md** model so the drill-downs are
  *modeled hierarchies*, not ad-hoc SQL. · Why: Bora's Phase 2 names db/er/md explicitly; the
  star is the natural TPC-DS framing and makes "which categories/brands drove the drop" a
  first-class dot-path. · **Supersedes `05-d`'s single-model framing** (05-d's entity roster,
  measures policy, synonym families all carry forward into `er` + `lexicon`).

- 2026-07-18 · **BM-6 · Repo & cluster ripples.** `Collite/hartland` (D-7/BM-9) carries the
  db/er/md/binding/lexicon stack + one agent def + both Shems (`golem-hartland`,
  `golem-hartland-finance`), consumed by Ariadne as its model Git source. The cluster gains a
  **second Arges connection** `pg-hartland-cz` + a **second Kyklop mapping**, and a **second
  warehouse database** (`hartland_cz`) — **placement = one CNPG, two DBs** (Q-BM-3a). Keycloak
  demo realm gains **new Czech personas** (Q-BM-4a — a CZ category manager + CZ finance,
  alongside Maya/Dan for the US world). The **cs prompt bundle** in the Shem (previously "unused
  per FI-4", `05-d`) is **now in scope**. · This extends E-2/E-3 and the olymp
  `plan-cluster.md` (H2/H3) — see Phase 3 of the companion plan.

- 2026-07-18 · **BM-9 · Demo-repo consolidation — everything demo lives in `Collite/hartland`;
  kantheon is code-only.** All demo build assets move to / are authored in the hartland repo:
  the **`model/`** folder (db/er/md/binding/lexicon per BM-5), **`data/`** (re-date, CZ
  localize, catalog generator, seeds, recon — the scripts formerly slated for `kantheon/surgery/`),
  **`run-set/`** (the `hartland-query` run-set, formerly "kantheon-owned"), **`agents/`** +
  **Shems** (+ `prompts/en`, `prompts/cs`), and a **`design/`** copy of the demo design docs
  (transcript, control room, this delta, the build plan). The **only** kantheon-side demo
  touchpoint that stays is *code*: Proteus golden unparse fixtures for any **new** query shapes
  (CASE-sum / md-derived) live with Proteus in kantheon, because those are service test assets.
  · Why: Bora — "leave kantheon for code, all the demo stuff into hartland." · Rejected: the
  original split (Phase-1 scripts in kantheon `surgery/`, only the model in the hartland repo).
  · The olymp `clusters/hartland` overlay stays in **olymp** (it is GitOps infra, not a demo
  script) and references the hartland repo for the model (Ariadne source) + run-set.

- 2026-07-18 · **BM-10 · Hartland is the ecosystem's standard test fixture — on every cluster.**
  The hartland dataset (`hartland_us` EN + `hartland_cz` CZ) becomes the **standard data for all
  e2e / integration / nightly tests** across the ecosystem, replacing the ad-hoc tpcds/erp
  fixtures. A **standing `hartland-pg`** (both DBs, read-only, restored from the Phase-1 demo
  dumps) is deployed on **all three clusters — bp-dsk, collite-o1, hartland** — and every
  data-bearing test context repoints to it, defaulting to **CZ** (the "(Czech) hartland data" —
  Bora), with EN available for language-agnostic assertions. · Why: Bora — one believable,
  governed, story-seeded dataset that the demo AND the whole test suite share; the Czech world
  also makes the suite exercise locale handling for real (cs lexicon, Czech-diacritic
  resolution, CZK). · **Scope boundary:** `import-schema` (SV-P4 S3/S4) keeps its
  deliberately-messy Czech **MSSQL** hero — its purpose is relation-derivation from an imperfect
  schema, which hartland's clean TPC-DS schema does not exercise; hartland_cz is only an
  *additional clean-PG* introspection/determinism smoke there. Mocked unit/component tests are
  unaffected. · The full re-plan (shared deployment + per-surface deltas for the nightlies and
  SV-P4 S5/S7) is **`test-fixture-hartland-replan.md`** (companion). · Opens **Q-BM-7** (retire
  `tpcds-query` / `tpc-ds-1g` vs keep it as a pristine benchmark) and **Q-BM-8** (S7's import
  leg — messy hero vs clean hartland).

- 2026-07-18 · **BM-7 · The story is mirrored, not re-invented.** `hartland_cz` carries the
  **same C-3a seed spec** (S1–S4) with the DC re-pointed to **Brno DC**: inventory zero-streak
  wks 31–47/2025, ~60% Marketplace-line deletion wks 32–48 with matching returns, "Nedorazilo
  včas" ("Did not get it on time") reason-skew wks 33–49, everything else genuinely flat. Q-4
  magnitude tuning is done **once** and applied to both worlds (same %; different absolute
  currency). · Why: parity keeps the two worlds narratively identical so a locale switch on
  stage proves *only* locale-agnosticism, nothing else moves. · Rejected: a divergent Czech
  story (muddies the message; doubles the rehearsal surface).

- 2026-07-18 · **BM-8 (resolved) · One locale per delivery — no on-stage switch or cameo.** The
  demo is presented **entirely in one world**: English over `hartland_us`, **or** Czech over
  `hartland_cz`. There is **no bilingual beat** and no locale-switch cameo — the "two worlds"
  point is made simply by the fact that *the same model* serves whichever world is presented.
  Consequence for readiness: **both worlds must be equally demo-ready** (either could be the one
  delivered), and the presenter script (`07-f` / transcript) needs a **cs mirror** for any
  Czech delivery — a straight translation of the same beats, not new content (BM-7 keeps the
  stories identical). · Why: Bora, 2026-07-18. · Supersedes the BM-8 "carry it + switch cameo"
  lean and drops the F-2/ε-adjacent bilingual-cameo idea entirely.

---

## Sub-decisions — ALL DECIDED 2026-07-18 (Bora)

| id | Question | **Decision** |
|---|---|---|
| **Q-BM-1** | CZK authoring method for `hartland_cz` monetary values | **(a) FX-scale** the USD facts ×~23 then round to believable CZK price points — preserves the seeded story arithmetic and all ratios; one R0 set carries across ×FX. |
| **Q-BM-2** | Catalog authoring — generator vs generator+curation | **(b) generator + hero curation** — a per-category set of hand-picked hero brands/manufacturers for on-screen credibility over the generated ~18k×2 floor. |
| **Q-BM-3** | `hartland_cz` DB placement | **(a) one CNPG, two DBs** (`hartland_us` + `hartland_cz` on the `hartland` CNPG). |
| **Q-BM-4** | Czech personas | **(a) new CZ personas** — e.g. *Markéta Nováková*, Senior Category Manager + a CZ CFO — alongside Maya/Dan (US). |
| **Q-BM-5** | CZ distribution-centre cities (5, meltdown = Brno) | **Brno (meltdown) + Praha + Ostrava + Plzeň + Hradec Králové.** |
| **Q-BM-6** | On-stage scope of the Czech world | **One locale per delivery — no switch/cameo** (BM-8 resolved). Both worlds equally demo-ready; script mirrored per delivery locale. |

Two **new opens** from BM-10 (test-fixture arc) — leans in the re-plan, decide before those task lists:

| id | Question | Options / lean |
|---|---|---|
| **Q-BM-7** | Fate of `tpcds-query` / the pristine `tpc-ds-1g` fixture once the e2e contexts move to hartland | (a) **retire** `tpcds-query`, `hartland-query` replaces it; (b) **keep** `tpc-ds-1g` + the frozen `q.tpcds.*` as a benchmark-vocabulary regression alongside. *Lean: retire the live nightly context; keep `tpc-ds-1g` only if a test still needs canonical TPC-DS oracle rows (likely drop once hartland-query covers the surface).* |
| **Q-BM-8** | SV-P4 **S7** quickstart's *import* leg (needs a messy schema; hartland is clean) | (a) outsider imports the **messy Czech MSSQL hero**, then serves **hartland_cz** for the query/agent/governed-answer legs; (b) force hartland through import (loses the relation-derivation showcase). *Lean: (a) — import the hero, serve hartland; they exercise different parts of the bar.* |

---

## What is unchanged (still canonical)

The A/B/C/D/E/F convergence stands except where a BM entry says "supersedes/extends":
P-1..P-3 principles; the 6-beat spine + satellites (A-1/A-3); single `golem-hartland` +
`golem-hartland-finance` cameo (B-2/F-1); SF1, +23y re-date, seeded provenance (C-1a/C-2/C-3a);
`net_profit` exclusion (D-6a); dedicated showcase cluster on pinned MP-4 tags (E-1); demo-reset /
pre-show ops (E-4); the E-5 demo-ready bar and the R0–R5 rehearsal ladder (07-f). BM widens the
*world* and the *item dimension*; it does not touch the story's shape or the readiness bar.
