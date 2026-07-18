# Stage 1.2 — US catalog application (`hartland_us`)

> **Phase 1, Stage 1.2.** Plan: [`../plan-demo-build.md`](../plan-demo-build.md) (§ Stage 1.2).
> Decisions: [`../08-czech-mirror-and-catalog-delta.md`](../08-czech-mirror-and-catalog-delta.md)
> — **BM-4** (catalog is orthogonal to the seeded story: keys/categories/price bands preserved) and
> **BM-1** (the existing US world becomes `hartland_us`).
>
> **Goal:** the existing US world gains the meaningful catalog **without disturbing the seeded
> story**. The proof obligation is that the Memphis-DC-meltdown recon numbers are byte-for-byte the
> same before and after the catalog rewrite (S1/S2 seeds key on warehouse×week, item-agnostic).

## Depends on

- **Stage 1.1 DONE** — `data/catalog/us.sql` generated, committed, tests green.
- The existing re-dated (+23y) + Memphis-seeded US `hartland` DB standing on `test-pg-1` (bp-dsk `data` ns).
- The committed 2026-07-09 US recon baseline (`data/recon/results/`) — the reference for the "story unchanged" diff.

## Pre-flight

- [ ] Stage 1.2 branch: `feat/p1-s2-us-catalog`.
- [ ] `us.sql` regenerated against the **live** `hartland` item export (not just the test fixture) — re-run the
      Stage 1.1 generator with a full export:
      `psql -d hartland -c "\copy (SELECT i_item_sk,i_item_id,i_category,i_category_id,i_class,i_class_id,i_current_price FROM item) TO STDOUT WITH CSV HEADER"` > `/tmp/item_us.csv`;
      `python data/catalog/generate.py --items /tmp/item_us.csv --taxonomy data/catalog/taxonomy.yaml --out-us data/catalog/us.sql --out-cz data/catalog/cz.sql`.
- [ ] `psql` reachable via `kubectl --context dsk -n data exec test-pg-1 -c postgres --`; `client_encoding=UTF8`.

## Tasks

- [ ] **T1 — Confirm/rename to `hartland_us`; snapshot a pre-catalog rollback dump.**
  Adopt the existing `hartland` DB as `hartland_us`. Prefer a rename so downstream connection strings are explicit:
  `ALTER DATABASE hartland RENAME TO hartland_us;` (must be run with no active sessions on it — terminate first via
  `pg_terminate_backend`). If a rename is risky mid-flight, create an alias role/connection instead and record the
  decision. **Before applying the catalog**, take the DR snapshot (Stage 1.6 T5 retains it):
  `pg_dump -Fc -Z6 -d hartland_us > hartland_us-precatalog-$(date +%Y%m%d).dump`. Push to
  `tpcds-staging/hartland/us/` with a `-precatalog` suffix. This is the rollback point for T2.

- [ ] **T2 — Apply `data/catalog/us.sql` to `hartland_us`.**
  `kubectl --context dsk -n data exec -i test-pg-1 -c postgres -- psql -v ON_ERROR_STOP=1 -d hartland_us < data/catalog/us.sql`.
  Runs in one transaction (the generator wraps `BEGIN;…COMMIT;`). Expected: one UPDATE per live `i_item_sk`, row count ==
  live item count (~18k), zero errors. Edge cases: if `ON_ERROR_STOP` trips on a quoting issue, fix the generator's
  escaping (Stage 1.1 T5) and regenerate — never hand-edit `us.sql`. Re-running the script is safe (idempotent PK-keyed
  overwrite); verify the second run reports the same UPDATE count and leaves the DB byte-identical.

