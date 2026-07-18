-- Story-shape verification harness (percentage signals, currency-invariant by design).
-- Run against either world: psql -d hartland_us -f verify-story.sql
--                            psql -d hartland_cz -f verify-story.sql
-- Stage 1.5 T6 diffs the two outputs -- all four signals must match within tolerance (BM-7).
\pset format unaligned
\pset fieldsep ','

\echo 'signal,value'

-- 1. Marketplace H2 (Jul-Dec) YoY %, seed year vs the 4-year flat average.
WITH h2 AS (
  SELECT d.d_year, sum(cs_ext_sales_price) AS rev
  FROM catalog_sales JOIN date_dim d ON cs_sold_date_sk = d.d_date_sk
  WHERE d.d_moy BETWEEN 7 AND 12 AND d.d_year BETWEEN 2021 AND 2025
  GROUP BY d.d_year
)
SELECT 'h2_yoy_pct',
       round(100.0 * (
         (SELECT rev FROM h2 WHERE d_year = 2025)
         - (SELECT avg(rev) FROM h2 WHERE d_year BETWEEN 2021 AND 2024)
       ) / (SELECT avg(rev) FROM h2 WHERE d_year BETWEEN 2021 AND 2024), 2)::text
FROM h2 LIMIT 1;

-- 2. November YoY %.
WITH nov AS (
  SELECT d.d_year, sum(cs_ext_sales_price) AS rev
  FROM catalog_sales JOIN date_dim d ON cs_sold_date_sk = d.d_date_sk
  WHERE d.d_moy = 11 AND d.d_year BETWEEN 2021 AND 2025
  GROUP BY d.d_year
)
SELECT 'nov_yoy_pct',
       round(100.0 * (
         (SELECT rev FROM nov WHERE d_year = 2025)
         - (SELECT avg(rev) FROM nov WHERE d_year BETWEEN 2021 AND 2024)
       ) / (SELECT avg(rev) FROM nov WHERE d_year BETWEEN 2021 AND 2024), 2)::text
FROM nov LIMIT 1;

-- 3. Zero-inventory streak length at the meltdown DC: weeks where the zero share is clearly
--    seeded (>=50%), not baseline noise (baseline is ~0.1% of item-weeks, isolated).
WITH weekly AS (
  SELECT d.d_week_seq,
         count(*) FILTER (WHERE inv.inv_quantity_on_hand = 0)::numeric / count(*) AS zero_share
  FROM inventory inv
  JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
  WHERE d.d_year = 2025 AND inv.inv_warehouse_sk = 5
  GROUP BY d.d_week_seq
)
SELECT 'meltdown_dc_zero_streak_weeks_2025', count(*)::text
FROM weekly WHERE zero_share >= 0.5;

-- 4. "Late" reason share among surviving meltdown-DC returns, weeks 33-49/2025.
WITH base AS (SELECT min(d_week_seq) AS b FROM date_dim WHERE d_year = 2025)
SELECT 'late_reason_share_pct_meltdown_returns',
       round(100.0 * count(*) FILTER (WHERE cr.cr_reason_sk = 3) / nullif(count(*), 0), 2)::text
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk, base
WHERE cr.cr_warehouse_sk = 5
  AND d.d_year = 2025
  AND d.d_week_seq BETWEEN base.b + 33 - 1 AND base.b + 49 - 1;

-- 5. Per-state/kraj revenue rank-correlation guard (geography-even red herring): just the
--    count of distinct regions with >0 catalog revenue in 2025, for a quick sanity cross-check
--    (the actual rank-correlation diff is computed by the caller from r06b, not here).
SELECT 'catalog_regions_active_2025',
       count(DISTINCT ca.ca_state)::text
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE d.d_year = 2025;
