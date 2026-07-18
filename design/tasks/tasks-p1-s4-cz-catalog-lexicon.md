# Stage 1.4 — CZ catalog & cs value-labels (`hartland_cz`)

> **Phase 1, Stage 1.4.** Plan: [`../plan-demo-build.md`](../plan-demo-build.md) (§ Stage 1.4).
> Decisions: [`../08-czech-mirror-and-catalog-delta.md`](../08-czech-mirror-and-catalog-delta.md)
> — **BM-4** (per-item bilingual catalog; same `i_item_sk` → mirror product), **BM-3** (Czech content).
>
> **Goal:** the Czech per-item catalog, mirroring the US keys with localized content, plus the
> `valueLabels` seed data (cs+en) the Phase-2 lexicon consumes. The catalog SQL was already
> generated in Stage 1.1 (`data/catalog/cz.sql`); this stage applies it and proves the mirror.

## Depends on

- **Stage 1.1 DONE** — `data/catalog/cz.sql` generated (same generator run as `us.sql`, so choices mirror), tests green.
- **Stage 1.3 DONE** — `hartland_cz` exists, localized (geography + CZK + reasons), redated. Catalog apply comes after
  localization so the item dimension is present and stable.

## Pre-flight

- [ ] Stage 1.4 branch: `feat/p1-s4-cz-catalog-lexicon`.
- [ ] `data/catalog/cz.sql` was generated from the **same item population** as `hartland_cz` (the pristine item SKs ==
      the US item SKs — TPC-DS `item` is identical pre-localization, so one generator run covers both worlds). Confirm
      `SELECT count(*) FROM item` on `hartland_cz` matches the row count the generator emitted.
- [ ] `client_encoding=UTF8` on the psql client (Czech diacritics in product names).

## Tasks

- [ ] **T1 — Apply `data/catalog/cz.sql` to `hartland_cz`.**
  `kubectl --context dsk -n data exec -i test-pg-1 -c postgres -- psql -v ON_ERROR_STOP=1 -d hartland_cz < data/catalog/cz.sql`.
  One transaction; one UPDATE per live `i_item_sk`; expected row count == live item count (~18k), zero errors. Idempotent
  (PK-keyed overwrite) — a re-run converges. Edge case: verify no mojibake — spot-check
  `SELECT i_product_name FROM item WHERE i_product_name ~ '[ěščřžýáíé]' LIMIT 5;` returns clean Czech, not `Ä›`.

- [ ] **T2 — Verify mirror integrity: same `i_item_sk` → same taxonomy node, localized strings.**
  Cross-DB check that every `i_item_sk` present in both worlds maps to the **same taxonomy node** (same class/brand/
  manufacturer *choice*, localized text). Export both and compare on the node identity the generator recorded. Practical
  approach: have the Stage-1.1 generator also emit a `data/catalog/mirror-map.csv` (`i_item_sk, class_key, brand_key,
  container_key, size_key` — locale-independent node keys). Then assert:
  ```sh
  # us item labels reverse-map to the same node keys as cz item labels
  psql -d hartland_us -c "\copy (SELECT i_item_sk,i_brand,i_class FROM item WHERE i_category IS NOT NULL) TO STDOUT CSV" > /tmp/us_items.csv
  psql -d hartland_cz -c "\copy (SELECT i_item_sk,i_brand,i_class FROM item WHERE i_category IS NOT NULL) TO STDOUT CSV" > /tmp/cz_items.csv
  ```
  and a small pytest joins both on `i_item_sk` + `mirror-map.csv` and asserts identical node keys and identical
  `i_category`/`i_class_id`. This is the BM-4 mirror guarantee (en/cs differ only in rendered strings, never in structure).

