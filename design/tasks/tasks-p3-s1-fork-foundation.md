# Stage 3.1 — Cluster fork & foundation  (= plan-cluster **H1**)

> **Phase 3, Stage 3.1.** Plans: [`../plan-demo-build.md`](../plan-demo-build.md) (§ Stage 3.1) ·
> **`olymp/clusters/hartland/plan-cluster.md`** (Phase **H1** — this stage is that plan; reuse its task
> detail verbatim). Decisions: [`../08-czech-mirror-and-catalog-delta.md`](../08-czech-mirror-and-catalog-delta.md)
> (E-1 pinned tags, E-3 roster). Design source: `06-e-cluster-spec.md` **E-3** (the estate roster).
>
> **Goal:** the `hartland` cluster exists as a full Olymp peer tenant — ArgoCD self-managing; auth/data/gateway/
> monitoring tiers green — with the estate **trimmed to the E-3 demo roster** and the image policy **pinned**.
> **Repo: [O] olymp only.** No second-world delta here — the CZ world touches data/wiring (3.2/3.3), not the fork.

## Depends on

- **Stage 3.0 sign-off** (the completeness gate) — H2+ waits on it; H1 (fork/trim/pin) may run in parallel.
- **G5 — hardware decided** (Q-12): where the K3s node physically runs. This is the only gate H1 needs.

## Pre-flight

- [ ] Stage 3.1 branch: `feat/p3-s1-fork-foundation`.
- [ ] `just new-cluster` / `just bootstrap` scaffold available (Phase 6 / D24 olymp mechanics).
- [ ] The `forking.md` runbook (eso-bootstrap re-seal) reachable; `collite-o1` cold-start fixes (D24) known.
- [ ] `:testing` images are acceptable for bring-up (E-1) — the **pin flip is G1, done at 3.5**, not here.
- [ ] `olymp/clusters/hartland/` currently holds only `plan-cluster.md` (confirmed) — the overlay is created here.

## Tasks

- [ ] **T1 — Provision the K3s node + kube-context (H1.1 T1).**
  Provision the node per G5 (`--node-external-ip` if the host is public). Kube-context **`hartland`** (context =
  cluster name, D24). Sizing: reuse the bp-dsk **request-shrink** values from day one (the constellation idles heavy
  on CPU *requests*, R1). Record the host + base-domain concrete (`<base_domain>`, TLS via the forked cert-manager CA)
  in `olymp/clusters/hartland/README.md`.

- [ ] **T2 — Fork bp-dsk into the overlay (H1.1 T2).**
  `just new-cluster hartland <base_domain>` — forks bp-dsk into `olymp/clusters/hartland/` + every
  `platform/*/hartland` overlay + `root-app-hartland.yaml`. Verify the tree materializes:
  `clusters/hartland/{apps,platform/{auth,data,gateway,monitoring}}` + `golems/`.

- [ ] **T3 — Bootstrap + re-seal auth (H1.1 T3).**
  `just bootstrap hartland hartland`; re-seal `eso-bootstrap-auth` to the new controller (per `forking.md`). Vault:
  reuse `olymp` (D24) unless G5 landed off-Azure — if off-Azure, note the store swap in the overlay README.

- [ ] **T4 — Verify app-of-apps reconciles (H1.1 T4).**
  Confirm root-app, auth, data, gateway, monitoring are **Synced/Healthy** (collite-o1 parity; D24 cold-start fixes
  apply; the retired bp-olymp01 baseline is not the reference — D28).
  ```sh
  argocd app list --grpc-web | grep hartland
  kubectl --context hartland get applications -n argocd
  ```

- [ ] **T5 — Trim the apps to the E-3 roster (H1.2 T1).**
  In `clusters/hartland/apps/*`, **remove** (nothing routes to them): `midas-core`, `midas-excel-loader`, `sysifos`,
  `sysifos-bff`, `brontes`, `steropes`, `report-renderer`. **Keep/add** per E-3: theseus (+mcp), proteus, argos,
  kyklop, arges, capabilities-mcp, ariadne (+mcp), echo (+mcp), kadmos (+mcp), prometheus, charon (+mcp),
  metis (+mcp), iris, iris-bff, themis (+mcp), pythia, hebe, golem (the chart for the golems ApplicationSet).
  `landing` is optional/cosmetic — decide at 3.3, zero-risk either way. Trim the golems appset input:
  `clusters/hartland/golems/` **starts empty** (filled in Stage 3.3); **do NOT** copy bp-dsk's `golem-ucetnictvi`.
  - **⚠ RECONCILE FIRST (Stage 3.0 X-roster).** The keep/remove names above are the **pre-rename**
    E-3 roster — `theseus`/`proteus`/`argos`/`kyklop`/`arges`/`ariadne`/`echo`/`kadmos`/`prometheus`
    **no longer exist** as apps on the live bp-dsk/collite-o1/hartland clusters (constellation
    renamed; current apps: `dispatch`, `query`, `resolver`, `fuzzy`, `kallimachos`, `kleio`,
    `veles`, `llm-gateway`, … + survivors `charon`/`metis`/`iris`/`hebe`/`pythia`/`themis`/`golem`/
    `capabilities-mcp`). Establish the old→new mapping (source: the kantheon service list + the
    live rosters) and rewrite the keep/remove lists against **current** names before trimming.
    **Until then the trim is deferred and the full forked roster runs** (64 GB fits it) — the
    estate is green, so the trim is a footprint optimization, not a correctness gate. See
    `p3-completeness-matrix.md` (X-roster).

- [ ] **T6 — Set the image policy = pinned (H1.2 T2, D12 per-cluster).**
  NO `hartland` entry in any ImageUpdater CR / disable `sys-image-updater` for this cluster. Every `config.json`
  pins `chartRevision` to a release tag (bring-up may sit on `:testing` until **G1**, then flip pin-to-pin **by PR
  only** at Stage 3.5). Declare the **freeze-window rule** in `clusters/hartland/README` (no chart/image/model changes;
  only `demo-reset` + daily `demo-check`).

- [ ] **T7 — Foundation test gate (lint/template, not a live-cluster blocker).**
  Per the conventions' testing policy, the "test" for an infra stage is a **template/lint** gate, not a mocked unit:
  ```sh
  kustomize build olymp/clusters/hartland/platform/auth   >/dev/null
  kustomize build olymp/clusters/hartland/platform/data   >/dev/null
  argocd app diff root-app-hartland --grpc-web || true      # renders; no drift on the trimmed roster
  ```
  Assert: no removed app (midas*/sysifos*/brontes/steropes/report-renderer) appears in the rendered manifests;
  no `:testing`-tracking image automation references `hartland`. Real-cluster acceptance is a tracked capability
  (verified in T4 / Stage 3.5), not a gate here.

## DONE bar (plan-cluster H1)

- [ ] All Applications **Synced/Healthy** on the **trimmed E-3 roster**; the four platform tiers green.
- [ ] `argocd app list` shows **no `:testing`-tracking image automation** for hartland (pinned policy in force).
- [ ] `clusters/hartland/golems/` empty; no `golem-ucetnictvi` copied; freeze-window rule documented in the README.

## Verify block

```sh
kubectl --context hartland get applications -n argocd -o wide          # all Synced/Healthy
argocd app list --grpc-web | grep hartland | grep -v Healthy           # expect empty
# removed apps are truly gone:
for a in midas-core midas-excel-loader sysifos sysifos-bff brontes steropes report-renderer; do
  test -e olymp/clusters/hartland/apps/$a && echo "STILL PRESENT: $a"; done
kustomize build olymp/clusters/hartland/platform/data >/dev/null && echo "data tier renders"
```
