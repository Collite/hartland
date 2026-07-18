# Stage 2.2 — `model er` (logical) + `er2db` binding

> **Phase 2, Stage 2.2.** Plan: [`../plan-demo-build.md`](../plan-demo-build.md) (§ Stage 2.2).
> Decisions: [`../08-czech-mirror-and-catalog-delta.md`](../08-czech-mirror-and-catalog-delta.md)
> — **BM-5** (19-entity er layer + er2db), **D-5** (the entity roster), **D-6/D-6a** (synonym/
> measure families; no profit measure), **D-4** (`AreaDef hartland`).
> Roster + synonyms authority: `project/kantheon/design/demo-tpcds/05-d-ttrm-spec.md` (D-5, D-6).
>
> **Goal:** the 19 curated entities and their relationships, mapped to the physical schema via
> `er2db`, with the channel/measure **structure** recorded (the lexical layer is Stage 2.5).
> `ResolveArea("hartland")` and every er2db binding resolve green; no profit measure is reachable.

## Where the code lives

```
model/
├── er/
│   ├── sales.ttrm        # T1 — store_sales, web_sales, catalog_sales (channel entities)
│   ├── returns.ttrm      # T1 — store/web/catalog_returns, reason
│   ├── inventory.ttrm    # T1 — inventory, warehouse
│   ├── parties.ttrm      # T1 — customer, customer_address, demographics, income_band, store
│   ├── catalog.ttrm      # T1 — item (Products), promotion, call_center
│   └── relations.ttrm    # T3 — def relation (fact→dim, address/demographics chains)
├── binding/
│   └── er2db.ttrm        # T2 — er2db_entity + er2db_attribute for every entity/attribute
└── er/area.ttrm          # T5 — def area hartland
```

er files open `model er` (fixture `09-entity.ttrm`); binding files open `model binding`
(`12-er2db_entity.ttrm`). `def area` lives in a package-scoped file (`56-area.ttrm`).

## Library / syntax references (verified — do not guess)

- **Entity (roles, bilingual label, inline attributes):**
  `mnt/tatrman/tests/conformance/fixtures/09-entity.ttrm`:
  ```ttrm
  model er
  def entity Customer {
      description: "A customer"
      labelPlural: "Customers"
      nameAttribute: name
      codeAttribute: code
      aliases: ["client", "buyer"]
      roles: [fact, dimension]
      displayLabel: { cs: "Zákazník", en: "Customer" }
      attributes: [
          def attribute id { type: int, isKey: true },
          def attribute name { type: text, search { searchable: true } }
      ]
  }
  ```
- **Relation (cardinality + join, or FK binding):** `11-relation.ttrm`
  (`def relation customer_orders { from: er.Customer, to: er.Order, cardinality:{from:"1",to:"0..*"}, join:[{from: er.Customer.id, to: er.Order.customer_id}] }`)
  and `26-relation-fk-mapping.ttrm` (`binding: { fk: db.dbo.fk_a_b }`).
- **er2db binding:** `12-er2db_entity.ttrm` (`def er2db_entity customer_map { entity: er.Customer,
  target: { table: db.dbo.customers }, whereFilter: { active: 1 } }`) and `13-er2db_attribute.ttrm`
  (`def er2db_attribute name_map { attribute: er.Customer.name, target: { column: db.dbo.customers.name } }`).
- **cnc roles are pre-loaded** — `roles: [fact, dimension]` reference the stock vocab
  (`fact/dimension/structural/master/transaction/bridge`, loaded by `@tatrman/semantics`). Do NOT
  author a cnc model. (er2cnc role mapping is optional; fixture `17-er2cnc_role.ttrm` shows the
  form if a role assignment needs to be explicit.)
- **Area:** `56-area.ttrm`; resolver: `resolveArea(symbols, resolver, entry, root)` →
  `ResolvedArea { resolvedPackages, resolvedEntities }` (`packages/semantics/src/area-table.ts`).

## Pre-flight

