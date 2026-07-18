# Stage 2.1 — Repo scaffold confirm + `model db` (physical) + both connections

> **Phase 2, Stage 2.1.** Plan: [`../plan-demo-build.md`](../plan-demo-build.md) (§ Stage 2.1).
> Decisions: [`../08-czech-mirror-and-catalog-delta.md`](../08-czech-mirror-and-catalog-delta.md)
> — **BM-5** (explicit `model db` physical layer), **BM-2** (one model / two connections),
> **BM-9** (the hartland repo tree), **D-6a** (`net_profit`/cost excluded).
>
> **Goal:** the `model/` tree is confirmed (BM-9 — already scaffolded); the demo subset of the
> TPC-DS physical schema is modeled in `model/db/` (tables, columns, types, PK/FK), with **no
> profit/cost columns**; both connection descriptors (`pg-hartland-us` USD, `pg-hartland-cz` CZK)
> are declared as repo-level manifest input. The `db` model parses + resolves clean.

## Where the code lives

```
Collite/hartland/
├── modeler.toml               # T1 — project manifest (schemas, language, connections doc)
├── model/
│   ├── connections.toml        # T3 — the two connection descriptors (Ariadne/Arges input)
│   ├── db/
│   │   ├── facts.ttrm          # T2 — store/web/catalog sales + 3 returns + inventory
│   │   ├── dims.ttrm           # T2 — date, item, customer, customer_address, store,
│   │   │                       #        warehouse, promotion, reason, demographics/income
│   │   └── fks.ttrm            # T2 — def fk cross-table references
│   └── README.md               # (present) — points at plan + delta
```

All model files are `.ttrm`, ESM-free plain TTR-M. First line of each db file is
`model db schema dbo` (verified: `tests/conformance/fixtures/02-table.ttrm`).

## Library / syntax references (verified — do not guess)

- **Physical table + inline columns + PK:** `mnt/tatrman/tests/conformance/fixtures/02-table.ttrm`:
  ```ttrm
  model db schema dbo
  def table customers {
      description: "Customer master"
      primaryKey: ["id"]
      columns: [
          def column id { type: int, isKey: true },
          def column total { type: { type: decimal, length: 19, precision: 5 } },
          def column name { type: text, indexed: true, optional: true }
      ]
  }
  ```
- **Column detail / search:** `04-column.ttrm`; **index:** `05-index.ttrm`
  (`def index ix_name { type: btree, columns: ["name","code"] }`); **constraint:**
  `06-constraint.ttrm` (`def constraint uq_code { type: unique, columns: ["code"] }`).
- **Foreign key (cross-table):** `07-fk.ttrm`:
  `def fk fk_orders_customer { from: [db.dbo.orders.customer_id], to: [db.dbo.customers.id] }`.
- **Manifest schema (`modeler.toml`):** `mnt/tatrman/docs/features/v1/design/architecture.md §5`
  (`[project]`, `[language] preferred`, `[schemas] declared/namespaces`, `[stock] load`).
- **Parser API for the smoke test:** `parseString`/`parseFile` → `{ ast, errors, source }`
  (`packages/parser/src/walker.ts`); `parseDirectory(root)` (`packages/parser/src/index.ts`).

## Pre-flight

- [ ] Stage 2.1 branch cut: `feat/p2-s1-repo-db`.
- [ ] Phase 1 Stages 1.1–1.2 done — a catalog-rich `hartland_us` on `test-pg-1` to introspect for
      the physical column inventory.
- [ ] The BM-9 tree exists (confirmed present 2026-07-18). Add the one missing folder:
      `model/binding/` (empty for now; er2db lands in 2.2, md2db in 2.4).
- [ ] `pnpm -r build` green in the tatrman workspace so `parseDirectory`/the LSP can be run against
      `model/` for the smoke test.
- [ ] Extract the authoritative physical column list once (hermetic, for the tests):
      `kubectl --context dsk -n data exec test-pg-1 -c postgres -- psql -d hartland_us -c "\d+ <table>"`
      for each demo table; save to `model/db/.schema-ref/` (gitignored) as the reference the T6
      completeness test diffs against.

---

## Tasks

