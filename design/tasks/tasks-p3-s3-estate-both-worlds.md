# Stage 3.3 — Estate wired for both worlds  (= plan-cluster **H3**, extended)

> **Phase 3, Stage 3.3.** Plans: [`../plan-demo-build.md`](../plan-demo-build.md) (§ Stage 3.3) ·
> [`../test-fixture-hartland-replan.md`](../test-fixture-hartland-replan.md) · **`olymp/clusters/hartland/plan-cluster.md`**
> (Phase **H3** — H3.1 platform wiring, H3.2 agents + personas). Decisions:
> [`../08-czech-mirror-and-catalog-delta.md`](../08-czech-mirror-and-catalog-delta.md) (**BM-2** two connections,
> **BM-6** second Kyklop map + cs prompt bundle + CZ personas, **Q-BM-4a** new CZ personas). Design:
> `06-e-cluster-spec.md` **E-3**; `demo-transcript.md` satellite **G** (governance) + **D** (Discover); F-1/S-13.
>
> **Goal:** the constellation answers over **either world through one model** — model served from `Collite/hartland`,
> **two** Arges connections + **two** Kyklop mappings, **both** Shems registered, **both** persona sets in Keycloak,
> the **cs prompt bundle** mounted. **Repo: [O] olymp** (wiring); the model + Shems + prompts are **[H] Phase-2
> artifacts, consumed** here (Ariadne source = `Collite/hartland`).
>
> **SV-P4 cross-ref:** the live hartland model + `hartland_cz` this stage serves is the **reference model** that
> **SV-P4 · S5** (`.../tasks-sv-p4-s5-golem-conformance.md` T5) authors its conformance core tier against
> (Czech-diacritic fuzzy match, `tržba/obrat`, CZK grounding, cs `valueLabels`) — `test-fixture-hartland-replan.md` §2.2.

## Depends on

- **Stage 3.2 DONE** — both DBs serve read-only on the hartland CNPG (the connections need a live warehouse).
- **G2 — `Collite/hartland` populated** (Phase 2 done): `model/` loads clean + resolves against both connections;
  both Shems assemble with en+cs `example_questions`; `q.hartland.*` #1–15 present.
- **G4 — constellation waves proven on bp-dsk** (themis/pythia wave 4, hebe wave 6, Iris-P4, Metis/Charon) — the
  DONE bar depends on these; **G1** (pins) for the DONE bar's "pinned tags" clause.

## Pre-flight

- [ ] Stage 3.3 branch: `feat/p3-s3-estate-both-worlds`.
- [ ] Shape to mirror: `olymp/test-contexts/tpcds-query/{arges,kyklop,ariadne}.values.yaml` (the connection-wiring
      pattern — Arges `extraEnv` REPLACES the chart default array, so Proteus is restated alongside the DB wiring).
- [ ] The `pg-hartland-{us,cz}-ro-cred` secrets land in the `kantheon` app ns on the hartland cluster (Stage 3.2 T3 CES).
- [ ] Phase-2 `model/` resolves `ResolveArea("hartland")` against **both** `pg-hartland-us` and `pg-hartland-cz` offline.

## Tasks

> **⚠ RECONCILE SERVICE NAMES FIRST (Stage 3.0 X-roster).** T1–T4 below name apps/services by
> their **pre-rename** identities — `ariadne` (model resolve), `arges` (DB connection), `kyklop`
> (world map), `proteus`, `prometheus` (LLM provider). The live constellation was renamed (e.g.
> the LLM provider is now `llm-gateway`; see the current rosters in `p3-completeness-matrix.md`
> X-roster). Map each to its **current** app dir + values path (`clusters/hartland/apps/<name>/`)
> and the current env-var names before editing values. The wiring *shape* here (two connections,
> two Kyklop maps, real LLM keys) is unchanged — only the service/app names need updating.

- [ ] **T1 — Ariadne model Git source = `Collite/hartland` (H3.1 T1; resolve Q-9).**
  Point Ariadne at the `Collite/hartland` repo (`model/` folder) as its model Git source in
  `clusters/hartland/apps/ariadne/values.yaml`. Add the ArgoCD/Ariadne **repo credential** for the private
  `Collite/hartland`. Resolve **Q-9** here: verify single- vs multi-source support; the kantheon in-repo `tpcds`
  seed stays the *integration fixture* and is NOT served on this cluster. Confirm `ResolveArea("hartland")` loads
  the db/er/md/binding/lexicon stack (en + cs) at startup.

- [ ] **T2 — TWO Arges connections (H3.2 Δ — BM-2).**
  In `clusters/hartland/apps/arges/values.yaml`, restate `extraEnv` (it **replaces** the chart default array, so
  Proteus must be restated too — see the tpcds-query arges values) with **both** connections, read-only, no tenant
  envelope (mirrors `pg-tpcds`):
  ```yaml
  extraEnv:
    - { name: PROTEUS_SERVER, value: "proteus" }
    - { name: PROTEUS_SERVER_GRPC_PORT, value: "7276" }
    # pg-hartland-us (USD)
    - { name: ARGES_PG_HARTLAND_US_HOST, value: "hartland-pg-rw.data.svc.cluster.local" }
    - { name: ARGES_PG_HARTLAND_US_USER, value: "hartland_us_readonly" }
    - name: ARGES_PG_HARTLAND_US_PASSWORD
      valueFrom: { secretKeyRef: { name: pg-hartland-us-ro-cred, key: password } }
    # pg-hartland-cz (CZK)
    - { name: ARGES_PG_HARTLAND_CZ_HOST, value: "hartland-pg-rw.data.svc.cluster.local" }
    - { name: ARGES_PG_HARTLAND_CZ_USER, value: "hartland_cz_readonly" }
    - name: ARGES_PG_HARTLAND_CZ_PASSWORD
      valueFrom: { secretKeyRef: { name: pg-hartland-cz-ro-cred, key: password } }
  ```
  Both DBs live on the same CNPG (Q-BM-3a), so the host is shared; the role/db differ per connection.

