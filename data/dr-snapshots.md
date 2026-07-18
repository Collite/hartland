# DR snapshots

Rollback artefacts retained in `tpcds-staging` (SeaweedFS), one row per snapshot taken before an
irreversible-in-spirit step. Not overwritten by the versioned demo dumps (Stage 1.6).

| Path | Taken before | Date | sha256 |
|---|---|---|---|
| `hartland/us/hartland_us-precatalog-20260718.dump` | Stage 1.2 T2 (catalog UPDATE on the former `hartland` DB, renamed to `hartland_us` in T1) | 2026-07-18 | `4ea83a7ad4bd506a958328901806d5196cb44905e2f7464be7cec83844d9e738` |
