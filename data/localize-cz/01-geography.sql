-- Stage 1.3 T2/T3 — CZ geography localization: store, warehouse, customer_address.
-- Idempotent (PK-keyed / total UPDATE from a deterministic map). Physical schema untouched.
-- Assumes /dev/shm/localize-cz/geo-map.csv is present alongside this script (loaded via \copy).
\set ON_ERROR_STOP on
BEGIN;

-- ---- T2: stores (S-7 mirror) — same 6 s_store_id keys as the US world -----------------------
UPDATE store SET s_store_name = 'Praha',    s_city = 'Praha',    s_state = 'PH', s_zip = '100 00', s_country = 'Czech Republic' WHERE s_store_id = 'AAAAAAAABAAAAAAA';
UPDATE store SET s_store_name = 'Brno',     s_city = 'Brno',     s_state = 'JM', s_zip = '602 00', s_country = 'Czech Republic' WHERE s_store_id = 'AAAAAAAACAAAAAAA';
UPDATE store SET s_store_name = 'Ostrava',  s_city = 'Ostrava',  s_state = 'MS', s_zip = '702 00', s_country = 'Czech Republic' WHERE s_store_id = 'AAAAAAAAEAAAAAAA';
UPDATE store SET s_store_name = 'Plzeň',    s_city = 'Plzeň',    s_state = 'PL', s_zip = '301 00', s_country = 'Czech Republic' WHERE s_store_id = 'AAAAAAAAHAAAAAAA';
UPDATE store SET s_store_name = 'Olomouc',  s_city = 'Olomouc',  s_state = 'OL', s_zip = '779 00', s_country = 'Czech Republic' WHERE s_store_id = 'AAAAAAAAIAAAAAAA';
UPDATE store SET s_store_name = 'Liberec',  s_city = 'Liberec',  s_state = 'LI', s_zip = '460 00', s_country = 'Czech Republic' WHERE s_store_id = 'AAAAAAAAKAAAAAAA';

-- ---- T2: warehouses (Q-BM-5) — same 5 w_warehouse_sk keys as the US world;
--      w_warehouse_sk=5 is the meltdown DC (same physical identity as US Memphis DC) --------
UPDATE warehouse SET w_warehouse_name = 'Brno DC',            w_city = 'Brno',           w_state = 'JM', w_zip = '602 00', w_country = 'Czech Republic' WHERE w_warehouse_sk = 5;
UPDATE warehouse SET w_warehouse_name = 'Praha DC',           w_city = 'Praha',          w_state = 'PH', w_zip = '100 00', w_country = 'Czech Republic' WHERE w_warehouse_sk = 1;
UPDATE warehouse SET w_warehouse_name = 'Ostrava DC',         w_city = 'Ostrava',        w_state = 'MS', w_zip = '702 00', w_country = 'Czech Republic' WHERE w_warehouse_sk = 2;
UPDATE warehouse SET w_warehouse_name = 'Plzeň DC',           w_city = 'Plzeň',          w_state = 'PL', w_zip = '301 00', w_country = 'Czech Republic' WHERE w_warehouse_sk = 3;
UPDATE warehouse SET w_warehouse_name = 'Hradec Králové DC',  w_city = 'Hradec Králové', w_state = 'HK', w_zip = '500 00', w_country = 'Czech Republic' WHERE w_warehouse_sk = 4;

COMMIT;

-- ---- T3: customer_address, from the deterministic geo-map (many-to-one, distribution-preserving) ----
BEGIN;

DROP TABLE IF EXISTS _geo_map;
CREATE TEMP TABLE _geo_map (
  us_state   text,
  kraj       text,
  kraj_code  text,
  obec       text,
  psc_prefix text
);
\copy _geo_map FROM '/dev/shm/localize-cz/geo-map.csv' WITH (FORMAT csv, HEADER true)

-- non-NULL states: join on ca_state (btrim, since char(2) may carry padding — it doesn't here,
-- but be defensive)
UPDATE customer_address ca
SET ca_city = m.obec,
    ca_state = m.kraj_code,
    ca_zip = m.psc_prefix || ' ' || lpad((abs(hashtext(ca.ca_address_sk::text)) % 100)::text, 2, '0'),
    ca_country = 'Czech Republic'
FROM _geo_map m
WHERE btrim(ca.ca_state) = m.us_state;

-- NULL-state rows: the designated fallback row (us_state = '(null)')
UPDATE customer_address ca
SET ca_city = m.obec,
    ca_state = m.kraj_code,
    ca_zip = m.psc_prefix || ' ' || lpad((abs(hashtext(ca.ca_address_sk::text)) % 100)::text, 2, '0'),
    ca_country = 'Czech Republic'
FROM _geo_map m
WHERE ca.ca_state IS NULL AND m.us_state = '(null)';

COMMIT;

\echo '-- verification: any customer_address row not yet localized? (should be 0) --'
SELECT count(*) FROM customer_address WHERE ca_country IS DISTINCT FROM 'Czech Republic';
\echo '-- store/warehouse names --'
SELECT s_store_id, s_store_name, s_city, s_state FROM store ORDER BY 1;
SELECT w_warehouse_sk, w_warehouse_name, w_city, w_state FROM warehouse ORDER BY 1;
