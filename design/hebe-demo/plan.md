# HB — Hebe demo on Hartland · Phased plan

> **Planning artefact (2026-07-23).** Inputs: [`00-demo-narrative.md`](./00-demo-narrative.md)
> · [`architecture.md`](./architecture.md) · [`contracts.md`](./contracts.md) · the Hebe
> integration arc (P1–P4, `hebe/v0.4.0`) · the Kantheon-demo corpus + ops manual. Task
> lists: [`tasks/00-task-management.md`](./tasks/00-task-management.md). Flags HB-⚑1…5
> (architecture §5) — defaults let P0 start now; ⚑3 (Telegram bot) is the earliest hard
> external dependency (bites at P1).

## 0. Overall plan

```
HB-P0 pre-flight & probes (cluster hebe reality, version, console, registry, OBO, telegram path)
  ▼
HB-P1 instance & identity (bound to Maya, Telegram live, console reachable — contracts §2 table met)
  ▼
HB-P2 fixtures (workspace memory seed · routines · delivery oracles · HB-R1 reset)
  ▼
HB-P3 beats (S1: phone+memory · S2: delegation+routines+hand-back+governance) — beat sheets
  ▼
HB-P4 script + rehearsal + dry-run + readiness (HB-B bar) — the exit
```

Strictly serial P0→P1→P2; P3's two stages may interleave; P4 is the barrier.

**Global pre-flight:** the hartland cluster green (Kantheon-demo estate); hebe deployed at
(or upgradeable to) the `hebe/v0.4.0` feature level — the P4 constellation-client features
(`kantheon_question`, Telegram delivery, AWAITING_AGENT) are the demo's spine, so **if the
cluster image predates them, HB-P0 stops and flags** (an image bump is an olymp pin PR +
freeze-calendar check).

**Global DONE:** HB-B 1–8 green + recorded · transcript + `hebe-demo-quirks.md` committed ·
fixtures + reset scripts in `data/hebe/` · findings routed · STATUS `done`.

## HB-P0 · Pre-flight & probes — [`tasks/tasks-hb-p0-preflight.md`](./tasks/tasks-hb-p0-preflight.md)

**Deliverable.** `probes.md`: the live truth of the cluster instance — pod state,
provisioned-or-not (`hebe-dev` secret contents inventory — names only, no values), image
version vs v0.4.0 features, registry state (non_routable honored), console auth mode +
reachability options, Keycloak OBO wiring state, Telegram config surface (what
`[channels.telegram]` needs), egress-to-Telegram check. Flags ⚑1…5 put to Bora with
evidence; **⚑3 kicked off immediately** (bot creation is Bora-serial).

**DONE.** every contracts-§2 row has a probed *current* value; verdicts recorded; no
cluster mutations yet.

## HB-P1 · Instance & identity — [`tasks/tasks-hb-p1-instance-identity.md`](./tasks/tasks-hb-p1-instance-identity.md)

**Deliverable.** Contracts §2 target table met on the cluster: bound user maya (OBO mint
verified), Telegram channel live both directions on the demo bot, chat_user_map = exactly
one row, console reachable per ⚑2 verdict, registry + doctor green. All changes via olymp
PRs / the provisioning runbook (§4.4) — freeze rules respected.

**Tests first.** Each wiring task starts from its verify probe (doctor check, token mint,
round-trip message) written as a failing check in `rig-hb/verify.sh` before the change.

**DONE.** `rig-hb/verify.sh` all-green: doctor clean · OBO mint as maya · Telegram
echo round-trip · console login · registry heartbeat · unmapped chat rejected.

## HB-P2 · Fixtures — [`tasks/tasks-hb-p2-fixtures.md`](./tasks/tasks-hb-p2-fixtures.md)

