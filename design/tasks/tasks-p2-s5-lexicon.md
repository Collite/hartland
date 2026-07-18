# Stage 2.5 — `model lexicon` (en + cs)

> **Phase 2, Stage 2.5.** Plan: [`../plan-demo-build.md`](../plan-demo-build.md) (§ Stage 2.5).
> Decisions: [`../08-czech-mirror-and-catalog-delta.md`](../08-czech-mirror-and-catalog-delta.md)
> — **BM-2** (the `lexicon` layer is the locale mechanism the two-world story rides on),
> **BM-3/BM-6** (Czech world + cs in scope), **D-6** (synonym families).
> Resolution contract: `mnt/tatrman/docs/features/resolution/plan/contracts.md §7` (Czech
> diacritics are contract-observable). `valueLabels` seed data from Phase-1 Stage 1.4 T3.
>
> **Goal:** the bilingual naming layer — `locale en` + `locale cs` terms/patterns/examples over the
> er/db/md carriers, plus `valueLabels` for coded dims. A cs question form resolves to the **same
> target** as its en twin; Czech diacritics resolve.

## Where the code lives

```
model/lexicon/
├── en/
│   ├── measures.ttrm     # T1 — revenue/turnover, return-rate, stockout terms → md measures/cubelets
│   ├── channels.ttrm     # T1 — Marketplace/Web/Stores synonyms → er channel entities
│   └── examples.ttrm     # T1 — def example seeds (en)
├── cs/
│   ├── measures.ttrm     # T2 — tržba/obrat/utržit, reklamace, vyprodáno → same carriers
│   ├── channels.ttrm     # T2 — tržiště/e-shop/prodejny
│   └── examples.ttrm     # T2 — def example seeds (cs)
└── value-labels.ttrm     # T3 — valueLabels (en+cs) for category/reason/DC/container/size codes
```

Each file's first line is `model lexicon locale en` or `model lexicon locale cs` (verified:
`tests/conformance/fixtures/62-lexicon.ttrm`). Inline sugar (`lexicon: { terms: [...] }`) may be
added on carriers directly where cleaner (T4; fixture `63-lexicon-inline.ttrm`).

## Library / syntax references (verified — do not guess)

- **Lexicon file (term/pattern/example):** `mnt/tatrman/tests/conformance/fixtures/62-lexicon.ttrm`:
  ```ttrm
  model lexicon locale cs
  def term trzba { description: "revenue synonyms", for: md.measure.net, forms: ["tržba", "tržby", "obrat", "utržit"] }
  def pattern nazev { for: db.query.by_name, match: "název .*" }
  def example q1 { for: md.cubelet.sales, text: "Kolik jsme utržili za Octavie" }
  ```
- **Inline lexicon sugar:** `63-lexicon-inline.ttrm`
  (`def entity customer { attributes: [...], lexicon: { terms: ["zákazník", "odběratel"] } }`).
- **`valueLabels` (per-locale + aliases):** `64-value-labels-aliases.ttrm`:
  ```ttrm
  def attribute status {
      type: int,
      valueLabels {
          "1": { label: { cs: "Aktivní", en: "Active" }, aliases: ["živý", "aktivni"] },
          "2": { cs: "Neaktivní", en: "Inactive" }
      }
  }
  ```
  (also fixture `10-attribute.ttrm` for the terser `valueLabels: { "1": { cs, en } }` form).
- **Resolution behaviour + diacritics:** `tests/integration/src/lexicon-lsp.test.ts` (a `for:`
  target resolves to the measure def; go-to-def jumps to it; a dangling `for:` publishes an
  unresolved-reference) and `docs/features/resolution/plan/contracts.md §7` (the fuzzy/resolver
  cascade treats Czech diacritics as observable — `aktivni` ≈ `aktivní`).

## Pre-flight

