# Stage 3.2 — The two warehouses = the shared `hartland-pg` fixture  (= plan-cluster **H2**, generalized per BM-10)

> **Phase 3, Stage 3.2.** Plans: [`../plan-demo-build.md`](../plan-demo-build.md) (§ Stage 3.2) ·
> [`../test-fixture-hartland-replan.md`](../test-fixture-hartland-replan.md) (**§1 — the shared deployment**) ·
> **`olymp/clusters/hartland/plan-cluster.md`** (Phase **H2** — H2.1 CNPG, H2.2 restore, H2.3 seed sanity).
> Decisions: [`../08-czech-mirror-and-catalog-delta.md`](../08-czech-mirror-and-catalog-delta.md) (**Q-BM-3a** one
> CNPG / two DBs; **BM-10** fixture on every cluster; **Q-BM-7** retire `tpcds-query` DB / keep dump). Design:
> `06-e-cluster-spec.md` **E-2/S-14**; recon anchors `demo-transcript.md` App. B.
>
> **Goal:** both demo databases (`hartland_us`, `hartland_cz`) serve **read-only**, from the **one shared
> `hartland-pg` component** composed into **bp-dsk, collite-o1, AND hartland** (the showcase CNPG is this component,
> not a bespoke one). Restore **both** dumps; run **seed sanity on both** (Memphis streak on us, Brno streak on cz).
> **Repo: [O] olymp only.** Source of truth = the Phase-1 dumps in `tpcds-staging/hartland/{us,cz}/`.
>
> **SV-P4 cross-ref:** the **collite-o1** overlay here is the standing `hartland-pg` that **SV-P4 · S7**
> (`project/server/design-corpus/implementation/tasks/tasks-sv-p4-s7-dry-run.md` T1) requires as its scratch host.

## Depends on

- **Stage 3.1 DONE** — the hartland cluster (and its `platform/data` tier) exists; bp-dsk + collite-o1 already stand.
- **G3 — both demo dumps in `tpcds-staging/hartland/{us,cz}/`** with `data/recon/dump-manifest.md` pinned
  (Phase 1 done). The **pre-seed** baseline restores without G3; the **seed sanity** (T6) needs the seeded dumps.

## Pre-flight

- [ ] Stage 3.2 branch: `feat/p3-s2-warehouses-fixture`.
- [ ] Existing shape to mirror: `olymp/platform/data/test-pg/{base/{cluster,databases}.yaml, overlays/<cluster>/{load-job,externalsecret-pg-tpcds-*-cred}.yaml}` and the per-cluster CES
      `olymp/clusters/<cluster>/platform/auth/clusterexternalsecret-pg-tpcds-ro.yaml`.
- [ ] Vault reachable; a `pg-hartland-ro` (or `-us-ro`/`-cz-ro`) secret path provisioned for the readonly creds.
- [ ] Seaweed `tpcds-staging` reachable from all three clusters (`seaweedfs-s3.data.svc.cluster.local:8333`).

## Tasks

- [ ] **T1 — Author the `hartland-pg` CNPG base (H2.1, generalized).**
  New shared component `olymp/platform/data/hartland-pg/base/`:
  - `cluster.yaml` — a CNPG `Cluster` mirroring `test-pg/base/cluster.yaml`: `instances: 1`, storage sized for
    **~2× the two restored DBs** (S-14 — isolates warehouse scans from agent-state I/O; the §7.1 one-PG rule is
    agent DBs only, so a dedicated warehouse CNPG is legal). `managed.roles`: **`hartland_us_readonly`** and
    **`hartland_cz_readonly`** (mirror `tpcds_readonly`), each `login: true`, `passwordSecret:` →
    `pg-hartland-us-ro-cred` / `pg-hartland-cz-ro-cred`. Owner/loader role `hartland` (`passwordSecret: pg-hartland-cred`).
  - `databases.yaml` — **two** CNPG `Database` CRs (`hartland_us`, `hartland_cz`), `owner: hartland`,
    `cluster: { name: hartland-pg }`, sync-wave `"2"` (after the Cluster at wave `"1"`).
  - `kustomization.yaml` — lists `cluster.yaml`, `databases.yaml`, `restore-job.yaml` (T2).

- [ ] **T2 — The restore Job (H2.2 T1, both DBs).**
  `olymp/platform/data/hartland-pg/base/restore-job.yaml` — pattern lifted from
  `test-pg/overlays/*/load-job.yaml` but **`pg_restore -Fc`** instead of `\copy`: pull each dump from Seaweed
  (`$S3/hartland/us/<dump>` and `$S3/hartland/cz/<dump>`, anonymous GET), **idempotent drop+recreate**, restore
  **both** DBs. Dump version **pinned in values** (`us.dumpFile` / `cz.dumpFile`, from `data/recon/dump-manifest.md`).
  Not auto-synced by ArgoCD (mirror the test-pg load-job `SkipDryRun` + hand-apply convention); a values bump +
  Job re-run re-restores when Phase 1 re-freezes R0 (`test-fixture-hartland-replan.md` §0).
  ```sh
  # inside the Job, per world:
  createdb-if-absent hartland_us; pg_restore -Fc --clean --if-exists -d hartland_us <(curl -sf "$S3/hartland/us/$US_DUMP")
  createdb-if-absent hartland_cz; pg_restore -Fc --clean --if-exists -d hartland_cz <(curl -sf "$S3/hartland/cz/$CZ_DUMP")
  ```

