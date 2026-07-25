# HB-P0 — Pre-flight & probes

> Output: `../probes.md` — one section per probe ending in a **VERDICT:** line the later
> phases cite; every verdict quotes the command/output/file it rests on. **No cluster
> mutation in this phase** (task-mgmt rule 2). Kube access + recipes:
> [`../../demo-ops-manual.md`](../../demo-ops-manual.md) §5–§6.

- [ ] **T1 — Pod & provisioning truth.** `kubectl --context hartland -n kantheon get
  deploy,pod -l app=hebe` (adjust selector from the chart) + describe. Is the pod Healthy
  or CreateContainerConfigError (= `hebe-dev` never provisioned — values header)? Inventory
  the `hebe-dev` secret **key names only** (`kubectl get secret hebe-dev -o
  jsonpath='{.data}' | jq 'keys'`): PG creds, Keycloak client+bound-user, llm-gateway-key,
  telegram token, receipts signing key — which exist? **VERDICT:** provisioned-state +
  the P1 gap list.
- [ ] **T2 — Image/feature level.** Pod image tag → map to the hebe tag lineage
  (`hebe/v0.4.0` needed: `kantheon_question` routines, Telegram delivery loop,
  AWAITING_AGENT mapping — integration plan P4). If the image predates P4: **STOP, flag
  Bora** (olymp pin bump PR + freeze check). **VERDICT:** feature level + upgrade need.
- [ ] **T3 — Console surface.** Port-forward `svc/hebe 8765` (ops-manual §6 discipline):
  what auth does the console present (password? OIDC?), does chat work, is the memory
  browser/routine monitor/receipts view present at this build? Screenshot each.
  **VERDICT:** console auth mode + which Beat-2/4/6 surfaces exist (feeds ⚑2 and the
  beat sheets).
- [ ] **T4 — Identity wiring.** From the secret inventory + hebe config: is a Keycloak
  client + bound user configured, and is it `maya` or something else? Attempt `hebe
  doctor` (console or exec) — record the identity/gateway/PG check results. **VERDICT:**
  OBO state + what P1 must change (client? bound-user? chat_user_map rows?).
- [ ] **T5 — Registry & routing.** capabilities-mcp list/search shows hebe; the routing
  view served to Themis does NOT (non_routable — integration plan Stage 3.4). Verify both
  sides via the mcp surfaces (port-forward). **VERDICT:** Beat-0 fact confirmed or a
  findings entry.
- [ ] **T6 — Telegram path.** (a) Config surface: what `[channels.telegram]` keys the
  shipped build expects (from the hebe docs/config module — read the kantheon repo, don't
  guess); (b) egress: from a debug pod, HTTPS to `api.telegram.org` reachable? **VERDICT:**
  the exact P1 config/secret delta for the channel + egress yes/no.
- [ ] **T7 — File the flags.** probes.md complete → put HB-⚑1…5 to Bora (plain text, with
  evidence); **⚑3 immediately** (bot creation + vault seed is Bora-serial and gates P1).
  Record verdicts/defaults in the `00-task-management.md` table. Check all boxes.

## Verify block

```sh
grep -c '^VERDICT:' design/hebe-demo/probes.md    # == 6
# and: zero cluster changes made (kubectl diff clean; no olymp commits from this phase)
```