- [ ] Stages 2.2–2.4 closed (er/md carriers exist for `for:` targets); branch `feat/p2-s5-lexicon`.
- [ ] **Phase 1 Stage 1.4 T3 done** — the cs+en `valueLabels` seed data (categories, reasons incl.
      **"Nedorazilo včas"**, DC names Brno/Praha/…, container/size codes) is committed under
      `data/catalog/`. The **en half** of 2.5 can be authored before this; the **cs half** and the
      value-labels need it — this is why 2.5 gates on Phase-1 CZ (plan-overview dependency note).
- [ ] A `hartland_cz` DB (Phase 1 Stages 1.3–1.4) is available to *validate* cs resolution against
      (authoring uses the US structure; cs correctness is checked with the CZ world).

---

## Tasks

- [ ] **T1 — `model lexicon locale en` (terms/patterns/examples over the carriers).**
  Author `model/lexicon/en/*.ttrm`. Cover the D-6 families as `def term`s whose `for:` points at
  the md/er/db target:
  - **Channels** — `for: er.catalog_sales` forms `["marketplace","3P","third-party","marketplace sellers","fulfilled by Hartland"]`;
    `for: er.web_sales` forms `["web","online","hartland.com","e-shop"]`;
    `for: er.store_sales` forms `["stores","brick and mortar","retail stores","TN stores"]`.
  - **Measures** — `for: md.measure.revenue` forms `["revenue","sales","turnover"]`;
    `md.measure.returnAmount`/return-rate forms `["returns","refunds","RMA","return rate"]`;
    stockout `for: md.measure.onHandQty`/inventory cubelet forms
    `["out of stock","zero on hand","stockout","availability"]`.
  - **Entities** — SKU/product/article `for: md.dimension.Product` (or `er.item`) forms
    `["product","SKU","article","item"]`; DC `for: md.dimension.DistributionCentre` forms
    `["warehouse","fulfillment center","distribution center","DC"]`.
  - `def pattern` for any regex-shaped trigger; `def example` seeds (en) go in `examples.ttrm`
    (these become Shem example_questions in 2.6, but a couple here exercise resolution).

