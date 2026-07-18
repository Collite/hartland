-- Stage 1.3 T6b — DB assertion harness (integration-flavoured verification, not a stage
-- blocker). Run: psql -d hartland_cz -f verify.sql

\echo '-- schema parity vs pristine tpc-ds-1g: table/column counts (compare by eye against a --'
\echo '-- `\\d` on tpc-ds-1g -- Postgres has no cross-database FROM, so this is same-table-set only) --'
SELECT count(DISTINCT table_name) AS table_count, count(*) AS column_count
FROM information_schema.columns WHERE table_schema = 'public';
\echo '-- the only intentional schema delta vs pristine: 71 monetary columns widened numeric(7,2) -> numeric(10,2) --'
SELECT count(*) AS widened_money_columns
FROM information_schema.columns
WHERE table_schema = 'public' AND data_type = 'numeric' AND numeric_precision = 10 AND numeric_scale = 2;

\echo '-- redate: sales min/max, inventory max --'
SELECT 'store_sales' AS fact, min(d.d_date) AS min_date, max(d.d_date) AS max_date
FROM store_sales JOIN date_dim d ON ss_sold_date_sk = d.d_date_sk
UNION ALL
SELECT 'catalog_sales', min(d.d_date), max(d.d_date)
FROM catalog_sales JOIN date_dim d ON cs_sold_date_sk = d.d_date_sk
UNION ALL
SELECT 'inventory', min(d.d_date), max(d.d_date)
FROM inventory JOIN date_dim d ON inv_date_sk = d.d_date_sk;

\echo '-- CZK audit: FX marker present exactly once (guards against a compounded double-apply) --'
SELECT count(*) AS fx_marker_rows FROM _localize_meta WHERE step = 'czk_fx';

\echo '-- geography FK integrity: no orphan store/warehouse/customer_address; all CZ country --'
SELECT
  (SELECT count(*) FROM store WHERE s_country IS DISTINCT FROM 'Czech Republic') AS bad_store_country,
  (SELECT count(*) FROM warehouse WHERE w_country IS DISTINCT FROM 'Czech Republic') AS bad_warehouse_country,
  (SELECT count(*) FROM customer_address WHERE ca_country IS DISTINCT FROM 'Czech Republic') AS bad_addr_country,
  (SELECT count(*) FROM customer_address WHERE btrim(ca_state) !~ '^[A-Z]{2}$') AS bad_state_codes,
  (SELECT count(*) FROM store_sales ss LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk WHERE ss.ss_store_sk IS NOT NULL AND s.s_store_sk IS NULL) AS orphan_store_fk,
  (SELECT count(*) FROM catalog_sales cs LEFT JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk WHERE cs.cs_warehouse_sk IS NOT NULL AND w.w_warehouse_sk IS NULL) AS orphan_warehouse_fk;
