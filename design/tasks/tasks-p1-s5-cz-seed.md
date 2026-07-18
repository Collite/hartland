# Stage 1.5 — Seed the story in `hartland_cz` (Brno DC meltdown)

> **Phase 1, Stage 1.5.** Plan: [`../plan-demo-build.md`](../plan-demo-build.md) (§ Stage 1.5).
> Decisions: [`../08-czech-mirror-and-catalog-delta.md`](../08-czech-mirror-and-catalog-delta.md)
> — **BM-7** (the story is mirrored, not re-invented: same C-3a seed spec S1–S4, DC = Brno, same %
> magnitude as US, different absolute currency). Seed spec source: `03-c-data-options.md` C-3 v2
> (S1–S4) and `demo-transcript.md` App. B (Q-4 magnitude guidance).
>
> **Goal:** the same authored ground truth as US (Memphis) but re-pointed to **Brno DC**, verified
> to the **same shape** — parity is the point (a locale switch proves *only* locale-agnosticism).

## Where the code lives

```
data/seed/02-seed-incident/         # the seed battery, re-pointed at hartland_cz / Brno DC
├── s1-inventory-zero.sql           # inventory zero-streak
├── s2-marketplace-delete.sql       # catalog_sales + catalog_returns deletion
├── s3-reason-skew.sql              # "Nedorazilo včas" reassignment
├── seed.conf                       # DC sk, week windows, magnitude % (frozen at R0)
└── tests/verify-story.sql          # T4/T6 — the parity assertion harness
```

Canonical columns: `inventory` (`inv_item_sk`, `inv_warehouse_sk`, `inv_date_sk`, `inv_quantity_on_hand`),
`catalog_sales` (`cs_warehouse_sk`, `cs_sold_date_sk`, `cs_order_number`, `cs_item_sk`, `cs_ext_sales_price`),
`catalog_returns` (`cr_order_number`, `cr_item_sk`, `cr_returned_date_sk`, `cr_reason_sk`, `cr_return_amount`),
`date_dim` (`d_date_sk`, `d_year`, `d_week_seq`, `d_date`), `r_reason` (`r_reason_sk`, `r_reason_desc`).

## Depends on

- **Stage 1.3 DONE** — `hartland_cz` localized + redated; **Brno DC = the highest-Marketplace-share warehouse** (same
  `w_warehouse_sk` the US world named "Memphis DC"), Stage 1.3 T2.
- **Stage 1.4 DONE** — Czech catalog + reasons applied; "Nedorazilo včas" is a distinct `r_reason_sk` (Stage 1.3 T5 /
  Stage 1.4 T3). *(Seeds are item-agnostic in selection, so catalog order vs seed is not strictly required — but reasons
  must be Czech before S3 targets "Nedorazilo včas".)*
- The **Q-4-frozen magnitude** from the US seed (`data/seed/02-seed-incident/seed.conf` on the US side) — applied
  **identically** here (same %; CZK absolute follows from the already-CZK facts).

## Pre-flight

- [ ] Stage 1.5 branch: `feat/p1-s5-cz-seed`.
- [ ] Resolve the Brno DC `w_warehouse_sk`: `SELECT w_warehouse_sk FROM warehouse WHERE w_warehouse_name='Brno DC';` →
      set in `seed.conf` as `MELTDOWN_WAREHOUSE_SK`.
- [ ] Resolve the "Nedorazilo včas" `r_reason_sk`: `SELECT r_reason_sk FROM r_reason WHERE r_reason_desc='Nedorazilo včas';`
      → `LATE_REASON_SK` in `seed.conf`.
- [ ] Copy the US-frozen magnitude/window values into `seed.conf` (do not re-tune — BM-7 says magnitude is tuned once).

## Tasks

- [ ] **T1 — Re-point the seed scripts at `hartland_cz` / Brno DC.**
  Parameterize the seed SQL on `seed.conf` (`MELTDOWN_WAREHOUSE_SK`, `LATE_REASON_SK`, week windows, magnitude %) via
  `psql -v`. The scripts are the US `02-seed-incident` battery with the warehouse SK and reason SK swapped — **no
  structural change**. Deterministic selection keyed on `mod(hash(stable_id), N)`, **never `random()`** (idempotent,
  reproducible — the same rows are selected on a re-run). Guard each script against double-application (a marker row /
  `_seed_meta` flag) so re-running is a no-op, not a compounding delete.

- [ ] **T2 — S1/S2/S3 seeds (Brno, mirrored windows).**
  - **S1 — inventory zero-streak** (`s1-inventory-zero.sql`): set `inv_quantity_on_hand = 0` at Brno DC for ~70% of items,
    **weeks 31–47 of 2025** (join `inventory` to `date_dim` on `inv_date_sk`, filter `d_year=2025 AND d_week_seq BETWEEN
    <wk31> AND <wk47>`, `inv_warehouse_sk = :meltdown_sk`, item selection by `mod(hash(inv_item_sk),10) < 7`). A 17-week
    streak vs the 0.09% baseline (r08) is unambiguous.
  - **S2 — Marketplace slump** (`s2-marketplace-delete.sql`): delete ~60% (the frozen %) of `catalog_sales` lines with
    `cs_warehouse_sk = :meltdown_sk` sold in **weeks 32–48 of 2025**, plus their matching `catalog_returns` (delete
    returns first, or by `cr_order_number` IN the deleted order set — **no orphan returns**). Selection deterministic on
    `mod(hash(cs_order_number),100)`. Expected: Marketplace H2-2025 ≈ **−10..12% YoY** (or the frozen figure — see the
    Q-4 note below), Nov ≈ −12%.
  - **S3 — reason skew** (`s3-reason-skew.sql`): for *surviving* Brno-shipped `catalog_returns` in **weeks 33–49/2025**,
    reassign ~40% of `cr_reason_sk` to `:late_reason_sk` ("Nedorazilo včas"). Near-uniform baseline (r04) makes it pop.

