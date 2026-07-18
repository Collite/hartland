# Stage 2.4 — `model md`: cubelets + measures + `md2db` binding

> **Phase 2, Stage 2.4.** Plan: [`../plan-demo-build.md`](../plan-demo-build.md) (§ Stage 2.4).
> Decisions: [`../08-czech-mirror-and-catalog-delta.md`](../08-czech-mirror-and-catalog-delta.md)
> — **BM-5** (fact cubelets Store/Web/Marketplace sales, 3 returns, weekly inventory; measures
> revenue/qty/counts/return-amt/on-hand; shape **wide**), **BM-2** (currency = per-connection
> display label, not structure), **D-6a** (no profit measure).
>
> **Goal:** the fact cubelets and measures wired to the physical facts via `md2db`; the star is
> queryable (`marketplace.2025.november.revenue`). The Money measure renders USD on `pg-hartland-us`
> and CZK on `pg-hartland-cz` — same measure, currency label from the lexicon/connection.

## Where the code lives

```
model/md/
├── measures.ttrm       # T1 — def measure revenue/quantity/orderCount/lineCount/returnAmount/onHandQty
├── cubelets.ttrm       # T2 — def cubelet storeSales/webSales/marketplaceSales/*Returns/inventory
model/binding/
└── md2db.ttrm          # T3 — md2db_cubelet (+ md2db_map for table-backed dim maps, md2db_domain for bound domains)
```

`measures.ttrm`/`cubelets.ttrm` open `model md`; `md2db.ttrm` opens `model binding`
(verified: `tests/integration/src/md-binding.test.ts` — `BINDING_OK` const).

## Library / syntax references (verified — do not guess)

- **Measure (domain, class, aggregation):** `mnt/tatrman/docs/manual/en/15-md-model.md`:
  ```ttrm
  def measure net     { domain: md.Money, class: additive, aggregation: sum }
  def measure balance { domain: md.Money, class: semiAdditive,
                        aggregation: { default: sum, time: latestValid }, validBy: asOf }
  ```
- **Cubelet (grain + measures):**
  ```ttrm
  def cubelet sales { grain: [Customer.code, Product.code, Time.day], measures: [net, balance] }
  ```
- **`md2db_cubelet` (wide + long):** `15-md-model.md` + `md-binding.test.ts`:
  ```ttrm
  model binding
  def md2db_cubelet sales_fact {
    cubelet: md.sales,
    target: db.dbo.SALES_FACT,
    shape: wide,
    attributes: { Customer.code: CUST_CODE, Time.day: TXN_DATE },
    measures:   { net: NET_AMT },
    journaling: overwrite
  }
  ```
  A long fact: `shape: { long: { codeColumn: DRIVER_CODE, valueColumn: AMOUNT } }`, measures as
  `{ fte: { code: FTE } }`. The bound `attributes` **must cover the cubelet grain**; an
  attribute-through-map uses `{ via: md.map, from: { table: …, column: … } }`.
- **`md2db_map` (table-backed dim maps) + `md2db_domain` (bound domains):** `15-md-model.md`:
  ```ttrm
  def md2db_map class_cat_map { map: md.class_to_category, target: db.dbo.item,
                                columns: { ClassCode: i_class, CategoryCode: i_category } }
  def md2db_domain reason_src { domain: md.ReasonCode, source: { table: db.dbo.reason, column: r_reason_sk } }
  ```
- **Diagnostics to expect green:** `md/shape-measure-mismatch`, `md/grain-ref-unknown`,
  `md/incomplete-journaling`, `md/multisource-grain-mismatch`, `md/source-on-unbound-domain`,
  `md/binding-on-calc-map`, `md/map-columns-incomplete` (`grammar-md-changes.md §9`,
  `15-md-model.md`). The `md-binding.test.ts` seeds `md/source-on-unbound-domain` as a negative —
  mirror that harness.

## Pre-flight

- [ ] Stage 2.3 closed (dims/hierarchies/maps resolve); branch `feat/p2-s4-md-cubelets`.
- [ ] The physical fact columns exist in `model/db/` (Stage 2.1): `*_ext_sales_price`,
      `*_quantity`, `*_ticket_number`/`*_order_number`, `*_return_amt`, `inv_quantity_on_hand`,
      and the fact grain keys (`*_item_sk`, `*_sold_date_sk`, `*_warehouse_sk`, `*_customer_sk`,
      `*_promo_sk`, `*_reason_sk`).
- [ ] The dimension attributes the cubelet grains reference exist (Stage 2.3): `Product.itemCode`,
      `Calendar.day`, `DistributionCentre.dcCode`, `Customer.customerCode`, `ReturnReason.reasonCode`.

