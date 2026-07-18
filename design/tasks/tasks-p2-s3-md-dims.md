# Stage 2.3 — `model md`: domains, dimensions, hierarchies, maps

> **Phase 2, Stage 2.3.** Plan: [`../plan-demo-build.md`](../plan-demo-build.md) (§ Stage 2.3).
> Decisions: [`../08-czech-mirror-and-catalog-delta.md`](../08-czech-mirror-and-catalog-delta.md)
> — **BM-5** (ROLAP star; **Product** Category→Class→Brand→Manufacturer→Item; conformed dims),
> **BM-4** (the catalog lit up the Product hierarchy as a real drill).
>
> **Goal:** the conformed dimensions of the star — typed domains, dimensions with inline
> attributes + keys, hierarchies (leaf→root), and the maps between levels (Calendar calc-backed;
> Product/Store/DC table-backed). Dot-path drill resolves
> (`product.electronics.<class>`, `calendar.2025.november`). Cubelets/measures/binding are 2.4.

## Where the code lives

```
model/md/
├── domains.ttrm       # T1 — Money, Date/Day, Quantity, coded domains (Category/Class/…/Reason/Container/Size)
├── calendar.ttrm      # T2/T3 — dimension Calendar + calc maps + hierarchy (Y→Q→M→W→D)
├── product.ttrm       # T2/T3 — dimension Product + table maps + hierarchy (Category→…→Item)
├── dimensions.ttrm    # T2/T3 — Customer, Store, DistributionCentre, Promotion, ReturnReason (+ their maps/hierarchies)
└── attributes.ttrm    # T4 — any shared/standalone dimensional attributes with domains
```

All files open `model md` (verified: `tests/integration/src/md-binding.test.ts` opens
`model md` then `def domain/dimension/map/measure/cubelet`). MD attributes **must** carry
`domain:` and **must not** carry `type:` (semantic rule `md/attr-needs-domain` /
`md/attr-type-in-md`, `docs/manual/en/15-md-model.md`).

## Library / syntax references (verified — do not guess)

- **The whole worked example:** `mnt/tatrman/docs/manual/en/15-md-model.md` (domains, dimensions,
  maps, hierarchies, measures, cubelets). Property shapes:
  `mnt/tatrman/docs/features/md/grammar-md-changes.md`. Calc-map catalog:
  `mnt/tatrman/docs/features/md/map-catalog.md`.
- **Domain (scalar / calc / bound):** `15-md-model.md`:
  ```ttrm
  def domain Money   { type: decimal }
  def domain Day     { type: date }
  def domain Month   { type: int, kind: calc, restrict: { range: 1..12 } }
  def domain AccountKind { type: string, kind: bound,
      restrict: { members: { "A": { en: "Asset" }, "L": { en: "Liability" } } } }
  ```
  (`..` is the range literal; `kind: bound` ⇒ needs an `md2db_domain` source in 2.4.)
- **Dimension + inline attributes + key + hierarchies:**
  ```ttrm
  def dimension Customer {
    key: code,
    attributes: [
      def attribute code { domain: md.CustomerCode, isKey: true },
      def attribute name { domain: md.CustomerName }
    ],
    hierarchies: [geo]
  }
  ```
- **Map (calc vs table-backed):**
  ```ttrm
  def map day_to_month  { from: md.Day, to: md.Month, calc: monthOfDate }          # calc
  def map class_to_cat  { from: md.ClassCode, to: md.CategoryCode,
                          cardinality: { from: "N", to: "1" } }                    # table-backed (no calc:)
  ```
  Calc catalog names (`map-catalog.md`): truncation `truncToDay/Week/Month/Quarter/Year`;
  extraction `monthOfDate, quarterOfDate, yearOfDate, dayOfMonth, weekOfYear`; roll-up
  `quarterOfMonth`; parameterised `fiscalYearOfDate(fiscalYearStartMonth: 4)`.
- **Hierarchy (leaf→root, `via` pins the map):**
  ```ttrm
  def hierarchy calendar { dimension: md.Calendar,
    levels: [day, month via md.day_to_month, quarter via md.month_to_qtr, year via md.qtr_to_year] }
  ```
  (Also `tests/conformance`? — no md fixture; use `packages/lint/src/__tests__/md-hierarchy.test.ts`
  and `docs/features/md/design.md:206` for level-list examples.)
- A minimal **current-syntax logical model** is inlined in
  `tests/integration/src/md-binding.test.ts` (`LOGICAL` const) — copy its shape verbatim.

## Pre-flight