- [ ] **T2 — `model lexicon locale cs` (Czech terms over the *same* carriers).**
  Author `model/lexicon/cs/*.ttrm`, mirroring T1's `for:` targets with Czech `forms:` (diacritics
  correct — contract §7):
  - **Measures** — revenue `for: md.measure.revenue` forms `["tržba","tržby","obrat","utržit"]`
    (pattern from fixture 62); return `for: md.measure.returnAmount` forms
    `["reklamace","vrácení","vratky","míra vrácení"]`; stockout `for: md.measure.onHandQty` forms
    `["vyprodáno","není skladem","nulový stav","dostupnost"]`.
  - **Channels** — marketplace `for: er.catalog_sales` forms `["tržiště","třetí strana","3P"]`;
    web `for: er.web_sales` forms `["web","online","e-shop"]`; stores `for: er.store_sales` forms
    `["prodejny","kamenné prodejny","obchody"]`.
  - **Entities** — DC `for: md.dimension.DistributionCentre` forms
    `["sklad","distribuční centrum","DC"]`; product `for: md.dimension.Product` forms
    `["produkt","zboží","artikl","položka"]`.
  Every `for:` must resolve to the **same** target its en twin uses (that's the "one model, two
  locales" invariant — T5 checks it).

- [ ] **T3 — `valueLabels` (en+cs) for the coded dimensions.**
  From the Stage 1.4 T3 seed, author `model/lexicon/value-labels.ttrm` (or attach on the md/er
  carriers). Cover: **categories** (Electronics/Elektronika, Shoes/Obuv, Jewelry/Šperky,
  Children/Dětské, …), **return reasons** (crucially `{ label: { en: "Did not get it on time",
  cs: "Nedorazilo včas" }, aliases: ["late delivery","pozdní dodání","nedorazilo"] }`), **DC names**
  (Memphis DC / Brno DC, plus Praha/Ostrava/Plzeň/Hradec Králové), **container** + **size** codes.
  Use the fixture-64 shape:
  ```ttrm
  "R-LATE": { label: { en: "Did not get it on time", cs: "Nedorazilo včas" }, aliases: ["late delivery","pozdní dodání"] }
  ```
  Keep the reason member **clear of the other reasons** (mirror S-9's delivery-timing isolation) so
  the returns-by-reason drill (#6) resolves it unambiguously in both locales.

- [ ] **T4 — Inline `lexicon` sugar on the headline carriers (where cleaner).**
  Where a synonym set belongs tightly to one carrier, use the inline form (fixture 63) instead of a
  standalone `def term` — e.g. on the `revenue` measure or the channel entities:
  `def measure revenue { domain: md.Money, aggregation: sum, lexicon: { terms: ["revenue","turnover"] } }`.
  Keep the **locale-specific** forms in the `locale cs`/`locale en` files; use inline sugar only for
  locale-neutral aliases so the two lexicons stay the single source for per-locale wording. Don't
  duplicate a term both inline and in a `def term` for the same locale (avoid duplicate-target).

- [ ] **T5 — Model-load: cs + en resolution both green (write first; TDD-shaped).**
  Add a lexicon resolution test (mirror `tests/integration/src/lexicon-lsp.test.ts`: parse the
  model + both lexicons through the LSP; check `for:` targets resolve; a dangling `for:` publishes
  an unresolved-reference). Assert mocked/unit:
  1. **Parse-clean** — every `model/lexicon/{en,cs}/*.ttrm` + `value-labels.ttrm` parses with
     zero errors and **no unresolved `for:`** (every term/example target is a real er/md/db def).
  2. **en/cs twin parity** — for each measure/channel family, the cs `def term` and the en
     `def term` resolve to the **same** target qname (e.g. `md.measure.revenue`) — a cs question
     form resolves where its en twin does.
  3. **Diacritic resolution** — a Czech form with diacritics (`tržba`, `vyprodáno`, `Nedorazilo
     včas`) resolves, and its diacritic-stripped alias (`trzba`, `nedorazilo`) also matches via the
     fuzzy cascade (contract §7). Include the "Nedorazilo včas" reason label as an explicit case.

- [ ] **T6 — Unit tests: term→target, fuzzy cs match, value-label coverage.**
  Mocked/unit (lexicon-lsp harness + resolution):
  1. **term→target correctness** — no missing target (unresolved `for:`), no **wrong-model** target
     (a term claiming an md measure that's actually a db column), no **duplicate** term for the same
     (locale, target) pair.
  2. **fuzzy cs-diacritic match** — assert the resolver matches `aktivni`→`Aktivní`-style aliases
     and the return-reason diacritic variants (contract §7 cascade).
  3. **bilingual value-label coverage** — every coded-dimension member referenced on-screen has
     **both** cs and en labels (no untranslated member — the Phase-1 "bilingual coverage lint"
     carried into the model); the reason set includes "Nedorazilo včas"/"Did not get it on time".
  4. **counter — no orphan term** — no `def term`/`def example` whose `for:` is dangling.
  Run: `pnpm --filter @tatrman/integration-tests test -- lexicon`.

## DONE bar

`model/lexicon/{en,cs}/` declare the D-6 synonym families (channels, revenue/turnover/tržba·obrat,
stockout/vyprodáno, return-rate/reklamace, product/SKU) over the shared er/md/db carriers, plus
`valueLabels` (en+cs) for every coded dimension including the isolated **"Nedorazilo včas"** reason;
**both lexicons parse with zero unresolved `for:`**, each cs term resolves to the **same** target
as its en twin, Czech diacritics resolve (with fuzzy diacritic-stripped fallback), and every
on-screen member carries both labels. Committed on `feat/p2-s5-lexicon`.

## Verify block

```sh
pnpm -r build
pnpm --filter @tatrman/integration-tests test -- lexicon    # parse + for:-resolution + en/cs twin parity + diacritics
# eyeball the reason isolation + coverage:
grep -RnE 'Nedorazilo|Did not get it on time' model/lexicon/value-labels.ttrm
grep -RnE 'locale (en|cs)' model/lexicon                     # both locales present over the same carriers
```

*(Validating cs resolution against the **live** `hartland_cz` is Phase 3 H3 — the cs correctness
here is checked at the mocked tier + against the Phase-1 CZ value-label seed.)*