---

## Tasks

- [ ] **T1 — `def measure`s (`model/md/measures.ttrm`).**
  Author the D-6/D-6a measure set — **revenue, quantity, order/line counts, return amount, on-hand
  qty only**:
  ```ttrm
  model md
  def measure revenue     { domain: md.Money,    class: additive, aggregation: sum }
  def measure quantity     { domain: md.Quantity, class: additive, aggregation: sum }
  def measure orderCount   { domain: md.Quantity, class: additive, aggregation: countDistinct }  # distinct order/ticket
  def measure lineCount    { domain: md.Quantity, class: additive, aggregation: count }
  def measure returnAmount { domain: md.Money,    class: additive, aggregation: sum }
  def measure onHandQty    { domain: md.Quantity, class: semiAdditive,
                             aggregation: { default: sum, time: latestValid }, validBy: week }  # weekly snapshot
  ```
  `revenue`/`returnAmount` share the currency-agnostic **`Money`** domain — the USD/CZK label is a
  lexicon/connection display fact (Stage 2.5 / `connections.toml`), **not** a second measure.
  `onHandQty` is a snapshot → semi-additive with a `validBy` (the weekly grain), per the manual's
  `balance` example. **No `net_profit`/`margin`/`cost` measure** (D-6a) — the domains to build one
  don't exist and the db columns aren't modeled.

- [ ] **T2 — `def cubelet`s (`model/md/cubelets.ttrm`, shape wide).**
  One cubelet per fact, each a grain (conformed `Dimension.attribute`s) × its measures:
  ```ttrm
  def cubelet marketplaceSales {
    grain: [Product.itemCode, Customer.customerCode, Calendar.day, DistributionCentre.dcCode, Promotion.promoCode],
    measures: [revenue, quantity, orderCount, lineCount]
  }
  def cubelet storeSales { grain: [Product.itemCode, Customer.customerCode, Calendar.day, Store.storeCode, Promotion.promoCode],
    measures: [revenue, quantity, orderCount, lineCount] }
  def cubelet webSales   { grain: [Product.itemCode, Customer.customerCode, Calendar.day, Promotion.promoCode],
    measures: [revenue, quantity, orderCount, lineCount] }
  def cubelet catalogReturns { grain: [Product.itemCode, Customer.customerCode, Calendar.day, DistributionCentre.dcCode, ReturnReason.reasonCode],
    measures: [returnAmount, quantity] }
  # storeReturns, webReturns analogous (webReturns: no DC; ReturnReason on all three)
  def cubelet inventory { grain: [Product.itemCode, DistributionCentre.dcCode, Calendar.week], measures: [onHandQty] }
  ```
  Conformed dimensions are **shared across cubelets** (same `Product`/`Calendar`/`Customer` defs) —
  this is what makes "which categories drove the drop" a cross-cubelet drill (T6 checks the sharing).
  Every grain ref must resolve to a real `Dimension.attribute` (`md/grain-ref-unknown`).

- [ ] **T3 — `md2db` bindings (`model/binding/md2db.ttrm`).**
  Author `model binding` with:
  - **`md2db_cubelet`** per cubelet → its physical fact table, `shape: wide`, mapping every grain
    attribute → its `*_sk`/code column and every measure → its value column. E.g.:
    ```ttrm
    def md2db_cubelet marketplaceSales_fact {
      cubelet: md.marketplaceSales,
      target: db.dbo.catalog_sales,
      shape: wide,
      attributes: { Product.itemCode: cs_item_sk, Customer.customerCode: cs_bill_customer_sk,
                    Calendar.day: cs_sold_date_sk, DistributionCentre.dcCode: cs_warehouse_sk,
                    Promotion.promoCode: cs_promo_sk },
      measures: { revenue: cs_ext_sales_price, quantity: cs_quantity, lineCount: cs_order_number, orderCount: cs_order_number }
    }
    ```
    The bound `attributes` must **cover the grain**. Inventory binds to `inventory` with
    `Calendar.week` reached through the date_dim week map if needed
    (`{ via: md.day_to_week, from: { table: db.dbo.date_dim, column: d_week_seq } }`).
  - **`md2db_map`** for each **table-backed** dim map from Stage 2.3 (Product roll-ups on `item`,
    Store→state, etc.) supplying the case columns (`columns: { … }` covering every from/to domain,
    else `md/map-columns-incomplete`).
  - **`md2db_domain`** for any **bound** domain (if a coded domain is `kind: bound`) → its source
    table/column; a source on an unbound domain is `md/source-on-unbound-domain` (the seeded
    negative in `md-binding.test.ts`).
  - **Journaling:** the demo is read-only serving; either omit `journaling` (read-only) or set
    `overwrite` consistently — if present, **every measure must be bound**
    (`md/incomplete-journaling`).