- [ ] **T3 — The read-only creds + ClusterExternalSecrets (H2.1 T2, two of them).**
  Per **§1**: `pg-hartland-us-ro` and `pg-hartland-cz-ro` ClusterExternalSecrets, lifted from
  `clusters/bp-dsk/platform/auth/clusterexternalsecret-pg-tpcds-ro.yaml` and retargeted:
  - `externalSecretName: pg-hartland-{us,cz}-ro-cred`; `secretStoreRef: azure-store`; `remoteRef.key: pg-hartland-{us,cz}-ro`;
    `template.type: kubernetes.io/basic-auth`, username `hartland_{us,cz}_readonly`.
  - **`namespaceSelectors`** must match: the `kantheon` app ns, the `ttr-server` ns, **and** the harness run
    namespaces (`olymp.collite/managed-by: test-harness`) — exactly as the tpcds-ro CES does today, so ESO
    materializes the cred when infra-up labels a run namespace. Place one CES per cluster under
    `clusters/{bp-dsk,collite-o1,hartland}/platform/auth/`.
  - Also add the CNPG-side `externalsecret-pg-hartland-{us,cz}-ro-cred.yaml` (data ns) in each overlay (mirror
    `test-pg/overlays/<cluster>/externalsecret-pg-tpcds-ro-cred.yaml`) so CNPG and Arges agree on the password.

- [ ] **T4 — Compose the component into all three cluster overlays (BM-10 §1).**
  Add `- ../../../../platform/data/hartland-pg/overlays/<cluster>` to each of:
  `clusters/bp-dsk/platform/data/kustomization.yaml`, `clusters/collite-o1/platform/data/kustomization.yaml`,
  `clusters/hartland/platform/data/kustomization.yaml` — **alongside** the existing `test-pg` line (bp-dsk/collite-o1
  keep `test-pg` for now; Q-BM-7 retirement of the live `tpcds-query` context happens in Stage 3.4, and the pristine
  `tpc-ds-1g` dump is kept). Create `overlays/{bp-dsk,collite-o1,hartland}/kustomization.yaml` for hartland-pg
  (base + the per-cluster CNPG creds; collite-o1 needs the barman-cloud plugin only if PITR is wanted — not required
  for a restore-from-dump fixture).

- [ ] **T5 — Restore the dumps + verify the instances (H2.2 T2, per cluster).**
  Apply the restore Job on each cluster (hand-apply, like tpcds-load). Verify: CNPG instance **Healthy**; both roles
  connect read-only; row-count manifest matches `dump-manifest.md`:
  ```sh
  for c in bp-dsk collite-o1 hartland; do
    kubectl --context $c -n data get cluster hartland-pg
    kubectl --context $c -n data exec hartland-pg-1 -c postgres -- \
      psql -d hartland_cz -c "SELECT count(*) FROM store_sales;"     # non-zero, matches manifest
  done
  ```
  On the **hartland** (showcase) cluster restore the **pre-seed** baseline first if G3 is not yet landed (bring-up
  doesn't wait); swap to the seeded dump when G3 lands (one `values` bump + Job re-run).

- [ ] **T6 — Seed sanity on BOTH worlds (H2.3, run twice — E-5 item 2).**
  After G3, run the recon variants against the cluster DB **per world** and confirm the seeded story at its
  Q-4-frozen magnitude:
  - **`hartland_us`** — r01/r02 show −10..12% Marketplace H2-2025; r08 the **17-week Memphis** zero-streak;
    r13 names (Memphis DC = the ex-NULL warehouse, S-7/S-8).
  - **`hartland_cz`** — the mirror (BM-7): the same %s, DC = **Brno**, in CZK; r08 the 17-week **Brno** streak;
    reason skew on **"Nedorazilo včas"**.
  Commit both recon outputs next to the Phase-1 baselines as the cluster's reference (`data/recon/cluster-<world>-<date>/`).

- [ ] **T7 — Fixture test gate (template/render + a `demo-check` connectivity assertion).**
  Infra "test" per the conventions: `kustomize build` each cluster's data tier renders the hartland-pg component;
  the two CES render with the run-harness selector. Plus a **readiness assertion** (capability, tracked): a run
  namespace labelled `olymp.collite/managed-by=test-harness` receives `pg-hartland-{us,cz}-ro-cred`, and a probe pod
  connects to `hartland-pg-rw.data.svc.cluster.local` as `hartland_cz_readonly`. Real-cluster acceptance is tracked,
  not a mocked-unit blocker.

## DONE bar (plan-cluster H2, generalized)

- [ ] The **one** `hartland-pg` component serves `hartland_us` + `hartland_cz` read-only on **all three** clusters
      (bp-dsk, collite-o1, hartland).
- [ ] Both dumps restore clean per cluster; row counts match `dump-manifest.md`.
- [ ] **Seed sanity green on both worlds** (Memphis streak on us, Brno streak on cz) — recon committed next to the baselines.
- [ ] Both `pg-hartland-{us,cz}-ro` CESs materialize the cred into the harness run namespaces (§1 selector).
- [ ] collite-o1's overlay stands (SV-P4 · S7's scratch-host dependency satisfied).

## Verify block

```sh
kustomize build olymp/clusters/hartland/platform/data | grep -q 'name: hartland-pg' && echo "component composed"
for c in bp-dsk collite-o1 hartland; do
  kubectl --context $c -n data get cluster hartland-pg -o jsonpath='{.status.phase}'; echo " ($c)"
  kubectl --context $c -n data exec hartland-pg-1 -c postgres -- \
    psql -tAc "SELECT datname FROM pg_database WHERE datname LIKE 'hartland_%';"   # hartland_us + hartland_cz
done
# seed sanity (both worlds) matches R0:
data/recon/run-recon.sh hartland hartland_us | grep -E 'Memphis|17'    # 17-week Memphis streak
data/recon/run-recon.sh hartland hartland_cz | grep -E 'Brno|17'       # 17-week Brno streak, CZK
```
