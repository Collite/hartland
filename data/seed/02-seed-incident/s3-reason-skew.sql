-- S3 — corroboration: for surviving meltdown-DC catalog_returns in weeks 33-49, reassign ~40%
-- of reasons to the "late" reason (r_reason_sk=3, "Did not get it on time" / "Nedorazilo včas").
-- Selection deterministic on hashtext(cr_order_number). Naturally idempotent (re-set to the same
-- value converges) but still guarded for a clear applied/skip signal, per convention.
\set ON_ERROR_STOP on
\ir seed.conf

SELECT set_config('seed.meltdown_sk', :'meltdown_sk', false);
SELECT set_config('seed.late_reason_sk', :'late_reason_sk', false);
SELECT set_config('seed.year', :'year', false);
SELECT set_config('seed.s3_week_start', :'s3_week_start', false);
SELECT set_config('seed.s3_week_end', :'s3_week_end', false);
SELECT set_config('seed.s3_pct', :'s3_pct', false);

CREATE TABLE IF NOT EXISTS _seed_meta (
  seed_name  text PRIMARY KEY,
  applied_at timestamptz NOT NULL DEFAULT now(),
  detail     text
);

DO $body$
DECLARE
  meltdown_sk    int := current_setting('seed.meltdown_sk')::int;
  late_reason_sk int := current_setting('seed.late_reason_sk')::int;
  yr             int := current_setting('seed.year')::int;
  wk_start       int := current_setting('seed.s3_week_start')::int;
  wk_end         int := current_setting('seed.s3_week_end')::int;
  pct            int := current_setting('seed.s3_pct')::int;
  base_seq       int;
  n              bigint;
BEGIN
  IF EXISTS (SELECT 1 FROM _seed_meta WHERE seed_name = 's3-reason-skew') THEN
    RAISE NOTICE 's3-reason-skew: already applied — skipping (idempotent no-op)';
    RETURN;
  END IF;

  SELECT min(d_week_seq) INTO base_seq FROM date_dim WHERE d_year = yr;
  IF base_seq IS NULL THEN
    RAISE EXCEPTION 's3-reason-skew: no date_dim rows for year %', yr;
  END IF;

  UPDATE catalog_returns cr
  SET cr_reason_sk = late_reason_sk
  FROM date_dim d
  WHERE cr.cr_returned_date_sk = d.d_date_sk
    AND cr.cr_warehouse_sk = meltdown_sk
    AND d.d_year = yr
    AND d.d_week_seq BETWEEN base_seq + wk_start - 1 AND base_seq + wk_end - 1
    AND abs(hashtext(cr.cr_order_number::text)) % 100 < pct
    AND cr.cr_reason_sk IS DISTINCT FROM late_reason_sk;
  GET DIAGNOSTICS n = ROW_COUNT;

  INSERT INTO _seed_meta(seed_name, detail)
  VALUES ('s3-reason-skew',
          format('warehouse_sk=%s weeks=%s-%s pct=%s late_reason_sk=%s rows=%s',
                 meltdown_sk, wk_start, wk_end, pct, late_reason_sk, n));

  RAISE NOTICE 's3-reason-skew: % surviving returns reassigned to reason % (warehouse %, weeks % .. %)',
    n, late_reason_sk, meltdown_sk, wk_start, wk_end;
END
$body$;