**Deliverable.** Contracts §3–§4 + §6: workspace seeded through the write path (fixture
files + install script, idempotent); `friday-returns` + `clarify-demo` fixture definitions;
`monday-brief` reconciled with the E-4 standing-fixture script (shared with the Kantheon
demo — coordinate, don't fork); oracles (`memory-answers.md`, `deliveries.md`) written
BEFORE seeding (the TDD of this phase); **HB-R1** reset extension implemented + proven
(reset → fixtures intact, sessions gone, receipts untouched).

**DONE.** seed → oracle spot-checks green · HB-R1 twice idempotent · Kantheon-demo
reset still preserves its own list (joint run).

## HB-P3 · Beats — S1 [`tasks/tasks-hb-p3-s1-phone-memory.md`](./tasks/tasks-hb-p3-s1-phone-memory.md) · S2 [`tasks/tasks-hb-p3-s2-delegation-governance.md`](./tasks/tasks-hb-p3-s2-delegation-governance.md)

**Deliverable.** S1 (Beats 0/1/2): the registry line verified for Beat 0; the Beat-1
phone→deep-link→Iris loop staged and timed; Beat-2 memory answers graded green; beat
sheets written. S2 (Beats 3/4/5/6): the delegation turn with identity + Iris badge; Beat-4
create-from-chat → routine diff vs fixture → manual fire → delivery; the Beat-5
AWAITING_AGENT choreography (engineer the clarifying question, pin it); the three Beat-6
governance strikes recorded exactly as the product behaves (⚑4 scope). Every beat: sheet +
screenshots + fallback move.

**DONE.** all in-scope beats runnable start-to-finish by a non-builder from the sheets;
HB-B items 2–6 individually green.

## HB-P4 · Script, rehearsal, readiness — [`tasks/tasks-hb-p4-script-dryrun.md`](./tasks/tasks-hb-p4-script-dryrun.md)

**Deliverable.** Frozen transcript (`demo-transcript-hebe.md`) with every quoted fact
oracle-pinned; timing boxes + fallback ladder (L0 retry · L1 pre-created routine /
pre-fired delivery / canned screenshots · L2 sheets); `hebe-demo-quirks.md` consolidated;
the **local-fallback proof** (one task: local Hebe boots + Beat 2 runs — architecture §3);
rehearsal ladder R1 table read → R2 beat drills (incl. one broken run per beat: kill
iris-bff mid-routine → failure *notification*; wrong-chat message; posture refusal) → R3
stopwatch → **R4 dry run: twice consecutively, ≤ 20′, zero intervention** (HB-B 7);
CZ mirror iff a CZ delivery is scheduled (HB-D6), else disposition recorded.

**DONE.** = Global DONE.

## Dependencies & sequencing

- **External-serial:** ⚑HB-3 (Telegram bot + vault seed — Bora) gates P1; the Keycloak/
  provisioning re-runs may need Bora's vault access too — batch them into one P1 window.
- **Shared-cluster coupling:** the Monday-brief fixture + demo-reset are SHARED with the
  Kantheon demo (E-4). Every shared change goes through the standing-fixture scripts;
  joint reset runs are part of P2's DONE. If a Kantheon-demo freeze window is declared,
  all HB cluster mutations pause (architecture §3).
- **SD interplay:** none technically (different surfaces); narratively the close references
  all three demos — final wording at P4.
- **Lane suggestion:** one lane; P1 is the only stage needing cluster/vault privileges.

## Risks & watch items

- **The unprovisioned-instance surprise:** if P0 finds `hebe-dev` was never provisioned
  (pod in CreateContainerConfigError), P1 grows by the full §4.4 runbook — budget it,
  don't absorb it silently.
- **Image-level gap:** cluster hebe predating the P4 constellation features kills the
  spine — P0 stops and flags (an olymp pin bump, Bora-gated).
- **LLM nondeterminism in graded beats:** memory/delegation answers vary in wording;
  oracles grade **facts + source**, never text; rehearsal drills the "wrong fact" abort
  (L0 re-ask once, then L1).
- **Telegram as a live external dependency:** api.telegram.org on show wifi; the L1
  fallback for Beat 1 is a pre-fired delivery already on the phone + the console's
  delivery record as proof; drill it.
- **Deep links on the demo machine:** need the TLS trust from ops-manual §2 done on the
  phone's browser too (tapping the link opens Iris on the phone!) — or the choreography
  moves "open the link" to the desktop; decide + record at P3.S1.
- **Scope magnetism:** approval-gate buttons, SOPs, Slack — all v2; the script sells v1;
  wishes → findings.
