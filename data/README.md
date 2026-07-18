# data — the two-world data build

Produces `hartland_us` (EN/USD) and `hartland_cz` (CZ/CZK) and their versioned demo dumps
(`tpcds-staging/hartland/{us,cz}/`). Pipeline order (per stage; see `design/plan-demo-build.md`
Phase 1):

1. `redate/` — `run-redate.sh <host> 23 <db>` (+23y; refuses to run against `tpc-ds-1g`).
2. `localize-cz/` — CZ geography (stores/addresses/DCs incl. Brno), CZK conversion, cs reasons.
3. `catalog/` — the bilingual per-item catalog: taxonomy + generator → `catalog/{us,cz}` UPDATEs.
4. `seed/` — `02-seed-incident` — Memphis DC (us) / Brno DC (cz) meltdown S1–S4.
5. `recon/` — the recon battery + committed baselines; R0 freeze; `pg_dump` → staging.

All scripts idempotent + hash-keyed (deterministic). Item keys + category assignments are
invariants (the seeds key on warehouse×week, not item).
