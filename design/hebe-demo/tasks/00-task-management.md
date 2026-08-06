# HB — Hebe demo · Task management

> Umbrella over the HB mini-task-lists. Plans: [`../plan.md`](../plan.md) ·
> [`../architecture.md`](../architecture.md) · [`../contracts.md`](../contracts.md) ·
> narrative [`../00-demo-narrative.md`](../00-demo-narrative.md).

## Rules for the implementer

1. **Check checkboxes the moment a task completes** — the checkbox state is the
   coordination surface.
2. **Probe before mutate:** HB-P0 touches nothing; every P1 cluster change starts from a
   failing check in `rig-hb/verify.sh` and lands via an olymp PR / the §4.4 provisioning
   runbook. NO kubectl-edit-by-hand state.
3. **Never patch Hebe** (HB-D3/SD-D2): defects → kantheon issues tagged `hebe-demo` +
   `../findings.md`; take the honest-degradation beat variant meanwhile.
4. **Shared fixtures are sacred:** `monday-brief` + demo-reset belong to the Kantheon
   demo's E-4 scripts — extend through them, never fork (contracts §4.1/§6).
5. **Oracles grade facts + source, not wording** (LLM variance is expected; fact variance
   is a failure — contracts §3/§4).
6. **Receipts are never reset** (HB-R1) — the chain is the demo.
7. Freeze windows bar all cluster mutations (architecture §3). Check before P1 work.
8. Quirks → append to `../hebe-demo-quirks.md` as they bite (running file from P0).

## Flag verdict table (fill in as Bora rules)

| Flag | Question | Default | Verdict | Date |
|---|---|---|---|---|
| HB-⚑1 | instance: rebind `dev` to Maya / new `maya` instance | keep `dev` (HB-D2) | — | — |
| HB-⚑2 | console: HTTPRoute `hebe.…nip.io` / port-forward | HTTPRoute | — | — |
| HB-⚑3 | Telegram bot + vault seed; stage phone; 2nd account for Beat 6 | Bora creates; Bora's phone | — | — |
| HB-⚑4 | governance beat: all three strikes / receipts-only | all three | — | — |
| HB-⚑5 | offline-tolerance pocket (local `personal` profile) | one spoken line, no build | — | — |

## The lists

### HB-P0 — Pre-flight & probes *(no cluster mutation)*
- [ ] [`tasks-hb-p0-preflight.md`](./tasks-hb-p0-preflight.md) (7 tasks)

### HB-P1 — Instance & identity *(cluster/vault privileges; olymp PRs)*
- [ ] [`tasks-hb-p1-instance-identity.md`](./tasks-hb-p1-instance-identity.md) (8 tasks)

### HB-P2 — Fixtures
- [ ] [`tasks-hb-p2-fixtures.md`](./tasks-hb-p2-fixtures.md) (8 tasks)

### HB-P3 — Beats
- [ ] [`tasks-hb-p3-s1-phone-memory.md`](./tasks-hb-p3-s1-phone-memory.md) (7 tasks)
- [ ] [`tasks-hb-p3-s2-delegation-governance.md`](./tasks-hb-p3-s2-delegation-governance.md) (8 tasks)

### HB-P4 — Script, rehearsal, readiness
- [ ] [`tasks-hb-p4-script-dryrun.md`](./tasks-hb-p4-script-dryrun.md) (8 tasks)

## Progress log

| Date | Session | What moved | Notes |
|---|---|---|---|
| 2026-07-23 | planning | corpus + task lists authored | awaiting Bora: ⚑ verdicts (⚑3 gates P1) |
