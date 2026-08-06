# Stage 3.4 — The `hartland-query` run-set (both worlds) + test-context repoint  (= plan-cluster **H4**, extended)

> **Phase 3, Stage 3.4.** Plans: [`../plan-demo-build.md`](../plan-demo-build.md) (§ Stage 3.4) ·
> [`../test-fixture-hartland-replan.md`](../test-fixture-hartland-replan.md) (**§2.1 — the per-context re-plan**) ·
> **`olymp/clusters/hartland/plan-cluster.md`** (Phase **H4**). Decisions:
> [`../08-czech-mirror-and-catalog-delta.md`](../08-czech-mirror-and-catalog-delta.md) (**BM-9** run-set lives in
> `Collite/hartland`; **BM-10** hartland on every cluster; **Q-BM-1a** CZ = US ×FX; **Q-BM-7** retire the live
> `tpcds-query`/`tpc-ds-1g` context, keep the pristine dump).
>
> **Goal:** the query surface proven mechanically for **each world** — the `hartland-query` run-set (oracle rows for
> all 15 `q.hartland.*`, both worlds) + the olymp test-contexts repointed onto hartland, defaulting to **CZ**.
> **Repos: [H] `Collite/hartland/run-set/`** (oracle rows) · **[O] olymp `test-contexts/*` + per-cluster CES** ·
> **[K] kantheon** (`deployment/test/bp-dsk-run-set.txt`, `.github/workflows/integration-nightly.yml`). New Proteus
> goldens for CASE-sum/md-derived shapes are **kantheon code (referenced, authored in Phase 2)** — not here.

## Depends on

- **Stage 3.3 DONE** — both worlds answer live through the full path (the run-set points at the standing estate).
- **Stage 3.2 DONE** — `hartland-pg` stands on all three clusters (the repointed nightly contexts reach it).
- **G3** for the raw-SQL leg (`theseus-runquery`, the `hartland-query` SQL oracle); **G2** for the model/agent
  contexts (`golem-hartland`, `pythia-rca`, `themis-routing`) — `test-fixture-hartland-replan.md` §3.

## Pre-flight

- [ ] Stage 3.4 branch: `feat/p3-s4-run-set-repoint`.
- [ ] `Collite/hartland/run-set/` exists (stub with README present); oracle-row home is here (BM-9).
- [ ] Shapes to mirror: `olymp/test-contexts/tpcds-query/` (context.yaml + per-service values; Arges extraEnv
      pattern) and `olymp/test-contexts/golem-erp/context.yaml` (Shem-as-ConfigMap agent-turn pattern).
- [ ] Phase-1 `data/recon/R0.md` (both worlds; CZ = US ×FX) available — the oracle-row source of truth.

## Tasks

- [ ] **T1 — Author the `hartland-query` run-set, both worlds (H4.1 T1/T2 — [H]).**
  In `Collite/hartland/run-set/` author the oracle rows for all **15** `q.hartland.*` queries **per world**:
  **US in USD**, **CZ = US ×FX** (Q-BM-1a — one figure set carries; the FX constant from `dump-manifest.md`). Anchor
  aggregates to `demo-transcript.md` App. B + the frozen `R0.md`. Structure: `run-set/{queries/,oracle/{us,cz}/}`
  with a per-query expected-rows file per world. Pointed at the **standing cluster estate** (no per-run bring-up).

- [ ] **T2 — New olymp `hartland-query` context, replacing `tpcds-query` (§2.1 — [O], Q-BM-7).**
  Create `olymp/test-contexts/hartland-query/` by lifting `tpcds-query/` and repointing: `context.yaml` name →
  `hartland-query`; **`arges.values.yaml`** `extraEnv` wires **`pg-hartland-cz`** (default) **and** `pg-hartland-us`
  instead of `pg-tpcds` (host `hartland-pg-rw.data.svc.cluster.local`, users `hartland_{cz,us}_readonly`, passwords
  from `pg-hartland-{cz,us}-ro-cred`; restate Proteus — the array is replaced). Oracle assertions = the 15
  `q.hartland.*` on CZK (US ×FX). **Retire the live `tpcds-query` context** (Q-BM-7a); **keep** the pristine
  `tpc-ds-1g` dump in Seaweed as a benchmark-vocabulary regression only if a test still needs canonical TPC-DS oracle
  rows (drop the context dir; note the retention decision in the context README). Generalized: this context runs on
  **every** cluster against the shared `hartland-pg`, not just the showcase.

- [ ] **T3 — Repoint `theseus-runquery` → hartland_cz (§2.1 — [O], the scheduled-nightly context).**
  This is the leanest smoke and the **only** context the scheduled nightly runs (`bp-dsk-run-set.txt` +
  `integration-nightly.yml`), so it moves first. In `olymp/test-contexts/theseus-runquery/` repoint the driven query
  to `hartland_cz` (raw-SQL leg — needs only Phase 1). Update its Arges wiring to `pg-hartland-cz` (mirror T2's
  extraEnv). Keep it the leanest single-query smoke.

