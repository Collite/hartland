# Dump manifest — Phase 1 versioned demo dumps

Source of truth for `test-fixture-hartland-replan.md` §0 ("when Phase 1 re-freezes R0, the
fixture is re-restored from the new dumps"). One version bump = one edit to this file.

## hartland_us — 2026-07-18

- **Path:** `tpcds-staging/hartland/us/hartland_us-demo-20260718.dump`
- **sha256:** `0ebfd9484832c910a408837a876309c0dcfcc60316660fa94dbc5260a945a81b`
- **Size:** 380,116,857 bytes
- **pg_dump:** `-Fc -Z6`
- **Row counts** (exact `COUNT(*)`, not `pg_stat_user_tables.n_live_tup` -- that estimate was
  stale on the CZ side pending autovacuum/ANALYZE): `item` 18,000, `store_sales` 2,880,404,
  `catalog_sales` 1,424,874 (post S2 deletion of 16,674), `catalog_returns` 142,371 (post S2
  deletion of 1,696).

## hartland_cz — 2026-07-18

- **Path:** `tpcds-staging/hartland/cz/hartland_cz-demo-20260718.dump`
- **sha256:** `9d7b02eda425cdbd5c27becdf56ab3568498fc3dc505034c4de9f99c081405a2`
- **Size:** 338,962,330 bytes
- **pg_dump:** `-Fc -Z6`
- **FX constant:** 23 (`data/localize-cz/fx.conf`) — applied once, guarded via `_localize_meta`.
- **Row counts:** identical to US, verified by exact `COUNT(*)` -- `item` 18,000, `store_sales`
  2,880,404, `catalog_sales` 1,424,874, `catalog_returns` 142,371 (S2 selection is currency-
  invariant, hash-keyed on `cs_order_number`, so both worlds delete the same lines).

## Restore

```sh
kubectl --context dsk -n data cp hartland_us-demo-20260718.dump test-pg-1:/dev/shm/hartland_us.dump -c postgres
kubectl --context dsk -n data exec test-pg-1 -c postgres -- createdb hartland_us_verify
kubectl --context dsk -n data exec test-pg-1 -c postgres -- pg_restore -d hartland_us_verify --no-owner /dev/shm/hartland_us.dump
# repeat for hartland_cz -> hartland_cz_verify
```

## History

- 2026-07-18 — first freeze (Stage 1.6, Phase 1 close). Supersedes the `hartland_us-precatalog-
  20260718.dump` DR snapshot (`data/dr-snapshots.md`) as the demo-ready artefact; the precatalog
  snapshot is retained, not overwritten.