- [ ] Stage 2.1 closed (db layer parses clean; FKs resolve); branch `feat/p2-s2-er`.
- [ ] The D-5 roster (19 in) in hand — reproduce it in a comment header of `er/README` so the
      executor checks 19 entities exist: store_sales, web_sales, catalog_sales, store_returns,
      web_returns, catalog_returns, inventory, date_dim, item, customer, customer_address,
      customer_demographics, household_demographics, income_band, store, warehouse, reason,
      promotion, call_center.
- [ ] The D-5 **Out** list recorded (time_dim, web_site/web_page/catalog_page, ship_mode,
      dbgen_version) so no stray entity is authored.

---

## Tasks

- [ ] **T1 — Author the 19 `model er` entities (D-5), with roles + attributes + display labels.**
  Across the `er/*.ttrm` files, one `def entity` per D-5 row. For each: `description`,
  `labelPlural`, `nameAttribute`/`codeAttribute` where one exists, `roles:` from the stock cnc
  vocab (`store_sales/web_sales/catalog_sales/*_returns/inventory` → `[fact]`; the dims →
  `[dimension]`; `customer` → `[master, dimension]`; `item` → `[dimension]`), inline `attributes:`
  covering the keys + display columns modeled in db (T2 of 2.1). Add a **placeholder**
  `displayLabel: { en: "…", cs: "…" }` per entity (the *authoritative* bilingual naming is the
  lexicon in 2.5, but the fixture pattern carries labels inline — keep them minimal here and let
  2.5 own synonyms/forms). Example (channel entity):
  ```ttrm
  model er
  def entity catalog_sales {
      description: "Marketplace (third-party / fulfilled-by-Hartland) sales lines"
      labelPlural: "Marketplace Orders"
      roles: [fact]
      displayLabel: { en: "Marketplace Orders", cs: "Objednávky z tržiště" }
      attributes: [
          def attribute item { type: int, isKey: true },
          def attribute order_number { type: int },
          def attribute ext_sales_price { type: { type: decimal, length: 7, precision: 2 } },
          def attribute quantity { type: int }
      ]
  }
  ```
  **Do NOT** add a `net_profit`/`cost` attribute anywhere (D-6a — those db columns don't exist to
  bind, and no er attribute may invent them). `call_center` is light (labeling only — a couple of
  attributes).

- [ ] **T2 — `er2db` binding for every entity + attribute.**
  Author `model/binding/er2db.ttrm` (`model binding`). One `def er2db_entity` per entity mapping
  `entity: er.<E>` → `target: { table: db.dbo.<t> }`; one `def er2db_attribute` per attribute →
  `target: { column: db.dbo.<t>.<c> }` (fixtures 12/13). Where an entity needs the catalog-dedupe
  filter, use `whereFilter` (e.g. items: current SCD row). **Completeness rule:** every er
  attribute authored in T1 has a matching `er2db_attribute` (the T6 test enforces this) — an
  unbound attribute is a gap, not allowed. Because db declares no profit column, no er2db can bind
  one — the exclusion is structurally sealed.

- [ ] **T3 — Relationships (`er/relations.ttrm`) fact→dim + address/demographics chains.**
  Author `def relation`s for every fact→dim edge (`catalog_sales`→`item`, →`customer`,
  →`warehouse` via `catalog_sales.cs_warehouse_sk`, →`date_dim`, →`promotion`;
  `catalog_returns`→`reason`; `inventory`→`warehouse`/`item`/`date_dim`; the address/demographics
  chains `customer`→`customer_address`, `customer`→`customer_demographics`/`household_demographics`,
  `household_demographics`→`income_band`). Use `cardinality` + either an explicit `join:` (fixture
  11) or a `binding: { fk: db.dbo.fk_… }` referencing the Stage 2.1 T5 FKs (fixture 26). Facts are
  the "many" side (`from: "0..*"`), dims the "one" side.

