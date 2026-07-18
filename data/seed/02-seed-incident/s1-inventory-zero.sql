-- S1 — inventory root cause: inv_quantity_on_hand -> 0 at the meltdown DC for ~70% of items,
-- weeks 31-47 of the target year (C-3a spec v2). Deterministic (hashtext, never random()).
-- Idempotent: guarded by _seed_meta; a second run is a no-op (UPDATE-to-0 is also naturally
-- idempotent in effect, the guard just avoids re-scanning + gives a clear notice).
\set ON_ERROR_STOP on
\ir seed.conf

SELECT set_config('seed.meltdown_sk', :'meltdown_sk', false);
SELECT set_config('seed.late_reason_sk', :'late_reason_sk', false);
SELECT set_config('seed.year', :'year', false);
SELECT set_config('seed.s1_week_start', :'s1_week_start', false);
SELECT set_config('seed.s1_week_end', :'s1_week_end', false);
SELECT set_config('seed.s1_pct', :'s1_pct', false);

CREATE TABLE IF NOT EXISTS _seed_meta (
  seed_name  text PRIMARY KEY,
  applied_at timestamptz NOT NULL DEFAULT now(),
  detail     text
);

DO $body$
DECLARE
  meltdown_sk int := current_setting('seed.meltdown_sk')::int;
  yr          int := current_setting('seed.year')::int;
  wk_start    int := current_setting('seed.s1_week_start')::int;
  wk_end      int := current_setting('seed.s1_week_end')::int;
  pct         int := current_setting('seed.s1_pct')::int;
  base_seq    int;
  n           bigint;
BEGIN
  IF EXISTS (SELECT 1 FROM _seed_meta WHERE seed_name = 's1-inventory-zero') THEN
    RAISE NOTICE 's1-inventory-zero: already applied — skipping (idempotent no-op)';
    RETURN;
  END IF;

  SELECT min(d_week_seq) INTO base_seq FROM date_dim WHERE d_year = yr;
  IF base_seq IS NULL THEN
    RAISE EXCEPTION 's1-inventory-zero: no date_dim rows for year %', yr;
  END IF;

  UPDATE inventory inv
  SET inv_quantity_on_hand = 0
  FROM date_dim d
  WHERE inv.inv_date_sk = d.d_date_sk
    AND inv.inv_warehouse_sk = meltdown_sk
    AND d.d_year = yr
    AND d.d_week_seq BETWEEN base_seq + wk_start - 1 AND base_seq + wk_end - 1
    AND abs(hashtext(inv.inv_item_sk::text)) % 100 < pct;
  GET DIAGNOSTICS n = ROW_COUNT;

  INSERT INTO _seed_meta(seed_name, detail)
  VALUES ('s1-inventory-zero',
          format('warehouse_sk=%s weeks=%s-%s pct=%s rows=%s', meltdown_sk, wk_start, wk_end, pct, n));

  RAISE NOTICE 's1-inventory-zero: % rows zeroed (warehouse %, weeks % .. %, year %)', n, meltdown_sk, wk_start, wk_end, yr;
END
$body$;
