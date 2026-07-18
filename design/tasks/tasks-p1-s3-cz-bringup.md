# Stage 1.3 — CZ world bring-up & geography localization (`hartland_cz`)

> **Phase 1, Stage 1.3.** Plan: [`../plan-demo-build.md`](../plan-demo-build.md) (§ Stage 1.3).
> Decisions: [`../08-czech-mirror-and-catalog-delta.md`](../08-czech-mirror-and-catalog-delta.md)
> — **BM-1** (two DBs), **BM-3** (full CZ world + CZK, Brno meltdown DC), **Q-BM-1a** (FX-scale CZK
> ×~23 then round), **Q-BM-5** (DCs: Brno + Praha + Ostrava + Plzeň + Hradec Králové).
>
> **Goal:** a Czech-grounded clone of the physical world — **same schema**, CZ places, CZK. Built
> fresh from the **pristine** `tpc-ds-1g` dump (not from the seeded US DB), so its baseline is
> localized-but-unseeded (the seed lands in Stage 1.5, calibrated against this baseline).

## Where the code lives

```
data/redate/run-redate.sh          # reused as-is: run-redate.sh <ctx> <offset> <db>
data/localize-cz/
├── 01-geography.sql                # T2/T3 — store, warehouse, customer_address → CZ
├── 02-czk-fx.sql                   # T4 — FX-scale monetary columns ×FX, rounded
├── 03-reasons.sql                  # T5 — r_reason → Czech strings
├── fx.conf                         # T4 — the FX constant (single source of truth)
├── geo-map.csv                     # T3 — deterministic US-state/city → CZ kraj/obec map
└── tests/                          # T6 — psql assertion harness + mocked map unit test
```

Canonical TPC-DS columns used here: `store` (`s_store_sk`, `s_store_id`, `s_city`, `s_state`, `s_zip`,
`s_country`), `warehouse` (`w_warehouse_sk`, `w_warehouse_id`, `w_warehouse_name`, `w_city`, `w_state`,
`w_country`), `customer_address` (`ca_address_sk`, `ca_city`, `ca_state`, `ca_zip`, `ca_country`),
`r_reason` (`r_reason_sk`, `r_reason_id`, `r_reason_desc`). Monetary fact columns for T4:
`*_ext_sales_price`, `*_ext_list_price`, `*_ext_wholesale_cost`, `*_list_price`, `*_wholesale_cost`,
`*_ext_discount_amt`, `*_net_paid`, `*_net_paid_inc_tax` across `store_sales`/`web_sales`/`catalog_sales`
+ the three returns; dim money columns `i_current_price`, `i_wholesale_cost`. (`*_net_profit` excluded per D-6a.)

## Pre-flight

- [ ] Stage 1.3 branch: `feat/p1-s3-cz-bringup`.
- [ ] Pristine `tpc-ds-1g` dump reachable (the same artefact Stage-1.2 US path never mutated).
- [ ] Stage 1.1 need NOT be done for T1–T5 (geography/CZK are catalog-independent); the CZ **catalog** apply is Stage 1.4.
- [ ] `data/redate/run-redate.sh` present (moved from `surgery/` per BM-9), default offset **+23**, guarded against double-runs.

## Tasks

- [ ] **T1 — Create `hartland_cz`, restore pristine, redate +23y.**
  ```sh
  kubectl --context dsk -n data exec test-pg-1 -c postgres -- createdb hartland_cz
  kubectl --context dsk -n data exec -i test-pg-1 -c postgres -- pg_restore -d hartland_cz --no-owner < tpc-ds-1g-pristine-*.dump
  data/redate/run-redate.sh dsk 23 hartland_cz
  ```
  `run-redate.sh` re-points every `*_date_sk` by +23y via the old_sk→new_sk map (calendar-exact, `date_dim` itself
  untouched), shifts plain-date validity windows, bumps `c_birth_year`. **Verification (built into the script):** sales
  span `2021-01-02 → 2026-01-08`, inventory ends `2025-12-25`. Single transaction, guarded. Edge case: ~4.5% of
  `store_sales` carry NULL `ss_sold_date_sk` (F-9) — the redate must tolerate/skip NULLs (it does for US; confirm on cz).

- [ ] **T2 — Localize `store` and `warehouse` → CZ towns and DCs.**
  Author `data/localize-cz/01-geography.sql`. **Stores** (keyed on `s_store_id`, 6 logical stores / 12 SCD rows sharing a
  name — mirror S-7): Praha (HQ), Brno, Ostrava, Plzeň, Olomouc, Liberec; set `s_city`, `s_state` → the kraj, `s_zip` →
  a valid PSČ, `s_country`='Czech Republic'. **Warehouses** (5 DCs, Q-BM-5): Brno DC, Praha DC, Ostrava DC, Plzeň DC,
  Hradec Králové DC — set `w_warehouse_name`, `w_city`, `w_state`, `w_country`. **Critical (mirror S-8a):**
  **Brno DC := the ex-NULL-named / highest-Marketplace-share warehouse** — the same physical `w_warehouse_sk` the US
  world made "Memphis DC" (per r13, 20.13% share). Determine it first:
  `SELECT cs_warehouse_sk, SUM(cs_ext_sales_price) FROM catalog_sales JOIN date_dim ON cs_sold_date_sk=d_date_sk WHERE d_year=2025 GROUP BY 1 ORDER BY 2 DESC;`
  → assign the top `w_warehouse_sk` the name "Brno DC" so Stage 1.5's seed lands on the meltdown DC by the same key logic
  as US. Idempotent UPDATEs (PK-keyed).