- [ ] Stage 2.2 closed (er + er2db resolve; `ResolveArea` green); branch `feat/p2-s3-md-dims`.
- [ ] The physical columns the maps/attributes will bind to (2.4) exist in `model/db/` — Product
      hierarchy needs `i_category`, `i_class`, `i_brand`, `i_manufact`, `i_item_id`/`i_item_sk` on
      `item`; Calendar needs `d_date`, `d_year`, `d_moy`, `d_qoy`, `d_week_seq` on `date_dim`.
- [ ] Note the **shape of the Product hierarchy** (BM-5): Category→Class→Brand→Manufacturer→Item
      (5 levels, leaf = Item). Calendar: Year→Quarter→Month→Week→Day (leaf = Day). Both authored
      leaf→root in `levels:`.

---

## Tasks

- [ ] **T1 — `def domain`s (`model/md/domains.ttrm`).**
  Author the typed value sets:
  - **`Money`** — `def domain Money { type: decimal }` (currency-agnostic; the USD/CZK label rides
    the lexicon — Stage 2.5 — and the FX-scaled values ride the DB, per the plan-overview note).
  - **`Day`** — `{ type: date }`; **`Quantity`** — `{ type: int }`.
  - **Calendar coded domains** — `Month { type: int, kind: calc, restrict: { range: 1..12 } }`,
    `Quarter { type: int, kind: calc, restrict: { range: 1..4 } }`, `Year { type: int, kind: calc }`,
    `Week { type: int, kind: calc, restrict: { range: 1..53 } }`.
  - **Coded (table-backed / member) domains** — `CategoryCode`, `ClassCode`, `BrandCode`,
    `ManufacturerCode`, `ItemCode`, `CustomerCode`, `StoreCode`, `DcCode`, `PromoCode`,
    `ReasonCode`, `ContainerCode`, `SizeCode` (`{ type: string }`; the on-screen member labels are
    supplied by the lexicon `valueLabels` in 2.5, not `restrict: members` here — keep these open
    string domains so both worlds share them). Add name domains (`CustomerName`, `ProductName`,
    `BrandName`, …) as `{ type: string }` for the display attributes.

- [ ] **T2 — `def dimension`s with inline attributes + keys.**
  Author the conformed dimensions:
  - **`Calendar`** (`calendar.ttrm`) — `key: day`; attributes `day {domain: md.Day, isKey:true}`,
    `week {domain: md.Week}`, `month {domain: md.Month}`, `quarter {domain: md.Quarter}`,
    `year {domain: md.Year}`; `hierarchies: [calendar]`.
  - **`Product`** (`product.ttrm`) — `key: itemCode`; attributes `itemCode {domain: md.ItemCode,
    isKey:true}`, `productName {domain: md.ProductName}`, `classCode {domain: md.ClassCode}`,
    `brandCode {domain: md.BrandCode}`, `manufacturerCode {domain: md.ManufacturerCode}`,
    `categoryCode {domain: md.CategoryCode}`, plus display names; `hierarchies: [productDrill]`.
  - **`Customer`**, **`Store`**, **`DistributionCentre`**, **`Promotion`**, **`ReturnReason`**
    (`dimensions.ttrm`) — each with a `key` (code attribute) + the attributes the queries slice by
    (Customer: `customerCode`, `state` [for the regional branch], `ageBand`; Store: `storeCode`,
    `state`; DistributionCentre: `dcCode`, `dcName`; Promotion: `promoCode`; ReturnReason:
    `reasonCode`, mapped to the "Nedorazilo včas"/"Did not get it on time" member in 2.5).
  Every MD attribute carries `domain:` (never `type:`).

- [ ] **T3 — `def map` + `def hierarchy` per dimension.**
  - **Calendar (calc-backed):** `def map day_to_month {from: md.Day, to: md.Month, calc: monthOfDate}`,
    `day_to_week {calc: weekOfYear}`, `month_to_qtr {from: md.Month, to: md.Quarter, calc: quarterOfMonth}`,
    `qtr_to_year {...}` (use catalog names from `map-catalog.md`; a calc map is implicitly N:1).
    Hierarchy: `def hierarchy calendar { dimension: md.Calendar,
    levels: [day, month via md.day_to_month, quarter via md.month_to_qtr, year via md.qtr_to_year] }`.
    (Weeks can be a second hierarchy sharing the `day` leaf: `levels: [day, week via md.day_to_week]`,
    per `design.md:207`.)
  - **Product (table-backed):** maps with **no `calc:`** — `class_to_category`, `brand_to_class`?
    Model the real containment: `item → class → category` and the brand/manufacturer facets.
    Because the TPC-DS `item` row carries category/class/brand/manufacturer **denormalized on one
    row**, the levels roll up within the item table — declare the maps as table-backed
    (`cardinality: { from: "N", to: "1" }`) so 2.4's `md2db_map` supplies the case columns.
    Hierarchy (leaf→root, 5 levels): `def hierarchy productDrill { dimension: md.Product,
    levels: [itemCode, manufacturerCode via md.item_to_manuf, brandCode via md.manuf_to_brand,
    classCode via md.brand_to_class, categoryCode via md.class_to_category] }`.
    *(If the demo prefers the simpler Category→Class→…→Item chain without the brand/manufacturer
    intermediate maps being ambiguous, pin every step with `via` to avoid
    `md/ambiguous-hierarchy-step`.)*
  - **Store / DistributionCentre / Customer / Promotion / ReturnReason:** each gets any needed
    roll-up map (e.g. Store `store_to_state`) + a hierarchy where a drill exists; single-level dims
    need no hierarchy.