- [ ] **T4 — Record the channel + synonym/measure *structure* (D-6).**
  This stage carries the **structural** half of D-6 (the *lexical* half — forms/synonyms — is
  Stage 2.5). Encode the channel mapping structurally so the model knows the three channels are
  peers: `catalog_* ⇒ Marketplace`, `web_* ⇒ Web`, `store_* ⇒ Stores` — realized as the three
  channel entities' `labelPlural`/`displayLabel` + `aliases: [...]` (e.g. catalog_sales aliases
  `["marketplace", "3P", "third-party", "fulfilled by Hartland"]`). Record the measure families as
  er attributes only: revenue → `ext_sales_price` (each sales entity), quantity, order/line counts
  (`*_order_number`/`*_ticket_number`), return amount (`*_return_amt`), on-hand qty
  (`inv_quantity_on_hand`). **No profit/margin family** (D-6a) — assert absent in T6.

- [ ] **T5 — `def area hartland` (D-4).**
  Author `model/er/area.ttrm` with a `package` declaration and `def area hartland` (fixture 56):
  ```ttrm
  package hartland
  def area hartland {
    description: "Sales, returns, inventory and customer analytics for Hartland Stores — store, web and marketplace channels.",
    tags: ["reporting", "demo"],
    packages: [hartland],
    entities: [hartland.er.entity.store_sales, hartland.er.entity.web_sales, hartland.er.entity.catalog_sales]
  }
  ```
  (List the headline entities explicitly; `packages: [hartland]` pulls the rest via the package
  closure.) The router description is the D-4 wording; the final Shem wording is applied in 2.6.

- [ ] **T6 — Unit tests: entity/relationship resolution, er2db completeness, measures policy.**
  Mocked/unit (parse from the committed files; use `@tatrman/semantics` + the integration harness,
  plan overview). Assert:
  1. **Parse-clean** — every `er/*.ttrm` + `binding/er2db.ttrm` parses with `errors: []`.
  2. **19 entities present** — the `def entity` count == 19, names == the D-5 roster; no D-5-Out
     entity present.
  3. **Relationship resolution** — every `def relation` `from`/`to`/`join` ref resolves to a real
     `er.<E>` / `er.<E>.<a>`; every `binding.fk` resolves to a `db.dbo.fk_…`.
  4. **er2db completeness** — every `def attribute` has a matching `er2db_attribute`; every
     `def entity` has an `er2db_entity` (no unbound entity/attribute).
  5. **`ResolveArea("hartland")` green** — build the area table (`AreaTableBuilder`), resolve, and
     assert `resolvedEntities` is non-empty, contains the three channel facts, and produces **zero
     unresolved references** across the closure.
  6. **Measures policy** — no attribute named `net_profit`/`net_paid`/`wholesale_cost`/`list_price`
     (or any cost/margin token) exists in `model/er/`; a "profitability" probe has no target.
  Run: `pnpm --filter @tatrman/integration-tests test -- er`.

## DONE bar

`model/er/` declares exactly the 19 D-5 entities (roles, attributes, bilingual placeholder labels,
channel aliases) with relationships; `model/binding/er2db.ttrm` binds every entity **and** every
attribute to db; **all er + er2db files parse with zero errors**, every relation/join/fk reference
resolves, and **`ResolveArea("hartland")` is green** with an empty unresolved-reference set; **no
profit/margin measure is reachable** through er (D-6a). Committed on `feat/p2-s2-er`.

## Verify block

```sh
pnpm -r build
pnpm --filter @tatrman/integration-tests test -- er     # parse + resolve + area + er2db completeness + no-profit
grep -RniE 'net_profit|wholesale_cost|list_price|margin|net_paid' model/er model/binding   # → no matches
# ad-hoc ResolveArea smoke (semantics): AreaTableBuilder over parsed model/, resolveArea('hartland') → resolvedEntities.length > 0, unresolved == 0
```

*(Live resolution against `hartland_us`/`hartland_cz` is Phase 3 H3 — not a stage blocker.)*
