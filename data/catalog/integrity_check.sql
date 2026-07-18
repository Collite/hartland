-- Stage 1.2 T6 / Stage 1.4 T5 — catalog integrity report.
-- Every SELECT below should return 0 problem rows. Run against hartland_us or hartland_cz:
--   psql -d <db> < data/catalog/integrity_check.sql

\echo '-- Row/NULL scan: live-category rows missing a catalog field --'
SELECT count(*) AS null_scan_problems
FROM item
WHERE i_category IS NOT NULL
  AND (i_product_name IS NULL OR i_brand IS NULL OR i_manufact IS NULL
       OR i_size IS NULL OR i_container IS NULL);

\echo '-- Key coverage: total item row count (compare to pre-catalog count) --'
SELECT count(*) AS item_row_count FROM item;

\echo '-- FK integrity: sales facts referencing a missing item --'
SELECT
  (SELECT count(*) FROM catalog_sales cs LEFT JOIN item i ON cs.cs_item_sk = i.i_item_sk WHERE i.i_item_sk IS NULL)
  + (SELECT count(*) FROM store_sales ss LEFT JOIN item i ON ss.ss_item_sk = i.i_item_sk WHERE i.i_item_sk IS NULL)
  + (SELECT count(*) FROM web_sales ws LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk WHERE i.i_item_sk IS NULL)
  AS orphan_fact_rows;

\echo '-- Category invariant: any row outside the 10 curated categories --'
SELECT count(*) AS category_invariant_problems
FROM item
WHERE i_category IS NOT NULL
  AND btrim(i_category) NOT IN
      ('Books','Children','Electronics','Home','Jewelry','Men','Music','Shoes','Sports','Women');