- [ ] **T1 — Confirm the `model/` tree + author `modeler.toml`.**
  Verify the BM-9 subtree (`model/{db,er,md,lexicon,queries}`, `agents/golem/shems/…`, `data/`,
  `run-set/`, `design/`) is present; create `model/binding/`. Author the repo-root `modeler.toml`
  (schema per `architecture.md §5`):
  ```toml
  [project]
  name = "hartland"
  version = "0.1.0"
  [language]
  preferred = "en"                 # default hover/display locale; cs is the second lexicon
  [schemas]
  declared   = ["db", "er", "md", "binding", "lexicon"]
  namespaces = { db = "dbo", er = "entity", binding = "er2db" }
  [stock]
  load = ["cnc-roles"]             # pre-load the fact/dimension/… vocab (semantics does this)
  ```
  The `agents/` side mirrors ai-models (Q-10, build-time concretization) — note it here; the Shem
  files themselves land in Stage 2.6. Edit-in-`project/` note: this repo is the source-of-truth
  home for the model per BM-9 (unlike kantheon's `project/`-split docs).

- [ ] **T2 — Author `model db` — the demo TPC-DS subset (tables, columns, types, PK).**
  Write `model/db/facts.ttrm` and `model/db/dims.ttrm`, each opening `model db schema dbo`. Model
  the demo subset (D-5 physical backing):
  - **Facts:** `store_sales`, `web_sales`, `catalog_sales`, `store_returns`, `web_returns`,
    `catalog_returns`, `inventory`. Include only the columns the model needs: the keys
    (`*_item_sk`, `*_customer_sk`, `*_store_sk`/`*_warehouse_sk`, `*_promo_sk`, `*_sold_date_sk`,
    `*_reason_sk`), the **revenue/qty/returns measures** (`ss_ext_sales_price`,
    `ss_quantity`, `ss_ticket_number`; `cs_ext_sales_price`, `cs_quantity`, `cs_order_number`;
    `sr_return_amt`, `sr_return_quantity`, `sr_reason_sk`; `inv_quantity_on_hand`,
    `inv_date_sk`, `inv_warehouse_sk`, `inv_item_sk` …). **Do NOT model** `*_net_profit`,
    `*_net_paid`, `*_wholesale_cost`, `*_list_price`, discount internals (T4 / D-6a).
  - **Dims:** `date_dim`, `item`, `customer`, `customer_address`, `store`, `warehouse`,
    `promotion`, `reason`, `customer_demographics`, `household_demographics`, `income_band`,
    `call_center` (light — labeling only). Model the columns the er/md layers reference plus each
    PK (`d_date_sk`, `i_item_sk`, `c_customer_sk`, `ca_address_sk`, `s_store_sk`, `w_warehouse_sk`,
    `p_promo_sk`, `r_reason_sk`, …) and the display columns the catalog lit up (`i_product_name`,
    `i_brand`, `i_class`, `i_category`, `i_manufact`, `i_size`, `i_container`).
  Use `primaryKey: [...]` + `isKey: true` per `02-table.ttrm`. Types: `int`/`bigint` for `*_sk`,
  `{ type: decimal, length: 7, precision: 2 }` for money columns, `text`/`varchar` for names.
  Money columns stay currency-**agnostic** at the db layer (the value is USD in `hartland_us`,
  CZK in `hartland_cz` — Phase 1 FX-scaled; the schema/type is identical). Keep the tables
  faithful to the physical `\d+` reference from pre-flight.

- [ ] **T3 — Declare the two connections (`model/connections.toml`).**
  **Verified constraint:** TTR-M has **no `connection` def** and no per-connection currency unit;
  connections are an Ariadne/Arges deploy concern (Phase 3 H3). Declare them here as a repo-level
  descriptor so the model is self-documenting and Phase 3 has one source:
  ```toml
  # model/connections.toml — consumed by Ariadne/Arges at deploy (Phase 3); NOT a TTR-M construct
  [[connection]]
  id       = "pg-hartland-us"
  database = "hartland_us"
  dialect  = "postgres"
  schema   = "dbo"                 # maps to the db-model namespace
  currency = "USD"                 # display fact — surfaces via lexicon locale en (Stage 2.5)
  locale   = "en"
  [[connection]]
  id       = "pg-hartland-cz"
  database = "hartland_cz"
  dialect  = "postgres"
  schema   = "dbo"
  currency = "CZK"                 # display fact — surfaces via lexicon locale cs (Stage 2.5)
  locale   = "cs"
  ```
  Both point at the **same** physical model (BM-2 — one model, two schema-identical DBs). Document
  in `model/README.md` that "loads against both connections" = the one model resolves clean and
  both descriptors target the identical schema; the live per-world round-trip is Phase 3.

- [ ] **T4 — Exclude `net_profit`/cost at the db layer (D-6a), documented.**
  Confirm no fact table in `facts.ttrm` carries a profit/cost/list/wholesale/discount-internal
  column. Add a comment block at the top of `facts.ttrm` enumerating the **deliberately-omitted**
  physical columns per fact (`ss_net_profit`, `ss_wholesale_cost`, `ss_list_price`,
  `ss_ext_discount_amt`, … and the `cs_`/`ws_`/`sr_`/`cr_`/`wr_` equivalents) with the reason:
  *"F-8 makes these nonsense-generators; margin questions gap gracefully — see D-6a."* The physical
  DB columns are untouched (the model simply never surfaces them). This is the layer where the
  exclusion is enforced structurally — er/md then cannot bind what db does not declare.

- [ ] **T5 — Author `model/db/fks.ttrm` — cross-table foreign keys.**
  Write `def fk` entries wiring every fact → dim (`from: [db.dbo.store_sales.ss_item_sk],
  to: [db.dbo.item.i_item_sk]`, etc.) and the demographics/address chains, patterned on
  `07-fk.ttrm`. These are what the `er2db` relation bindings (Stage 2.2 T-relation) reference via
  `binding: { fk: db.dbo.fk_… }` (fixture `26-relation-fk-mapping.ttrm`). Every `from`/`to`
  column must already exist in T2 — a dangling column ref is caught by resolution (T6).

- [ ] **T6 — Model-load / resolution unit tests (write first for the smoke; TDD-shaped).**
  Add a small unit suite (author under the hartland repo, run with the tatrman toolchain — or add
  a fixture case to `@tatrman/integration-tests` per the canonical harness, plan overview). Assert,
  **mocked/unit** (parse from strings / read the committed `.ttrm`, no live DB):
  1. **Parse-clean** — `parseDirectory("model/db")` (or `parseFile` per file) returns `errors: []`
     for every db file (`{ ast, errors }` shape, `walker.ts`).
  2. **Schema completeness** — the set of `def table` names + their `def column`s ⊇ the demo-subset
     reference list from pre-flight (diff against `model/db/.schema-ref/`); fail loud on a missing
     table/column.
  3. **PK/FK resolution** — every `def fk` `from`/`to` column resolves to a real
     `db.dbo.<table>.<column>` (no unresolved reference); every table has a `primaryKey`.
  4. **No profit/cost reachable** — assert none of the omitted-column names (T4 list) appears as a
     `def column` anywhere in `model/db/` (guards D-6a at its root).
  Run: `pnpm --filter @tatrman/integration-tests test -- db` (or the hartland-side script).

## DONE bar

`model/db/` models the full demo TPC-DS subset (7 facts + 12 dims) with types, PK, and cross-table
FKs; **`parseDirectory("model/db")` returns zero errors** and every FK column resolves; the
completeness test passes against the physical reference; **no profit/cost column is declared**
anywhere in the db layer (T4/T6-4); both connection descriptors are committed in
`model/connections.toml`; `modeler.toml` declares the five schemas. Everything committed on
`feat/p2-s1-repo-db`.

## Verify block

```sh
# in the tatrman workspace, pointed at the hartland model/ dir (or via the integration harness)
pnpm -r build
pnpm --filter @tatrman/integration-tests test -- db          # parse-clean + completeness + no-profit
# ad-hoc parse smoke (node REPL / a tiny script using @tatrman/parser):
#   const { parseDirectory } = await import('@tatrman/parser');
#   const rs = await parseDirectory('model/db');  rs.every(r => r.errors.length === 0)  // true
grep -RniE 'net_profit|wholesale_cost|list_price|net_paid|discount_amt' model/db   # → no matches (D-6a)
```

*(Resolving the model against a **live** `hartland_us`/`hartland_cz` is Phase 3 H3 — an
integration step, not a blocker here, per the conventions' testing policy.)*
