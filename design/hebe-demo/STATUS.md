---
effort: HB — Hebe demo on Hartland (personal-agent plane, cluster Hebe)
repo_home: Collite/hartland/design/hebe-demo
code_home: [Collite/hartland (data/hebe fixtures, rig-hb, beats), olymp (values/route/secret PRs), kantheon (consumed read-only at hebe/v0.4.0)]
state: planned
phase: corpus authored 2026-07-23; partial HB-P0 probed 2026-07-27 (probes.md) — HB-P1 found BLOCKED on unwritten kantheon P4 wiring
next: Bora — rule HB-⚑1…5 (⚑3 Telegram bot still the earliest hard gate) + NEW ⚑ on token-exchange:v1 (probes.md §2) + NEW ⚑ on the inbox carrier for scheduled briefs (inbox-beat1.md §5) · finish the HB-P0 rows left unprobed (no cluster mutation)
blocked_on: ["HB-P1 BLOCKED: the P4 constellation client is not wired in kantheon — IrisBffClient + ClientCredentialsExchangeGrant are defined and unit-tested but never constructed in production (probes.md §1)", "Keycloak legacy token-exchange:v1 disabled + no hebe realm client (probes.md §2)", "HB-⚑3 Telegram bot + vault seed (gates P1, not P0)", "HB-⚑1/2/4/5 verdicts (defaults recorded)"]
gates: ["cluster mutations via olymp PRs only; barred inside any Kantheon-demo freeze window", "Monday-brief fixture + demo-reset SHARED with the Kantheon demo — changes only via the E-4 standing-fixture scripts", "SD-D2 discipline inherited: product defects → kantheon issues, never patched in the demo"]
updated: 2026-07-27
stream: dev
lane: unassigned (one lane; P1 needs cluster/vault privileges)
---

The third Hartland demo: **Hebe, Maya's personal agent, on the hartland cluster** —
the plane the January demo showed for only two beats. Arc: phone brief with deep link
(doorbell-not-dashboard, HB-D4) → memory that traces to readable workspace fixtures
(HB-D5) → delegation through the platform door *as Maya* (OBO) → routines from a sentence
→ the AWAITING_AGENT hand-back → governance strikes (posture refusal · receipted chain
verify · stranger rejection · metered cost). Single-user by design; registered
`non_routable` — "the platform can't even route to her."

Cluster-first, local fallback (HB-D1, per Bora); instance = the standing `dev` bound to
Maya (HB-D2, pending ⚑1); consumes `hebe/v0.4.0` as shipped (HB-D3).

Corpus: [`00-demo-narrative.md`](./00-demo-narrative.md) · [`architecture.md`](./architecture.md)
· [`contracts.md`](./contracts.md) (instance table §2 · fixtures §3–4 · HB-R1/R2 reset ·
HB-B bar) · [`plan.md`](./plan.md) (HB-P0…P4) · [`probes.md`](./probes.md) (partial HB-P0: the live
cluster truth + the two blockers behind HB-P1) · [`inbox-beat1.md`](./inbox-beat1.md) (why the
Kantheon demo's Beat-1 inbox item is Hebe's to deliver, and the unmade carrier decision it
turns on) · [`tasks/00-task-management.md`](./tasks/00-task-management.md).
