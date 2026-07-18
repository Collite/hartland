# Stage 1.6 — Dual baseline, R0 freeze & versioned dumps

> **Phase 1, Stage 1.6.** Plan: [`../plan-demo-build.md`](../plan-demo-build.md) (§ Stage 1.6 — carries
> the **Phase 1 DONE bar**). Decisions:
> [`../08-czech-mirror-and-catalog-delta.md`](../08-czech-mirror-and-catalog-delta.md) — **BM-1/BM-7/BM-10**,
> **Q-BM-1a** (one R0 figure set carries to CZK by ×FX). Fixture consumer:
> [`../test-fixture-hartland-replan.md`](../test-fixture-hartland-replan.md) (§0/§1 — these dumps
> become the shared `hartland-pg` fixture; the source of truth is `tpcds-staging/hartland/{us,cz}/`).
>
> **Goal:** frozen numbers (R0, both worlds) + the two restore artefacts the cluster (Phase 3, gate
> **G3**) and the ecosystem fixture consume. This is the phase-closing stage.

## Depends on

- **Stage 1.2 DONE** — `hartland_us` catalogued, story proven orthogonal, recon baseline committed.
- **Stage 1.5 DONE** — `hartland_cz` localized + catalogued + seeded, parity verified.

## Pre-flight

- [ ] Stage 1.6 branch: `feat/p1-s6-dumps-baseline`.
- [ ] Both worlds are in their final state (all prior stages' verify blocks green); no pending fixes.
- [ ] Seaweed `tpcds-staging` bucket reachable; `hartland/us/` and `hartland/cz/` prefixes exist (S-10; no new bucket).
- [ ] `demo-transcript.md` (the copy in `Collite/hartland/design/`) with its ⟨R0⟩ slots is writable for T4.

## Tasks

- [ ] **T1 — Final recon on both worlds; assemble the R0 number table per world.**
  Run `data/recon/run-recon.sh dsk hartland_us` and `… hartland_cz` a final time. Populate the **R0 table** — every
  ⟨R0⟩ slot the transcript (App. A) reserves — per world:
  - **US in USD**, **CZ in CZK** where CZK = the same figure ×FX (Q-BM-1a — one figure set carries; record both columns
    side by side with the FX constant noted).
  - Slots to freeze (from `demo-transcript.md`): Marketplace H2-2025 YoY % and the Nov figure; four DCs flat at
    ~$145M/≈$145M×FX ±1% with the meltdown DC's collapse (−~60% wks 32–48); "late" reason share (~40% of surviving
    meltdown returns vs ~3% baseline); the 17-week zero-streak window; Marketplace AOV (US ≈$23K/order, CZ ×FX).
  Write to `data/recon/R0.md` (a table: signal · US value · CZ value · source query · recon variant). This is the
  authoritative frozen-number record the rehearsal ladder R0 (07-f) and every ⟨R0⟩ in the transcript resolve against.

- [ ] **T2 — `pg_dump -Fc hartland_us` → `tpcds-staging/hartland/us/`.**
  ```sh
  kubectl --context dsk -n data exec test-pg-1 -c postgres -- \
    pg_dump -Fc -Z6 -d hartland_us > hartland_us-demo-$(date +%Y%m%d).dump
  ```
  Upload to `tpcds-staging/hartland/us/hartland_us-demo-<date>.dump`. Record the dump's sha256 + row-count manifest
  (`SELECT relname, n_live_tup FROM pg_stat_user_tables ORDER BY 1;`) alongside it for restore verification.

- [ ] **T3 — `pg_dump -Fc hartland_cz` → `tpcds-staging/hartland/cz/`; pin both versions.**
  Same shape for `hartland_cz` → `tpcds-staging/hartland/cz/hartland_cz-demo-<date>.dump`. **Pin both dump versions** in a
  single `data/recon/dump-manifest.md` (path, sha256, date, row-count summary, the FX constant used for cz) — this is the
  version the fixture re-plan (`test-fixture-hartland-replan.md` §0) reads: "when Phase 1 re-freezes R0, the fixture is
  re-restored from the new dumps." One version bump = one manifest edit.