- [ ] **T4 — Currency renders per connection (verify, don't invent grammar).**
  **Verified:** there is no `unit`/`currency` on a `Money` domain. Prove the intended behavior
  instead: the **same** `revenue` measure + the **same** cubelet binding serve both connections;
  the currency label differs because (a) the physical value is USD in `hartland_us` / CZK in
  `hartland_cz` (Phase 1 FX-scale) and (b) the on-screen unit label is a lexicon/connection display
  fact (`connections.toml` `currency = USD|CZK`; Stage 2.5 lexicon may carry a per-locale unit
  form). Add a note in `md2db.ttrm` documenting this, and a test assertion (T6-4) that exactly one
  `Money`-domained `revenue` measure exists and one `md2db_cubelet` binds it per fact (no
  per-currency duplication). This is the "same measure renders both" acceptance, at the model tier;
  the live USD/CZK render is Phase 3 H3.

- [ ] **T5 — Model-load: cubelet resolution + drill query (write first; TDD-shaped).**
  Add an md-binding round-trip test (mirror `tests/integration/src/md-binding.test.ts`: a logical
  `model md` file + a `model binding` file through the LSP, diagnostics per file). Assert
  mocked/unit:
  1. **Parse + bind clean** — `model/md/*` + `model/binding/md2db.ttrm` publish **zero** `md/*`
     diagnostics (no shape/grain/journaling/domain errors).
  2. **Cubelet↔fact completeness** — every `def cubelet` has an `md2db_cubelet`; every grain
     attribute and every measure is bound; the shape is `wide`.
  3. **Drill resolves** — the dot-path `marketplace.2025.november.revenue` (channel cubelet →
     Calendar year→month → measure) resolves through the bound star on the model (the resolver
     path, as `lexicon-lsp` checks a `for:` target). Also `warehouse`/DC drill (#4) and the
     stockout weekly path (#8: `inventory` × `DistributionCentre.dcCode` × `Calendar.week`).

- [ ] **T6 — Unit tests: binding completeness, aggregation, conformed-dimension sharing.**
  Mocked/unit (md-binding harness + lint md rules):
  1. **Binding completeness** — grain coverage + measure binding per cubelet; a deliberately
     under-bound cubelet raises `md/incomplete-journaling`/grain error (negative case).
  2. **Aggregation correctness (vs fixture)** — `revenue`/`returnAmount` = `sum`, `orderCount` =
     `countDistinct`, `onHandQty` = semi-additive with `validBy` (a semi-additive without `validBy`
     raises `md/semiadditive-no-validby` — negative).
  3. **Conformed-dimension sharing** — `Product`/`Calendar`/`Customer` are referenced by ≥2
     cubelets (assert the grain refs point at the *same* dimension defs), so a category drill spans
     Store+Web+Marketplace uniformly.
  4. **No profit + single Money revenue** — no measure over a cost/margin domain; exactly one
     `revenue` (Money) measure, bound once per fact (T4).
  Run: `pnpm --filter @tatrman/integration-tests test -- md-binding` and
  `pnpm --filter @tatrman/lint test -- md-cubelet`.

## DONE bar

`model/md/` declares the measures (revenue/quantity/order+line counts/returnAmount/onHandQty, no
profit) and the fact cubelets (Store/Web/Marketplace sales + 3 returns + weekly inventory,
`shape: wide`, conformed dims shared); `model/binding/md2db.ttrm` binds every cubelet to its
physical fact with full grain + measure coverage, plus the table-backed dim maps and any bound
domains; **the md+binding round-trip publishes zero `md/*` diagnostics**, the drill
`marketplace.2025.november.revenue` (and the #4/#8 drills) resolve, and the single `Money` revenue
measure binds once per fact (currency is a per-connection display fact). Committed on
`feat/p2-s4-md-cubelets`.

## Verify block

```sh
pnpm -r build
pnpm --filter @tatrman/integration-tests test -- md-binding   # zero md/* diagnostics + drill resolution
pnpm --filter @tatrman/lint test -- md-cubelet                # grain/aggregation/binding rules
grep -RniE 'net_profit|margin|cost' model/md model/binding/md2db.ttrm   # → no matches (D-6a)
```

*(The live USD-vs-CZK render of the same measure over both connections is Phase 3 H3 — verified
here only at the model tier: one measure, one binding, currency-agnostic domain.)*
