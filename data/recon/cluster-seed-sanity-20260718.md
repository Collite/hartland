# Cluster seed sanity — hartland showcase cluster (Stage 3.2 T6 / E-5 item 2)

Verified live on the **hartland** cluster's `hartland-pg` CNPG (both worlds restored from the
Phase-1 demo dumps), 2026-07-18. This is the cluster's reference alongside the Phase-1 baselines
(`data/recon/R0.md`, `data/recon/dump-manifest.md`). Confirms the restore is the seeded demo data,
not generic TPC-DS — the meltdown story is present at its R0-frozen magnitude in both worlds.

## Restore (T5) — row counts match `dump-manifest.md` exactly

| DB | item | store_sales | catalog_sales |
|---|---|---|---|
| `hartland_us` | 18,000 | 2,880,404 | 1,424,874 |
| `hartland_cz` | 18,000 | 2,880,404 | 1,424,874 |

Restored via `platform/data/hartland-pg/base/restore-job.yaml` (`pg_restore -Fc`, PG 18.3);
sha256 of both dumps verified against the manifest before/after the SeaweedFS staging.

## Seed sanity (T6) — 2025 zero-inventory share per DC

The smoking gun (S1): the meltdown DC's zero-on-hand share vs the ~0.1% baseline at the other four.
Matches R0 exactly (**22.8% = 106,654 / 468,000**).

**hartland_us** (meltdown = Memphis):

| DC | zero_rows | total | zero_pct |
|---|---|---|---|
| **Memphis DC** | 106,654 | 468,000 | **22.79%** |
| Allentown DC | 445 | 468,000 | 0.10% |
| Dallas DC | 457 | 468,000 | 0.10% |
| Columbus DC | 440 | 468,000 | 0.09% |
| Reno DC | 400 | 468,000 | 0.09% |

**hartland_cz** (meltdown = Brno, BM-7 mirror — identical share):

| DC | zero_rows | total | zero_pct |
|---|---|---|---|
| **Brno DC** | 106,654 | 468,000 | **22.79%** |
| Hradec Králové DC | 445 | 468,000 | 0.10% |
| Ostrava DC | 457 | 468,000 | 0.10% |
| Plzeň DC | 400 | 468,000 | 0.09% |
| Praha DC | 440 | 468,000 | 0.09% |

Localized DC names correct in both worlds (Memphis↔Brno as the meltdown DC; US vs CZ peers). The
read-only roles (`hartland_us_readonly` / `hartland_cz_readonly`) connect and SELECT; their creds
materialize into `kantheon` + `ttr-server` for Arges (Stage 3.3).

> Note: the full R0 recon battery (r01/r02 Marketplace −10.62% wks 32–48, r04 reason skew 39.10%,
> r13 DC revenue) is the same frozen data as Phase 1 (`R0.md`) — the restore preserves it byte-for-
> byte (sha-verified), so this cluster check targets the S1 smoking gun as the live restore proof.
