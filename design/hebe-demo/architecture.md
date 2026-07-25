# HB — Hebe demo on Hartland · Architecture

> **Effort HB** (Hebe demo), planned 2026-07-23. Third member of the Hartland demo family
> (Kantheon demo · SD Studio demo · this). *Consumes, never reopens*: the Hebe design corpus
> (`project/kantheon/design/hebe/` — features, architecture, v1-specs), the **Hebe
> integration arc** (`project/kantheon/implementation/v1/hebe/plan.md`, P1–P4 →
> `hebe/v0.4.0`), the Kantheon-demo corpus (this repo `design/`), and the hartland cluster
> overlay (`olymp/clusters/hartland/apps/hebe/values.yaml`). Demo assets live **here**
> (BM-9). Companions: [`00-demo-narrative.md`](./00-demo-narrative.md) ·
> [`contracts.md`](./contracts.md) · [`plan.md`](./plan.md) · [`tasks/`](./tasks/).

## 1. What is being built

A runnable, resettable **Hebe capability demo** on the Hartland story — the personal-agent
plane. Deliverable families:

1. **The bound instance** — the cluster Hebe (`dev` on hartland, k8s profile) provisioned,
   **bound to Maya** (Keycloak OBO bound user + Telegram `chat_user_map`), console
   reachable, registered `non_routable` (contracts §2–§4).
2. **Fixtures** — the seeded workspace/memory (Maya's January notes), the two routines
   (Monday brief — already a Kantheon-demo standing fixture — + Friday returns summary),
   delivery templates, and the HB extension of `demo-reset` (contracts §5–§6).
3. **The beats** — choreography + beat sheets for phone/memory/delegation/routines/
   hand-back/governance (narrative Beats 1–6), each with oracle-pinned expected outputs.
4. **Script + readiness** — transcript, quirks file, rehearsal ladder, dry-run bar
   (plan HB-P4).

**Not in this effort:** any Hebe product change (defects → kantheon repo issues, the SD-D2
discipline); v2 features (SOPs, Slack/email channels, inline-button approvals, OTP) — the
script sells v1 truthfully; the `personal`-profile offline-tolerance story (outbox/catch-up
— it is real and demo-worthy but **cluster k8s profile doesn't exercise it**; recorded as a
possible local-profile pocket, ⚑HB-5); multi-instance fleets.

## 2. The demo estate

```
 Phone (Maya's Telegram)          Presenter browser
      ▲ deliver / ▼ chat            │ console + Iris
      │                             ▼
  api.telegram.org ◄── egress ── hartland cluster ──────────────────────────┐
                                  │                                          │
                          hebe `dev` (ns kantheon, k8s profile)              │
                          web console :8765 (⚑HB-2 route/pf)                 │
                          ├─ workspace/memory/receipts → central PG          │
                          │    (schema hebe_dev; pgvector hybrid search)     │
                          ├─ LLM → llm-gateway.ttr-server:7280 /v1           │
                          │    (Bearer ttrk-…, X-Cost-Center hebe/dev)       │
                          ├─ identity → Keycloak realm kantheon              │
                          │    (client-credentials→OBO, bound user = maya)   │
                          ├─ registry → capabilities-mcp (non_routable)      │
                          └─ constellation → iris-bff :7410 (headless client)│
                                   │  TurnOrigin.SCHEDULED, OBO bearer       │
                                   ▼                                         │
                          Themis → golem-hartland → …spine… → hartland_us ───┘
```

Everything except the Telegram egress and the console access already exists on the cluster
(deployed via olymp; `hebe-dev` instance secret provisioned by `just hebe-provision dev` —
**live state unverified → HB-P0 probe**).

## 3. Runtime home (Bora: "preferably cluster" — so: cluster, with a named fallback)

- **Primary — cluster Hebe** (`dev` on hartland). Real k8s profile, real gateway, real
  Keycloak, real PG — the strongest "this is deployed software" story, and Beats 0/3/6
  (non_routable, OBO, posture, cost) are only *true* there.
- **Fallback — local Hebe** (`hebe run`, local/server profile on the presenter machine)
  — exists so a cluster regression days before a show doesn't kill the demo. Fallback
  covers Beats 1/2/4/5 (memory, routines, Telegram) but **loses** the OBO/posture/cost
  beats in their honest form; the script marks which lines survive the fallback. Kept
  cheap: one HB-P4 task proves the fallback boots and runs Beat 2, nothing more.
- **Freeze discipline:** every cluster-touching change (console route, chat-map config,
  provisioning re-runs) is an olymp/values PR and is **barred inside a Kantheon-demo
  freeze window** — same rule as SD variant C. HB shares the cluster with the standing
  Kantheon demo; the standing fixtures (E-4) own demo-reset semantics — HB *extends*,
  never breaks them (contracts §6).

## 4. Decisions

- **HB-D1 · Cluster-first, local fallback** (§3; per Bora's "preferably cluster").
- **HB-D2 · One instance, bound to Maya.** Reuse the standing `dev` instance rather than
  provisioning a second (`hebe-maya`) — one pod fits the shrunken node, the Kantheon-demo
  Monday-brief fixture already lives there, and "Dan gets his own" is *narrated*, not
  deployed (the rejection beat proves the boundary better than a second pod would).
  Revisit only if ⚑HB-1 overrules.
- **HB-D3 · The demo consumes hebe/v0.4.0 as shipped.** The integration arc's P4 demo
  (cron-fired Golem question → Telegram, runbook + screencap) is this demo's kernel —
  HB stages it on hartland and builds the surrounding beats. Defects → kantheon issues;
  honest-degradation variants otherwise (SD-D2 discipline, inherited).
- **HB-D4 · The phone is a doorbell, not a dashboard.** No charts in Telegram (v1 rule)
  is *featured*, not apologized for — conclusion + deep link; provenance lives in Iris.
- **HB-D5 · Memory is seeded, not faked.** Maya's workspace fixtures are plausible
  artifacts of the January/February story (investigation conclusion note, promo decision,
  preferences) written as real workspace markdown — the memory beat then runs live search
  over them. Every remembered "fact" traces to a fixture file the audience could be shown.
- **HB-D6 · EN delivery** (BM-8 inherited); the CZ mirror is a conditional HB-P4 task.
- **HB-D7 · Effort prefix HB**; on-stage vocabulary: "Hebe", "routine", "receipt",
  "workspace/memory", "the console" — no profile/axis/module names spoken.

## 5. Flags for Bora (defaults let P0 start now)

- **HB-⚑1 · Instance:** keep `dev` bound to Maya (default, HB-D2) — or a fresh `maya`
  instance (cleaner story, more cluster work: appset entry + provisioning + secret)?
- **HB-⚑2 · Console exposure:** HTTPRoute `hebe.20-218-224-115.nip.io` via olymp (default
  — it's a stage surface; console auth per the console_auth axis) — or presenter-machine
  port-forward (zero cluster change, one more pre-show moving part)?
- **HB-⚑3 · Telegram:** Bora creates the demo bot (BotFather), seeds the token into the
  vault for the `hebe-dev` secret; whose Telegram account plays Maya on stage (Bora's?),
  and is a second account available for the Beat-6 rejection cameo?
- **HB-⚑4 · Governance beat scope:** all three strikes (posture refusal · receipts verify
  · stranger rejection) in the main script (default), or trimmed to receipts-only?
- **HB-⚑5 · Offline-tolerance pocket:** show the `personal`-profile outbox/catch-up story
  as a local-machine pocket (extra build), or leave it as one spoken line (default)?
