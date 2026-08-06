# SD-P0 — Pre-flight & probes

> Phase exit: [`../plan.md`](../plan.md) §SD-P0. Output artifact: `../probes.md` — one
> section per probe, each ending in a **VERDICT:** line the later phases cite. Nothing in
> this phase is a guess; every verdict quotes the file/commit/output it rests on.

- [ ] **T1 — Pin the product state.** Verify FO-A1 PRs **tatrman#104 + tatrman-platform#13**
  are MERGED and FO-A2 (`fo-a2` lineage, P0 `1cd2c7f` … P5) is PUSHED. Record in
  `probes.md` the exact SHAs of both repos the demo builds on (`git log -1` on the merged
  masters / branch). If either is missing → STOP, flag Bora (plan §Global pre-flight),
  do not build on unmerged worktrees.
- [ ] **T2 — Branch + skeleton.** In `Collite/hartland`: branch `studio-demo`; create
  `design/studio-demo/` (this corpus — commit it), `rig/`, `data/plan/`. Add
  `rig/README.md` stub with the three entry points (contracts §7).
- [ ] **T3 — Probe: the A1 authoring loop posture (feeds SD-⚑3).** On the pinned state,
  boot the Designer + `ttr-designer-server` per the A1 repo's own dev docs; open any
  workspace; exercise: `ttrp/validate` (expect: served — A1 P0 probe found it on the WS),
  draft **preview-run** (`ttrp/run`: does it accept draft `text`, or `uri`-only with the
  A1-CAP-003 stub chip showing?), **graduate** (`saveProgram` → catalog refresh). Screenshot
  each. **VERDICT:** Beat-D variant = `draft-live-run` or `graduate-then-run`.
- [ ] **T4 — Probe: `:services:studio-planner` boot surface.** From the pinned platform
  repo: how the service is configured (datasource env/HOCON, port, JWKS/bearer expectations
  — the A2 `PlannerRuntime.fromConfig` + `installEntryIngress` path), and how
  `acceptance-walk.mjs` wires it. Boot it against a scratch PG16; hit `/health`+`/ready`.
  **VERDICT:** the rig's env block for the service + the real default ports (amend
  contracts §7's placeholders).
- [ ] **T5 — Probe: launcher + workspace load.** How an app registers a launcher tile
  (A2-P5 registered Studio Planner — read that commit) and how the Designer opens a **git
  clone as Worker workspace** (the model-load path for `model/` of this repo). Load the
  hartland model read-only; confirm the md star renders (Beat 1 feasibility).
  **VERDICT:** rig launch config for 4 tiles + workspace-mount recipe.
- [ ] **T6 — Rig skeleton up.** `rig/up.sh` v0: PG16 container (empty `hartland_plan`
  + restored `hartland_us` from the demo dump per `data/recon/dump-manifest.md`), the two
  services from T4/T5 recipes, the shell dev-served. All health endpoints green from one
  command. (Auth = whatever is fastest for now; ⚑2 lands in P4.)
- [ ] **T7 — Close the flag loop.** SD-⚑1…5 are RULED (2026-07-23 — verdict table in
  `00-task-management.md`): only ⚑3's *probe verdict* remains open — write T3's verdict
  into the table. Confirm the rig skeleton (T6) actually runs on **Rancher Desktop's
  docker** on Bora's machine (⚑1) — RD VM memory sized before the `hartland_us` restore
  (see olymp README's `rdctl set` example). Phase DONE = probes.md complete + T6 boots
  on RD + this list all checked.

## Verify block

```sh
rig/up.sh                      # exits 0; prints all-green health table
cat design/studio-demo/probes.md | grep -c '^VERDICT:'   # == 4 (T3,T4,T5 + ports)
git -C . branch --show-current  # studio-demo
```
