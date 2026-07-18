-- Hartland Stores naming layer (C-4/C-5alpha', US world). Idempotent PK-keyed UPDATEs — display
-- values only, physical schema/keys untouched. Warehouse identity (meltdown_sk=5) matches
-- seed.conf; keep in sync if that ever changes.
\set ON_ERROR_STOP on
BEGIN;

-- S-7: 6 logical stores (s_store_id), 12 SCD rows share a name.
UPDATE store SET s_store_name = 'Nashville'     WHERE s_store_id = 'AAAAAAAABAAAAAAA';
UPDATE store SET s_store_name = 'Memphis'       WHERE s_store_id = 'AAAAAAAACAAAAAAA';
UPDATE store SET s_store_name = 'Knoxville'     WHERE s_store_id = 'AAAAAAAAEAAAAAAA';
UPDATE store SET s_store_name = 'Chattanooga'   WHERE s_store_id = 'AAAAAAAAHAAAAAAA';
UPDATE store SET s_store_name = 'Franklin'      WHERE s_store_id = 'AAAAAAAAIAAAAAAA';
UPDATE store SET s_store_name = 'Murfreesboro'  WHERE s_store_id = 'AAAAAAAAKAAAAAAA';

-- S-8: 5 DCs; Memphis DC = warehouse_sk 5 (the ex-NULL-named / meltdown warehouse, S-8a).
UPDATE warehouse SET w_warehouse_name = 'Memphis DC'   WHERE w_warehouse_sk = 5;
UPDATE warehouse SET w_warehouse_name = 'Columbus DC'  WHERE w_warehouse_sk = 1;
UPDATE warehouse SET w_warehouse_name = 'Dallas DC'    WHERE w_warehouse_sk = 2;
UPDATE warehouse SET w_warehouse_name = 'Reno DC'      WHERE w_warehouse_sk = 3;
UPDATE warehouse SET w_warehouse_name = 'Allentown DC' WHERE w_warehouse_sk = 4;

-- S-9: the 13 placeholder "reason NN" rows (keyed on r_reason_sk -- two rows, 30 and 31, share
-- the literal text "reason 31", a dsdgen quirk, so text-matching would collapse them).
UPDATE reason SET r_reason_desc = 'Changed my mind'                 WHERE r_reason_sk = 23;
UPDATE reason SET r_reason_desc = 'Found a better price'            WHERE r_reason_sk = 24;
UPDATE reason SET r_reason_desc = 'Wrong size'                      WHERE r_reason_sk = 25;
UPDATE reason SET r_reason_desc = 'Wrong color'                     WHERE r_reason_sk = 26;
UPDATE reason SET r_reason_desc = 'Ordered by mistake'              WHERE r_reason_sk = 27;
UPDATE reason SET r_reason_desc = 'No longer needed'                WHERE r_reason_sk = 28;
UPDATE reason SET r_reason_desc = 'Not as pictured'                 WHERE r_reason_sk = 29;
UPDATE reason SET r_reason_desc = 'Unwanted gift'                   WHERE r_reason_sk = 30;
UPDATE reason SET r_reason_desc = 'Incompatible with my device'     WHERE r_reason_sk = 31;
UPDATE reason SET r_reason_desc = 'Quality not as expected'         WHERE r_reason_sk = 32;
UPDATE reason SET r_reason_desc = 'Arrived too late for the occasion' WHERE r_reason_sk = 33;
UPDATE reason SET r_reason_desc = 'Better price found online'       WHERE r_reason_sk = 34;
UPDATE reason SET r_reason_desc = 'Changed delivery plans'          WHERE r_reason_sk = 35;

COMMIT;

\echo '-- verification: remaining "reason N" placeholders (should be 0 or pre-existing non-numbered ones) --'
SELECT count(*) FROM reason WHERE btrim(r_reason_desc) ~ '^reason [0-9]+$';
\echo '-- warehouse names --'
SELECT w_warehouse_sk, w_warehouse_name FROM warehouse ORDER BY w_warehouse_sk;
\echo '-- store names --'
SELECT DISTINCT s_store_id, s_store_name FROM store ORDER BY 1;