- [ ] **T3 — Produce the `valueLabels` seed data (cs+en) for coded dimensions.**
  Author `data/catalog/value-labels.json` (or `.yaml`) — the bilingual label table the Phase-2 `model lexicon`
  (`valueLabels`, contract §7 `{cs:…, en:…}`) consumes. Cover every coded dimension that renders on screen:
  - **Categories** — the 10, en + cs (Books→Knihy, Children→Dětské, Electronics→Elektronika, Home→Domácnost,
    Jewelry→Šperky, Men→Pánské, Music→Hudba, Shoes→Obuv, Sports→Sport, Women→Dámské).
  - **Return reasons** — every `r_reason_sk` used, en + cs, **including "Did not get it on time" → "Nedorazilo včas"**
    (the S3 skew target — must be present).
  - **DC names** — Memphis DC↔Brno DC, Columbus↔Praha, Dallas↔Ostrava, Reno↔Plzeň, Allentown↔Hradec Králové
    (keyed on `w_warehouse_sk` so the labels attach to the same physical warehouse in each world).
  - **Container / size codes** — every `i_container` and `i_size` value the generator emits, en + cs.
  Shape: `{"category": [{"key":"Electronics","en":"Electronics","cs":"Elektronika"}, …], "reason":[…], "dc":[…], …}`.
  Source the cs strings from `taxonomy.yaml` (containers/sizes) and `data/localize-cz/03-reasons.sql` (reasons) so there
  is one authority per string. This file is the hand-off to Phase 2 Stage 2.5 T3.

- [ ] **T4 — Spot-verify CZ hero products in the drill queries.**
  Run query #3 `category_revenue` and #5 `top_items_by_revenue` against `hartland_cz` for 2025; confirm the labels read as
  real Czech products (e.g. "Voltaic Sluchátka MX-3F") and ≥1 hero brand per populated category appears in the top-N —
  the CZ mirror of Stage 1.2 T4. Revenue values are now CZK (×FX) but the **ordering** is identical to US (scale is
  uniform) — a quick cross-check that the top-20 `i_item_sk` set matches US confirms both the catalog mirror and the CZK
  scale-invariance.

- [ ] **T5 — Commit the CZ catalog-integrity report.**
  Run `data/catalog/integrity_check.sql` (from Stage 1.2 T6, parameterizable by DB) against `hartland_cz`: NULL scan
  (no NULL cs name/brand/manufact/size/container on live rows), key coverage, item↔fact FK integrity, category invariant.
  Commit the output to `data/recon/results/cz-catalog-integrity.txt`. All checks return zero problem rows.

- [ ] **T6 — Bilingual coverage lint (verification).**
  Author `data/catalog/coverage_lint.py` (mocked/unit against the exported item CSVs + `value-labels.json`) that asserts
  **no on-screen dimension member is untranslated**:
  - every distinct `i_category`, `i_container`, `i_size`, DC name, and used `r_reason_sk` in `hartland_cz` has a matching
    entry in `value-labels.json` with a **non-empty cs string**;
  - symmetrically every entry has a non-empty en string (for the US world / language-agnostic assertions);
  - no cs string is accidentally equal to its en string for a term that must differ (e.g. category names must differ;
    proper-brand tokens may legitimately coincide — allowlist those).
  Fails loud on any gap. This lint is the gate Phase-2 Stage 2.5 T6 (bilingual value-label coverage) inherits.

## DONE bar

`hartland_cz` carries the Czech per-item catalog; every `i_item_sk` maps to the **same taxonomy node** as its US twin
(mirror proven, strings localized, diacritics clean); `data/catalog/value-labels.json` covers every coded dimension
(cs + en, "Nedorazilo včas" present); hero brands surface in queries #3/#5; the integrity report and the bilingual
coverage lint are green. The `value-labels.json` hand-off to Phase 2 Stage 2.5 is committed.

## Verify block

```sh
kubectl --context dsk -n data exec -i test-pg-1 -c postgres -- psql -v ON_ERROR_STOP=1 -d hartland_cz < data/catalog/cz.sql
uv run pytest data/catalog/tests/test_mirror.py -q            # T2 mirror-node equality
kubectl --context dsk -n data exec -i test-pg-1 -c postgres -- psql -d hartland_cz < data/catalog/integrity_check.sql
uv run python data/catalog/coverage_lint.py --items-cz /tmp/cz_items.csv --labels data/catalog/value-labels.json
```