- [ ] **T3 — Apply the Q-4-frozen magnitude (same % as US; CZK absolute).**
  The percentages in `seed.conf` are **identical** to the US seed's frozen values (BM-7). Because CZK facts are a uniform
  ×FX scale of USD (Stage 1.3 T4), applying the same % deletion yields the same *relative* collapse — the −10..12% (or
  the R0-frozen November/wks-32–48 figure, per App. B's arithmetic note that the pure H2 headline needs deletion ≈75–80%
  or a wider window) reads identically. Do **not** independently re-tune against CZK numbers; the CZK absolute follows.
  Record in `seed.conf` a comment pointing at the US R0 the magnitude was frozen against.

- [ ] **T4 — Recon the CZ story; confirm the seeded shape.**
  Run the seed-sensitive recon variants against `hartland_cz` (`data/recon/run-recon.sh dsk hartland_cz`, variants
  **r01/r02** channel trend, **r04** reason mix, **r05** category×channel, **r08a/b** stockout, **r13** warehouse share).
  Assert the seeded signals are present:
  - Marketplace H2-2025 down the frozen % vs the four flat prior years (r01/r02).
  - A **17-week zero-on-hand streak at Brno DC, weeks 31–47/2025**, baseline elsewhere ≤0.10% (r08).
  - "Nedorazilo včas" skew ≈40% of surviving Brno returns vs ~3% baseline (r04).
  - Brno's Marketplace share collapses; the other four DCs flat at ~20% (r13).

- [ ] **T5 — Red-herring check (all dying branches stay flat, in CZK).**
  Confirm the S4 red herrings are genuinely flat so every wrong hypothesis dies on flat evidence:
  **Web flat** (kills cannibalization — query #10 overlap unchanged), **demographics flat** (buyer age 45.0 — #12),
  **promo dense as always** (97.7–100% linkage — #13), **Stores untouched** (#14), **geography even** (per-kraj revenue
  unchanged by the meltdown — #11; the Stage 1.3 T3 distribution-preserving map guarantees the "regional branch dies
  even" property holds in CZK). Any non-flat red herring is a seed leak — investigate before proceeding.

- [ ] **T6 — Side-by-side US↔CZ story-shape diff (verification).**
  Author `data/seed/02-seed-incident/tests/verify-story.sql` (run against both DBs) that computes the **percentage**
  signals (not absolutes) for each world and asserts they match within tolerance (BM-7 parity):
  - Marketplace H2-2025 YoY %: `|pct_us − pct_cz| ≤ 0.5pp`.
  - Zero-streak length + week window: identical (weeks 31–47, both).
  - "Late" reason share among surviving meltdown returns: `|pct_us − pct_cz| ≤ 1pp`.
  - Per-region (state/kraj) revenue distribution: rank-correlation ≈ 1.0 (distribution preserved).
  Because CZK = USD ×FX, all these ratios are currency-invariant → the two worlds must be numerically identical in %.
  This is an integration-flavoured DB check (verification, not a mocked stage blocker); record it green and carry it to
  Stage 1.6.

## DONE bar

`hartland_cz` carries the mirrored meltdown (Brno DC, S1–S3, same % magnitude as US); recon shows the −frozen%
Marketplace H2-2025, the 17-week Brno zero-streak, and the "Nedorazilo včas" skew; every red herring is flat (incl.
geography even in CZK); the US↔CZ percentage story-shape diff matches within tolerance. Seeds are idempotent (double-run
is a no-op).

## Verify block

```sh
kubectl --context dsk -n data exec -i test-pg-1 -c postgres -- psql -v ON_ERROR_STOP=1 \
  -v meltdown_sk=$BRNO_SK -v late_reason_sk=$LATE_SK -d hartland_cz < data/seed/02-seed-incident/s1-inventory-zero.sql
# ... s2, s3 likewise ...
data/recon/run-recon.sh dsk hartland_cz
# parity diff (US already seeded from Stage 1.2's world):
kubectl --context dsk -n data exec -i test-pg-1 -c postgres -- psql -d hartland_us < data/seed/02-seed-incident/tests/verify-story.sql > /tmp/us_shape.txt
kubectl --context dsk -n data exec -i test-pg-1 -c postgres -- psql -d hartland_cz < data/seed/02-seed-incident/tests/verify-story.sql > /tmp/cz_shape.txt
diff /tmp/us_shape.txt /tmp/cz_shape.txt   # percentage columns match within tolerance
```