- [ ] **T3 — TWO Kyklop `world.table-connections` mappings (H3.1 T3 Δ — BM-6).**
  In `clusters/hartland/apps/kyklop/values.yaml`, map the **same** hartland model tables → `pg-hartland-us` **and**
  → `pg-hartland-cz` (the star is currency-agnostic; the Money measure's unit resolves per connection — USD on us,
  CZK on cz, BM-2). Verify each mapping resolves the full table set (facts + used dims) with no dangling table.

- [ ] **T4 — Register both Shems + platform deps live (H3.1 T4/T5, H3.2 T1/T2).**
  - `clusters/hartland/golems/golem-hartland.json` + `golem-hartland-finance.json` (the dynamic golems
    ApplicationSet, GI-5 — ConfigMap-fed Shems, **no image rebuild**). Both carry en+cs `example_questions`;
    finance = `visibility_roles: [kantheon-role-finance]` (F-1).
  - **Prometheus with REAL LLM provider keys** via ExternalSecrets (E-3 — the demo answers live; WireMock is for
    tests). Wire the latency/reachability probe into the pre-show check (Stage 3.5).
  - Pythia deps live: NATS JetStream, SeaweedFS, Polars worker, charon (+mcp), metis (+mcp); themis, pythia, hebe,
    iris + iris-bff at **Iris-P4 scope** (inbox, artifacts/pins, discover, feedback) — values per bp-dsk with hartland
    deltas; **pinned tags (G1)**.

- [ ] **T5 — Keycloak personas — both worlds (H3.2 T3 Δ — Q-BM-4a).**
  Realm-as-code additions to the hartland demo realm:
  - **US:** *Maya Chen* `maya@hartland.example` (`kantheon-area-hartland`) + *Dan Whitaker* `cfo@hartland.example`
    (`kantheon-area-hartland` + `kantheon-role-finance`) — F-1/S-13.
  - **CZ (new, Q-BM-4a):** *Markéta Nováková* (Senior Category Manager, `kantheon-area-hartland`) + a **CZ CFO**
    (`kantheon-area-hartland` + `kantheon-role-finance`).
  The delivery locale picks its persona set (BM-8, one-locale-per-delivery); both sets are demo-ready.

- [ ] **T6 — Mount the cs prompt bundle (H3.2 Δ — BM-6).**
  Mount the Shem's **cs prompt bundle** (`agents/golem/shems/prompts/cs/`, previously "unused per FI-4", now in
  scope) alongside `prompts/en/` on the hartland golem overlay (ConfigMap or golem `shem.configMapName` per the
  golem-erp pattern; prompts otherwise fall back to the image classpath). A CZ delivery routes through the cs bundle.

- [ ] **T7 — Registration + resolution check (H3.2 T4 — E-5 items 3+6, both worlds).**
  Verify `ResolveArea("hartland")` green; both Shems **assemble + register + route**; **Discover** shows **two**
  cards for the CFO persona, **one** for the category manager (satellite G, E-5 item 6). Then the DONE-bar resolution:
  ```sh
  # every example_question of both Shems hits a pattern plan through the FULL live path:
  # theseus → proteus → argos → kyklop → arges → pg-hartland-{us|cz}
  # en example_questions over pg-hartland-us ; cs example_questions over pg-hartland-cz
  ```
  Persona visibility contrast: the finance agent routes for the CFO, **never** for the category manager (F-1).

## DONE bar (plan-cluster H3, extended — E-5 items 3+6)

- [ ] **Every `example_question`** of both Shems resolves to a pattern plan through the **full live path** on **both**
      connections — **en over `pg-hartland-us`, cs over `pg-hartland-cz`**.
- [ ] Both Kyklop mappings resolve the full table set; the Money measure renders USD on us, CZK on cz (same measure).
- [ ] Both persona sets log in; **visibility contrast holds** (CFO: two DomainCards; category manager: one; finance
      agent routes for the CFO only).
- [ ] cs prompt bundle mounted; estate on **pinned tags** (G1); Prometheus answering with **real** provider keys.

## Verify block

```sh
# area + Shems assemble and register:
kubectl --context hartland -n kantheon exec deploy/ariadne -- curl -s localhost:8080/resolve/hartland | grep -q '"status":"Ready"'
# both connections advertised by Arges (its /ready gates on the pools):
kubectl --context hartland -n kantheon exec deploy/arges -- curl -s localhost:8080/ready | grep -Eo 'pg-hartland-(us|cz)'   # both
# Discover card contrast (rehearsed): CFO=2, category manager=1
# (assert via iris-bff /discover as each persona bearer)
```