- [ ] **T4 — Repoint the model/agent contexts (§2.1 — [O], needs Phase 2).**
  - **`golem-erp` → `golem-hartland`:** rename the context; `context.yaml` + Shem wiring point at the
    **golem-hartland** Shem / **hartland model** / **CZ data** (Marketplace/Brno questions) instead of the erp shem;
    new oracle. Mirror the golem-erp ConfigMap-Shem pattern (no image rebuild).
  - **`pythia-rca`:** repoint the RCA to hartland — Pythia finds **Brno DC** (CZ) / **Memphis DC** (EN) unaided; the
    seeded meltdown is the canonical RCA fixture (Phase-1 seeds + Phase-2 model).
  - **`themis-routing`:** route the scripted questions to the **`hartland`** area(s) + the gap/visibility cases
    (both persona sets).
  - **`smoke`:** unchanged (no warehouse).
  **Fixture-secret ripple:** each repointed context's `arges.values.yaml` restates the connection env and depends on
  `pg-hartland-{us,cz}-ro` in the run namespace (the CESs from Stage 3.2 T3 already extend their selector to
  `olymp.collite/managed-by=test-harness`).

- [ ] **T5 — Update the run-set matrix + the nightlies (§2.1 — [K] + [O]).**
  - **[K]** `kantheon/deployment/test/bp-dsk-run-set.txt` — replace the context names:
    `pythia-rca` (repointed), `golem-erp`→`golem-hartland`, `themis-routing` (repointed), `theseus-runquery`
    (repointed), `tpcds-query`→`hartland-query`. Keep lean→heavy order.
  - **[K]** `kantheon/.github/workflows/integration-nightly.yml` — the scheduled nightly's single context stays
    `theseus-runquery` (now hartland_cz); no name change needed there, but confirm the repointed context is what
    runs.
  - **[O]** `olymp/.github/workflows/nightly-ecosystem.yml` (the nightly master) inherits the new context names —
    update any hardcoded context list to the hartland names.

- [ ] **T6 — `just demo-check hartland` runs both worlds + the E-5 item-5 probes (H4.1 T3 — [O]/[H]).**
  Wire `just demo-check hartland` to run the `hartland-query` set for **both** worlds (US oracle in USD, CZ oracle in
  CZK) against the standing cluster, plus the **E-5 item-5 probes per world**: Themis routes the scripted beats incl.
  the **gap question**; Pythia RCA finds the meltdown DC unaided in ≤ rehearsed budget; **Metis forecast** renders
  with intervals; **Themis SPLIT** decomposes the compound question into Golem+Pythia in one turn (satellite S /
  PD-13 — Stage 3.0 fold: SPLIT otherwise had no verification before the dry run). This recipe is the
  freeze-window daily smoke.

- [ ] **T7 — Run-set test gate (oracle self-check + context template render).**
  Per the conventions: the "test" is a **golden/oracle self-check + template render**, not a mocked unit —
  ```sh
  # oracle rows well-formed + both worlds present for all 15 queries:
  ls Collite/hartland/run-set/oracle/us | wc -l    # 15
  ls Collite/hartland/run-set/oracle/cz | wc -l    # 15
  # every repointed context renders + carries a hartland connection, none still references pg-tpcds live:
  for c in hartland-query theseus-runquery golem-hartland pythia-rca themis-routing; do
    grep -qr 'pg-hartland' olymp/test-contexts/$c/ && echo "$c ok"; done
  grep -rl 'pg-tpcds' olymp/test-contexts/ | grep -v smoke   # expect empty (tpcds-query retired)
  ```
  Live-cluster acceptance (all 15 return oracle rows) is the tracked capability verified by `just demo-check`, not a
  gate here.

## DONE bar (plan-cluster H4, extended — E-5 items 4–5)

- [ ] All **15** queries return the oracle rows **live on both worlds** (US USD, CZ CZK = US ×FX).
- [ ] Routing + forecast + RCA probes green **per world** (E-5 item 5).
- [ ] `tpcds-query` retired; `hartland-query` replaces it; the pristine `tpc-ds-1g` dump kept per the retention note.
- [ ] Run-set matrix + both nightlies point at the hartland context names; `just demo-check hartland` = the daily smoke.

## Verify block

```sh
just demo-check hartland                                  # both worlds' 15 queries + item-5 probes green
grep -c hartland kantheon/deployment/test/bp-dsk-run-set.txt      # ≥ 4 hartland-named contexts
grep -rl 'pg-tpcds' olymp/test-contexts/ | grep -vi smoke         # expect empty
diff <(cut -d, -f2 Collite/hartland/run-set/oracle/cz/q03.csv) <(fx-scale Collite/hartland/run-set/oracle/us/q03.csv)  # CZ == US ×FX
```