- [ ] **T3 — Re-run recon variants; confirm the story numbers are UNCHANGED.**
  Run the seed-sensitive recon slice against `hartland_us`:
  `data/recon/run-recon.sh dsk hartland_us` (or the individual variants **r01** channel-year, **r02** channel-month,
  **r05** category×channel×year, **r08a/r08b** stockout incidence, **r13** warehouse Marketplace share). Diff each output
  CSV against the committed pre-catalog baseline:
  ```sh
  for r in r01 r02 r05 r08a r08b r13; do
    diff <(sort data/recon/results/${r}.csv) <(sort data/recon/results-precatalog/${r}.csv) && echo "$r UNCHANGED";
  done
  ```
  **Acceptance:** r01/r02/r08/r13 are byte-identical (catalog touches no fact rows, no warehouse, no dates). r05
  (category×channel) must also be identical because category assignment is a preserved invariant (Stage 1.1 T3) — if r05
  drifts, the generator changed a category and the run is a bug: stop and fix Stage 1.1, do not proceed. This is the
  central proof of BM-4's orthogonality claim.

- [ ] **T4 — Spot-verify hero products/brands surface in the drill queries.**
  Run query #3 `category_revenue` and #5 `top_items_by_revenue` (05-d D-2 list) against `hartland_us` for 2025 and eyeball
  the item labels: they must now read as real products (e.g. "Voltaic Headphones MX-3F"), not dsdgen gibberish, and ≥1
  curated **hero brand** per populated category must appear in the top-N. Concretely:
  `SELECT i_category, i_brand, SUM(cs_ext_sales_price) rev FROM catalog_sales JOIN item ON cs_item_sk=i_item_sk
   JOIN date_dim ON cs_sold_date_sk=d_date_sk WHERE d_year=2025 GROUP BY 1,2 ORDER BY rev DESC LIMIT 20;`
  Confirms the catalog "lights up" the Product hierarchy the Phase-2 md model will drill (Category→Class→Brand→Item).

- [ ] **T5 — Commit the refreshed US recon baseline.**
  Copy the T3 post-catalog recon outputs to `data/recon/results/` (the live baseline) and keep the pre-catalog set as
  `data/recon/results-precatalog/` (the proof-of-orthogonality reference). Commit both with a message noting the diff was
  clean. This becomes the input to Stage 1.6's R0 assembly (US in USD).

- [ ] **T6 — Catalog integrity report (verification).**
  Author `data/catalog/integrity_check.sql` (a psql script) and run it against `hartland_us`. It asserts, as SELECTs that
  should each return **zero problem rows**:
  - **Row/NULL scan:** `SELECT count(*) FROM item WHERE i_category IS NOT NULL AND (i_product_name IS NULL OR i_brand IS NULL OR i_manufact IS NULL OR i_size IS NULL OR i_container IS NULL);` → 0.
  - **Key coverage:** every live `i_item_sk` still present; `SELECT count(*) FROM item` unchanged vs pre-catalog.
  - **FK integrity:** no `catalog_sales`/`store_sales`/`web_sales`/inventory row now references a missing `i_item_sk`
    (`SELECT count(*) FROM catalog_sales cs LEFT JOIN item i ON cs.cs_item_sk=i.i_item_sk WHERE i.i_item_sk IS NULL;` → 0).
  - **Category invariant:** `SELECT count(*) FROM item WHERE i_category NOT IN ('Books','Children','Electronics','Home','Jewelry','Men','Music','Shoes','Sports','Women') AND i_category IS NOT NULL;` → 0.
  This is an integration-flavoured DB check (a verification step, not a mocked stage blocker) — record it as green in the
  stage checkbox and carry it into Stage 1.6's DONE evidence.

## DONE bar

`hartland_us` carries the meaningful catalog; the seed-sensitive recon variants (r01/r02/r05/r08/r13) are **byte-identical**
to the committed pre-catalog baseline (story proven orthogonal); hero brands surface in queries #3/#5; the integrity report
is all-zero; a pre-catalog rollback dump is retained in `tpcds-staging/hartland/us/`.

## Verify block

```sh
data/recon/run-recon.sh dsk hartland_us
for r in r01 r02 r05 r08a r08b r13; do
  diff <(sort data/recon/results/$r.csv) <(sort data/recon/results-precatalog/$r.csv) && echo "$r OK"; done
kubectl --context dsk -n data exec -i test-pg-1 -c postgres -- psql -d hartland_us < data/catalog/integrity_check.sql
```