- [ ] **T3 — Localize `customer_address` → Czech obce + PSČ + kraj (distribution-preserving).**
  Author the address rewrite in `01-geography.sql` (or a `geo-map.csv` + apply step). Build a **deterministic** map from
  US `(ca_state, ca_city)` → CZ `(kraj, obec, PSČ)` in `data/localize-cz/geo-map.csv`, applied by join/UPDATE keyed on
  the US value. The map must be **many-to-one stable**: every distinct US state maps to exactly one CZ kraj, every US city
  to exactly one CZ obec — so **per-region revenue distributions are preserved unchanged** (the "regional branch dies
  even" red-herring property, F-5/S4, must hold in CZK too). Do NOT hash per-row (that would smear a state's revenue
  across krajs and break the even-distribution property). Set `ca_city`, `ca_state`, `ca_zip` (valid PSČ format `NNN NN`),
  `ca_country`='Czech Republic'. Edge case: NULL `ca_state`/`ca_city` rows map to a designated "unknown" kraj deterministically.

- [ ] **T4 — CZK conversion: FX-scale monetary columns ×FX, rounded (Q-BM-1a).**
  Author `data/localize-cz/02-czk-fx.sql` and `data/localize-cz/fx.conf` (the single documented constant, e.g.
  `FX_USD_CZK=23`). Multiply every monetary column (the list in "Where the code lives" above) by FX and round to a
  believable CZK price point (`ROUND(col * :fx / 10.0) * 10` → nearest 10 Kč, or nearest whole Kč for small values —
  document the rounding rule beside the constant). **The story is a %-effect** — ratios/percentages/YoY are invariant
  under a uniform scale, so the seeded arithmetic and the −10..12% headline carry across unchanged; one R0 figure set
  carries to CZK by ×FX (Stage 1.6 T1). Exclude `*_net_profit`/cost-only columns per D-6a from the *model*, but the
  physical `*_ext_wholesale_cost` still scales (it exists in the schema; just never surfaces). Apply as one transaction;
  idempotency guard: stamp a `localize_cz_fx_applied` marker row (or a boolean in a `_localize_meta` table) so a
  double-run is a no-op — **FX must not compound** (running twice would ×529). This is the one non-idempotent-by-PK step;
  the marker guard is mandatory.

- [ ] **T5 — Localize return reasons → Czech; isolate "Nedorazilo včas" (mirror S-9).**
  Author `data/localize-cz/03-reasons.sql`. Relabel `r_reason.r_reason_desc` to Czech strings (keyed on `r_reason_sk`),
  keeping **"Nedorazilo včas"** ("Did not get it on time") as a **distinct, clearly-separated** reason from the others
  (it is the S3 skew target in Stage 1.5 — must not collide with a near-synonym). Mirror the US placeholder-reason list in
  Czech: "Změnil/a jsem názor", "Našel/la jsem lepší cenu", "Špatná velikost", "Špatná barva", "Objednáno omylem",
  "Již nepotřebuji", "Neodpovídá popisu", "Nechtěný dárek", "Nekompatibilní", "Kvalita neodpovídá". Idempotent
  PK-keyed UPDATE. Confirm the exact `r_reason_sk` that carries "Did not get it on time" in the source and map it to
  "Nedorazilo včas" (so Stage 1.5's reason-skew reassigns to the right SK).

- [ ] **T6 — Verification: schema parity, redate, CZK audit, geography FK integrity.**
  Two layers. **(a) Mocked/unit** — a small pytest (`data/localize-cz/tests/test_geo_map.py`) over `geo-map.csv`: assert
  the map is total (every distinct source state/city has a target), single-valued (no state → two krajs), and
  distribution-preserving (a fixture of `(state → revenue)` maps to the same `(kraj → revenue)` totals). **(b) DB
  assertion harness** (`data/localize-cz/tests/verify.sql`, integration-flavoured verification step, not a stage blocker):
  - **Schema parity** vs pristine `tpc-ds-1g`: same table set, same column set (`information_schema.columns` diff = empty).
  - **Redate:** sales min/max = `2021-01-02 / 2026-01-08`; inventory max = `2025-12-25`.
  - **CZK audit:** pick 10 known rows, assert `cz_value ≈ round(us_value × FX)` within the rounding tolerance; assert
    the `localize_cz_fx_applied` marker prevents a second scaling.
  - **Geography FK integrity:** no orphan `store`/`warehouse`/`customer_address` FKs after the rewrite; `s_country` /
    `w_country` / `ca_country` all 'Czech Republic'; no residual US state string in the three tables.

## DONE bar

`hartland_cz` exists, restored from pristine, redated +23y (span verified); stores/warehouses/addresses are Czech with
**Brno DC = the meltdown warehouse** (same key as US Memphis); all monetary columns are CZK (×FX, rounded, guarded
against re-application); reasons are Czech with "Nedorazilo včas" isolated; schema is byte-parity with `tpc-ds-1g`; the
geo-map unit test and the DB verification harness pass. This is the **localized-but-unseeded** baseline Stage 1.5 seeds against.

## Verify block

```sh
data/redate/run-redate.sh dsk 23 hartland_cz            # (idempotent re-run reports already-applied)
kubectl --context dsk -n data exec -i test-pg-1 -c postgres -- psql -v ON_ERROR_STOP=1 -d hartland_cz < data/localize-cz/01-geography.sql
kubectl --context dsk -n data exec -i test-pg-1 -c postgres -- psql -v ON_ERROR_STOP=1 -d hartland_cz < data/localize-cz/02-czk-fx.sql
kubectl --context dsk -n data exec -i test-pg-1 -c postgres -- psql -v ON_ERROR_STOP=1 -d hartland_cz < data/localize-cz/03-reasons.sql
uv run pytest data/localize-cz/tests -q
kubectl --context dsk -n data exec -i test-pg-1 -c postgres -- psql -d hartland_cz < data/localize-cz/tests/verify.sql
```
