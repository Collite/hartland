-- S2 — the slump: delete ~60% of catalog_sales lines shipped from the meltdown DC in weeks
-- 32-48, plus their matching catalog_returns (no orphan returns). Selection deterministic on
-- hashtext(cs_order_number) (C-3a spec v2). NOT naturally idempotent (a second run would delete
-- 60% of what survived the first) -- the _seed_meta guard is load-bearing here, unlike S1/S3.
\set ON_ERROR_STOP on
\ir seed.conf

SELECT set_config('seed.meltdown_sk', :'meltdown_sk', false);
SELECT set_config('seed.year', :'year', false);
SELECT set_config('seed.s2_week_start', :'s2_week_start', false);
SELECT set_config('seed.s2_week_end', :'s2_week_end', false);
SELECT set_config('seed.s2_pct', :'s2_pct', false);

CREATE TABLE IF NOT EXISTS _seed_meta (
  seed_name  text PRIMARY KEY,
  applied_at timestamptz NOT NULL DEFAULT now(),
  detail     text
);

DO $body$
DECLARE
  meltdown_sk  int := current_setting('seed.meltdown_sk')::int;
  yr           int := current_setting('seed.year')::int;
  wk_start     int := current_setting('seed.s2_week_start')::int;
  wk_end       int := current_setting('seed.s2_week_end')::int;
  pct          int := current_setting('seed.s2_pct')::int;
  base_seq     int;
  n_returns    bigint;
  n_sales      bigint;
BEGIN
  IF EXISTS (SELECT 1 FROM _seed_meta WHERE seed_name = 's2-marketplace-delete') THEN
    RAISE NOTICE 's2-marketplace-delete: already applied — skipping (guarded, deletion is not self-idempotent)';
    RETURN;
  END IF;

  SELECT min(d_week_seq) INTO base_seq FROM date_dim WHERE d_year = yr;
  IF base_seq IS NULL THEN
    RAISE EXCEPTION 's2-marketplace-delete: no date_dim rows for year %', yr;
  END IF;

  CREATE TEMP TABLE _s2_target ON COMMIT DROP AS
  SELECT cs.cs_item_sk, cs.cs_order_number
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE cs.cs_warehouse_sk = meltdown_sk
    AND d.d_year = yr
    AND d.d_week_seq BETWEEN base_seq + wk_start - 1 AND base_seq + wk_end - 1
    AND abs(hashtext(cs.cs_order_number::text)) % 100 < pct;

  -- returns first (no orphan returns), then the sales lines themselves
  DELETE FROM catalog_returns cr
  USING _s2_target t
  WHERE cr.cr_item_sk = t.cs_item_sk AND cr.cr_order_number = t.cs_order_number;
  GET DIAGNOSTICS n_returns = ROW_COUNT;

  DELETE FROM catalog_sales cs
  USING _s2_target t
  WHERE cs.cs_item_sk = t.cs_item_sk AND cs.cs_order_number = t.cs_order_number;
  GET DIAGNOSTICS n_sales = ROW_COUNT;

  INSERT INTO _seed_meta(seed_name, detail)
  VALUES ('s2-marketplace-delete',
          format('warehouse_sk=%s weeks=%s-%s pct=%s sales_deleted=%s returns_deleted=%s',
                 meltdown_sk, wk_start, wk_end, pct, n_sales, n_returns));

  RAISE NOTICE 's2-marketplace-delete: % catalog_sales lines + % matching catalog_returns deleted (warehouse %, weeks % .. %)',
    n_sales, n_returns, meltdown_sk, wk_start, wk_end;
END
$body$;