- [ ] **T4 — Dimensional attributes with domains (`attributes.ttrm` / inline).**
  Ensure every attribute referenced by a hierarchy level or a future grain (2.4) exists and carries
  a `domain:`. Add the query-driving attributes the roster implies: Product `productCode`/`week`
  granularity, Customer `state` + `ageBand` (buyer_age_profile #12, revenue_by_customer_state #11),
  DistributionCentre `dcName` (warehouse drill #4/#8). Confirm none carries `type:` (that's a db/er
  attribute form — `md/attr-type-in-md`).

- [ ] **T5 — Model-load: dot-path resolution smoke (write first; TDD-shaped).**
  Add an md-load test (integration harness, plan overview) that parses `model/md/*.ttrm` + the
  db/er below it and asserts, mocked/unit:
  1. **Parse-clean** — zero `errors` across `model/md/`.
  2. **Dot-path resolution** — representative drill/filter paths resolve to a real
     dimension→attribute chain: `product.category.<class>`-style
     (`product.electronics.<class>`), `calendar.2025.november` (year→month), and the leaf
     `product.<itemCode>`. Use the resolver the way `lexicon-lsp.test.ts` checks a `for:` target
     resolves. (Dot-path sugar semantics: `docs/features/md/dot-path-sugar.md`.)
  3. **Hierarchy well-formedness** — each `def hierarchy` has ≥1 inferred/`via`-pinned connecting
     map between consecutive levels; no `md/no-hierarchy-step`/`md/ambiguous-hierarchy-step`.

- [ ] **T6 — Unit tests: hierarchy ordering, map cardinality, domain typing.**
  Author against `@tatrman/lint`/semantics md rules (mirror `packages/lint/src/__tests__/
  md-hierarchy.test.ts`, `md-references.test.ts`). Assert:
  1. **Level ordering** — Calendar levels resolve leaf→root day→…→year; Product itemCode→…→category;
     a level not in the dimension raises `md/level-not-in-dim` (negative case).
  2. **Map cardinality** — every `def map` is N:1 or 1:1 (no M:N); a calc map has no explicit
     conflicting `1:1` (`md/calc-cardinality-conflict`); table-backed maps declare `cardinality`.
  3. **Domain typing** — every md attribute has `domain:` and no `type:`; calc domains are on
     discrete types only (`md/kind-on-scalar` negative for a `decimal` with `kind`).
  4. **Calc names valid** — every `calc:` reference is in the catalog (`md/unknown-calc-map`
     negative for a typo).
  Run: `pnpm --filter @tatrman/lint test -- md` and `pnpm --filter @tatrman/integration-tests test -- md`.

## DONE bar

`model/md/` declares the typed domains, the conformed dimensions (Calendar, **Product** with the
5-level Category→Class→Brand→Manufacturer→Item drill, Customer, Store, DistributionCentre,
Promotion, ReturnReason), their maps (Calendar **calc-backed**, the rest **table-backed**), and
hierarchies; **`model/md/*.ttrm` parses with zero errors**, dot-path drills resolve
(`product.<class>`, `calendar.2025.november`), every hierarchy has a connecting map, every md
attribute is `domain:`-typed, and the md-lint rules pass. Committed on `feat/p2-s3-md-dims`.

## Verify block

```sh
pnpm -r build
pnpm --filter @tatrman/lint test -- md                     # hierarchy/map/domain rules green
pnpm --filter @tatrman/integration-tests test -- md        # parse-clean + dot-path resolution
grep -RnE 'def dimension|def hierarchy|levels:' model/md    # eyeball: Product 5 levels, Calendar Y→..→D
```

*(md2db binding + measures + cubelets are Stage 2.4; a live drill against a DB is Phase 3.)*
