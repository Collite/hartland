# Stage 1.1 — Catalog taxonomy & bilingual generator

> **Phase 1, Stage 1.1.** Plan: [`../plan-demo-build.md`](../plan-demo-build.md) (§ Stage 1.1).
> Decisions: [`../08-czech-mirror-and-catalog-delta.md`](../08-czech-mirror-and-catalog-delta.md)
> — **BM-4** (full per-item bilingual catalog, deterministic on `i_item_sk`, keys/categories/price
> bands preserved) and **Q-BM-2b** (generator + hand-picked hero brands).
>
> **Goal:** a deterministic, reproducible generator that maps every `i_item_sk` → a believable
> bilingual product, from a curated taxonomy — the single source both worlds draw from. It emits
> idempotent SQL `UPDATE` scripts (`data/catalog/us.sql`, `data/catalog/cz.sql`) that patch the
> `item` dimension in place, per world.

## Where the code lives

```
data/catalog/
├── taxonomy.yaml            # T1 — curated 10-category tree, en+cs, hero brands
├── generate.py              # T2/T4/T5 — the deterministic generator (CLI)
├── us.sql                   # T5 output — idempotent UPDATE script, en
├── cz.sql                   # T5 output — idempotent UPDATE script, cs
├── pyproject.toml           # deps: pyyaml only (hashlib/csv are stdlib)
└── tests/
    ├── test_determinism.py  # T3/T6
    ├── test_invariants.py   # T3 — key/category/price-band preservation
    ├── test_bilingual.py    # T6 — no NULL en/cs coverage
    └── fixtures/item_sample.csv   # ~200-row i_item_sk sample export for mocked tests
```

The generator reads a **CSV export of the current `item` dimension** (produced once via `psql`, not a
live DB connection — keeps the generator unit-testable and hermetic) and writes SQL. Column names are
canonical TPC-DS: `i_item_sk` (PK, bigint), `i_item_id` (business key, char(16)), `i_product_name`,
`i_brand`, `i_brand_id`, `i_manufact`, `i_manufact_id`, `i_class`, `i_class_id`, `i_category`,
`i_category_id`, `i_size`, `i_container`, `i_current_price`, `i_rec_start_date`/`i_rec_end_date`
(SCD-2 validity — never touched).

## Pre-flight