- [ ] **T4 — Regenerate the transcript ⟨R0⟩ values (US) + a CZ R0 appendix.**
  In the `Collite/hartland/design/demo-transcript.md` copy, replace every ⟨R0: …⟩ placeholder with the frozen US value
  from `R0.md`. Add a **CZ R0 appendix** (the same beats in CZK) so a Czech delivery (BM-8, one-locale-per-delivery) has
  its own frozen numbers. Keep the % figures identical across the two (BM-7 parity); only absolutes differ (×FX). Note
  the FX constant at the head of the CZ appendix.

- [ ] **T5 — Disaster-recovery note: retain pre-catalog and pre-seed snapshots.**
  Confirm and document that the rollback artefacts are retained in Seaweed, not overwritten by the demo dumps:
  - US **pre-catalog** snapshot (Stage 1.2 T1) — `tpcds-staging/hartland/us/…-precatalog-<date>.dump`.
  - CZ **pre-seed** snapshot — take one now if not already retained: `pg_dump -Fc` of `hartland_cz` *before* Stage 1.5's
    seed would have been the clean localized baseline; if the seed is already applied, note that the localize scripts +
    pristine dump reconstruct it deterministically (redate → localize → catalog is reproducible). Record the DR recipe in
    `data/README.md` (the pipeline-order doc): pristine → redate → localize → catalog → seed → dump, each step idempotent
    or snapshot-guarded, so any world is rebuildable from `tpc-ds-1g` + the committed scripts.

- [ ] **T6 — Phase-1 close: restore-verify both dumps + the DONE-bar checklist.**
  Prove the artefacts, not just the live DBs (the fixture consumes the *dumps*). Restore each into a throwaway DB and
  re-run recon:
  ```sh
  createdb hartland_us_verify && pg_restore -d hartland_us_verify --no-owner < hartland_us-demo-*.dump
  data/recon/run-recon.sh dsk hartland_us_verify   # must match R0.md (US)
  createdb hartland_cz_verify && pg_restore -d hartland_cz_verify --no-owner < hartland_cz-demo-*.dump
  data/recon/run-recon.sh dsk hartland_cz_verify   # must match R0.md (CZ)
  ```
  Then walk the Phase-1 DONE bar (below) and check each item. Drop the `_verify` DBs after.

## DONE bar — Phase 1 (from the plan)

- [ ] **Both dumps restore clean** (T6 restore-verify green on fresh DBs).
- [ ] **Recon on each matches the frozen R0** (`data/recon/R0.md`, both worlds).
- [ ] **Catalog integrity + bilingual coverage green on both** (Stage 1.2 T6 / Stage 1.4 T5–T6 reports committed).
- [ ] **US story numbers unchanged from the 2026-07-09 baseline** (Stage 1.2 T3 diff clean — catalog orthogonal, proven).
- [ ] **US↔CZ story shape matches in %** (Stage 1.5 T6 parity diff), absolutes ×FX.
- [ ] **DR snapshots retained** (pre-catalog US, reconstructible CZ pre-seed) + `data/README.md` rebuild recipe.
- [ ] **Dumps pinned** in `data/recon/dump-manifest.md` (path/sha256/date/rowcounts/FX) → satisfies Phase 3 **G3** and
      the shared `hartland-pg` fixture source of truth.

## Verify block

```sh
data/recon/run-recon.sh dsk hartland_us && data/recon/run-recon.sh dsk hartland_cz
# restore-verify both artefacts on throwaway DBs (T6 block above), diff recon vs R0.md
diff <(recon hartland_us_verify) data/recon/R0-us.csv
diff <(recon hartland_cz_verify) data/recon/R0-cz.csv
sha256sum hartland_us-demo-*.dump hartland_cz-demo-*.dump   # matches dump-manifest.md
```