- [ ] Stage 1.1 branch cut: `feat/p1-s1-1-catalog-generator`.
- [ ] `data/catalog/` scaffolded; `pyproject.toml` created; `uv sync` (or `python -m venv`) green with `pyyaml`.
- [ ] A `item` CSV export exists for tests. Produce the fixture sample once:
      `kubectl --context dsk -n data exec test-pg-1 -c postgres -- \`
      `psql -d tpc-ds-1g -c "\copy (SELECT i_item_sk,i_item_id,i_category,i_category_id,i_class,i_class_id,i_current_price FROM item WHERE i_item_sk IS NOT NULL ORDER BY i_item_sk LIMIT 200) TO STDOUT WITH CSV HEADER"` > `data/catalog/tests/fixtures/item_sample.csv`.
- [ ] Confirm live-row count (~18k after SCD dedupe) and the 10 clean categories: Books, Children,
      Electronics, Home, Jewelry, Men, Music, Shoes, Sports, Women (F-6). Rows with NULL `i_category` exist
      (SCD tail) — the generator must skip them (they carry no on-screen product).

---

## Tasks

- [ ] **T1 — Curate `taxonomy.yaml` (10 categories → classes → brands → manufacturers, en+cs, heroes).**
  Author `data/catalog/taxonomy.yaml`. Top level is the 10 fixed TPC-DS categories (keyed by the exact
  `i_category` string so category assignment is preserved). Under each: 4–8 **classes**, each with a set of
  **brands** and **manufacturers**, and a **product-line** noun set for name synthesis. Every named node
  carries `en` and `cs` strings (Czech diacritics correct — `Dětské`, `Šperky`, `Obuv`, `Elektronika`).
  Per Q-BM-2b, mark 1–3 **hero brands** per category (`hero: true`) — hand-picked, on-screen-credible
  (e.g. Electronics → a plausible "Voltaic"/"Kentaur" house brand; keep brands fictional to avoid trademarks).
  Shape:
  ```yaml
  categories:
    Electronics:
      cs: Elektronika
      classes:
        - key: "audio"          # maps to i_class
          en: "Audio"
          cs: "Audio"
          brands:
            - {en: "Voltaic", cs: "Voltaic", hero: true, manufact: {en: "Voltaic Corp", cs: "Voltaic s.r.o."}}
          product_lines: [{en: "Headphones", cs: "Sluchátka"}, {en: "Speaker", cs: "Reproduktor"}]
      containers: [{en: "Box", cs: "Krabice"}, {en: "Case", cs: "Pouzdro"}]
      sizes: [{en: "small", cs: "malé"}, {en: "medium", cs: "střední"}, {en: "large", cs: "velké"}]
  ```
  Edge cases: keep the class key set **stable** and ≥ the real distinct `i_class` cardinality per category (a
  loader/validation step in T2 asserts every real `(i_category,i_class)` pair has a taxonomy node — fail loud if
  a real class is unmapped). Do NOT invent categories outside the 10.

- [ ] **T2 — Per-item deterministic attribute rules (`generate.py` core).**
  Implement the hash-keyed mapping in `data/catalog/generate.py`. **No `random()`, no wall-clock** — every choice is
  `hashlib.sha256(f"{i_item_sk}:{salt}".encode()).digest()` reduced mod the candidate-list length. Salt per
  attribute-family (`"brand"`, `"line"`, `"container"`, `"size"`, `"name"`) so the choices are independent but
  reproducible. For each live row `(i_item_sk, i_category, i_class, i_current_price)`:
  - **class node** = taxonomy lookup on `(i_category, i_class)`; if the real `i_class` has no node, deterministically
    fold it into the nearest node by `hash(i_class) % len(classes)` (record folded classes in a report, don't drop).
  - **brand** = pick from the class's brands, hero-weighted (heroes get 2× candidate slots so they surface in top-N).
    Set `i_brand` (varchar) and derive a **stable** `i_brand_id` = `1000 + (hash(brand_name) % 9000)` (int).
  - **manufacturer** = the brand's `manufact`; `i_manufact` string + `i_manufact_id` = `100 + (hash(manufact)%900)`.
  - **product name** = `f"{brand} {product_line} {model_token}"` where `model_token` = a deterministic short code
    (e.g. `"MX-" + base36(hash(i_item_sk) % 46656)`), giving unique-ish `i_product_name` (≤ 50 chars, TPC-DS width).
  - **`i_size`** = pick from the category `sizes`; **`i_container`** from `containers`.
  - **`i_item_id`** stays the business key but is **left unchanged** by default (it is a stable join key downstream);
    only regenerate it behind a `--rewrite-item-id` flag (default off) if a demo needs EAN-style codes — document the risk.
  - `i_category`, `i_category_id`, `i_current_price`, `i_rec_start_date/end_date` are **read-only** (never in the SET list).
  Function signature: `def build_row(item_row: ItemRow, tax: Taxonomy, locale: str) -> CatalogPatch`. Keep `en`/`cs`
  selection index-identical (same hash → same node) so US and CZ mirror; only the rendered string differs by locale.

- [ ] **T3 — Invariants harness (write first — TDD).**
  Author `data/catalog/tests/test_invariants.py` **before** wiring the SQL emitter. Load
  `fixtures/item_sample.csv`, run `build_row` over every row for both locales, and assert:
  1. **Key preservation** — the set of `i_item_sk` produced == the set read (no drops, no adds); every SK appears once.
  2. **Category preservation** — no `CatalogPatch` alters `i_category`/`i_category_id`; the emitted patch's implied
     category (from the chosen taxonomy node's parent) equals the input `i_category` for every row.
  3. **Price-band preservation** — `i_current_price` is never in the patch; assert it's absent from the SET column set.
  4. **Class coverage** — every distinct `(i_category,i_class)` in the sample resolves to a taxonomy node (real or folded);
     folds are reported, not silent.
  These are the invariants the seeds and recon depend on (S1/S2 key on warehouse×week, item-agnostic — so the rewrite
  must be provably orthogonal). Tests are mocked/unit: they read the CSV fixture, never a DB.

- [ ] **T4 — Bilingual rendering (en table for US, cs for CZ; same key → mirror product).**
  Extend `generate.py` so a single pass over the item CSV produces **both** locale patch sets from the same hash choices
  (call `build_row(row, tax, "en")` and `build_row(row, tax, "cs")` — identical node indices, localized strings). Verify
  diacritics survive as UTF-8 (write SQL files with explicit `encoding="utf-8"`; the psql client must run with
  `client_encoding=UTF8`). Mirror property: for any `i_item_sk`, the cs product is the **same taxonomy node** as its en
  twin — only `i_product_name`/`i_brand`/`i_manufact`/`i_size`/`i_container` strings are the localized variants.

- [ ] **T5 — Emit idempotent SQL `UPDATE` scripts (`us.sql`, `cz.sql`).**
  Add the SQL emitter + CLI: `python generate.py --items item_export.csv --taxonomy taxonomy.yaml --out-us us.sql
  --out-cz cz.sql`. Each output file is a single transaction of **keyed** UPDATEs — one row per live `i_item_sk`:
  ```sql
  BEGIN;
  -- generated 2026-07-18 from taxonomy.yaml sha256=<hash>; DO NOT EDIT BY HAND
  UPDATE item SET i_product_name='Voltaic Sluchátka MX-3F', i_brand='Voltaic', i_brand_id=1042,
    i_manufact='Voltaic s.r.o.', i_manufact_id=317, i_class='audio', i_class_id=<preserved>,
    i_size='střední', i_container='Krabice'
    WHERE i_item_sk=142857;
  ...
  COMMIT;
  ```
  **Idempotent by construction** — the WHERE is on the PK and the SET is a full overwrite of the mutable columns, so a
  re-run converges to the same state (no INSERT, no accumulation). Prepend a header comment carrying the taxonomy sha256
  and generator version for provenance. Single UTF-8 file per world; escape single quotes (`''`) in names. Do **not**
  emit UPDATEs for NULL-category SCD-tail rows (they carry no product).

- [ ] **T6 — Unit tests: determinism, FK integrity, bilingual coverage.**
  Author `test_determinism.py` and `test_bilingual.py` (mocked/unit, CSV fixture):
  - **Determinism** — running `generate.py` twice on the same inputs yields **byte-identical** `us.sql` and `cz.sql`
    (`hashlib.sha256(open(f,'rb').read())` equal across runs). This is the reproducibility guarantee BM-4 needs.
  - **FK integrity** — every `i_brand_id`/`i_manufact_id`/`i_class_id` emitted is an integer; `i_class_id` equals the
    input (preserved); no emitted UPDATE references an `i_item_sk` absent from the input.
  - **Bilingual coverage** — for every row, en and cs `i_product_name`/`i_brand`/`i_manufact`/`i_size`/`i_container` are
    **non-empty and non-NULL** (no `''`, no `None`); assert a Czech-diacritic row round-trips through UTF-8 unchanged.
  - **Hero surfacing** — sort the sample by a mock revenue proxy and assert ≥1 hero brand appears in the top-20 per
    populated category (guards Stage 1.2 T4 / 1.4 T4 spot-checks).

## DONE bar

`python generate.py` produces `data/catalog/us.sql` and `data/catalog/cz.sql` from `taxonomy.yaml` + the item export;
all four test files pass (`pytest data/catalog/tests -q`); two consecutive runs are byte-identical; every live
`i_item_sk` is patched exactly once with non-NULL en **and** cs content; `i_item_sk`, `i_category`, and `i_current_price`
are provably untouched. The generator is committed; the two `.sql` artefacts are committed as generated output with the
taxonomy sha256 in their headers.

## Verify block

```sh
cd data/catalog
uv run pytest tests -q                                    # all invariant + determinism + bilingual tests green
uv run python generate.py --items tests/fixtures/item_sample.csv \
    --taxonomy taxonomy.yaml --out-us /tmp/us.sql --out-cz /tmp/cz.sql
uv run python generate.py --items tests/fixtures/item_sample.csv \
    --taxonomy taxonomy.yaml --out-us /tmp/us2.sql --out-cz /tmp/cz2.sql
diff /tmp/us.sql /tmp/us2.sql && diff /tmp/cz.sql /tmp/cz2.sql   # byte-identical (determinism)
grep -c '^UPDATE item' /tmp/us.sql                        # == live-row count of the sample
```

*(Applying `us.sql`/`cz.sql` against a real DB and re-checking recon is Stage 1.2 / 1.4 — an integration-flavoured step,
not a blocker here, per the conventions' testing policy.)*
