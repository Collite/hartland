# Phase 3 — completeness matrix (Stage 3.0 T5) — the Phase-3 entry doc

> The artifact the rest of Phase 3 is checked against. Every requirement from
> [`p3-completeness-inventory.md`](p3-completeness-inventory.md) mapped to an owning task,
> with status. Grouped by block/beat/satellite/E-4/E-5/ladder.
>
> **Status legend:** `owned` (a task owns it, may be done) · `folded` (was an orphan; a home was
> added — see the resolution log) · `cross-ref` (a pre-flight gate or another repo's asset, not
> owned in this build) · `N-A` (dispositioned as not-applicable) · `amber` (owned but blocked on a
> reconcile before its stage can execute).

## Bora sign-off

- **✅ SIGNED OFF — Bora, 2026-07-18. Matrix ALL-GREEN → H2+ (Stages 3.2+) UNBLOCKED.**
- Zero ambers (X-roster resolved + validated against the live rosters 2026-07-18). Every
  requirement is `owned` / `folded` / `cross-ref` / `N-A`. The two folds (rehearsal ladder
  R1–R3 → S3.5 T8; SPLIT probe → S3.4 T6) accepted. No dispositions required.

## Matrix

### A — Appendix A rollup

| requirement | source | owning task(s) | status | notes |
|---|---|---|---|---|
| A-repo-1..6 agent def / model / #1–15 / lexicon / both Shems / prompts en+cs | transcript App A | **P2 S2.1–2.6** | owned ✓done | Phase 2 complete (`demo-p2`); md star fully bound |
| A-data-1 seeds S1–S4 | App A | **P1 S1.2, S1.5** | owned ✓done | Memphis (us) + Brno (cz) |
| A-data-2 dim display names S-7/S-8/S-9 | App A | **P1 S1.2 (naming-us), S1.3 (geo/DCs/reasons)** | owned ✓done | |
| A-data-3 recon → demo dump → staging | App A | **P1 S1.6** | owned ✓done | dumps in `tpcds-staging/hartland/{us,cz}/` |
| A-clu-1 fork of bp-dsk | App A | **P3 S3.1** | owned ✓done | forked **collite-o1** (correct tenant; see s1 note) |
| A-clu-2 pinned MP-4 tags | App A | **P3 S3.1 T6 / S3.5 T4** | owned (deferred) | bring-up on `:testing`; pin-flip = G1 @ 3.5 |
| A-clu-3 E-3 estate | App A | **P3 S3.1 T5 + S3.3 T4** | owned | names reconciled (X-roster resolved); trim deferred as footprint-only |
| A-clu-4 warehouse CNPG (S-14) | App A | **P3 S3.2** | owned | |
| A-clu-5 `pg-hartland` conn + Kyklop map | App A | **P3 S3.3 T2/T3** | owned | reconciled: `arges`→**postgres** (conn), `kyklop`→**dispatch** (map) |
| A-clu-6 Keycloak realm (Maya, Dan) | App A | **P3 S3.3 T5** | owned | + CZ personas (Q-BM-4a) |
| A-clu-7 `hartland-query` run-set | App A | **P3 S3.4** | owned | |
| A-clu-8 demo-reset + fixtures | App A | **P3 S3.5 T1/T2** | owned | |
| A-rdy-1 E-5 1–7 | App A | **P3 S3.5 T6** | owned | |
| A-rdy-2 R0–R5 | App A | see **ladder** below | mixed | R1–R3 folded (see log) |

### B — Beats

| requirement | source | owning task(s) | status | notes |
|---|---|---|---|---|
| B1-1 Hebe routine "Monday brief" fired pre-show | Beat1 | **S3.5 T2 (install) + T3 (fire) + S3.3 T4 (hebe)** | owned | standing fixture |
| B1-2 Iris P4 inbox; envelope-render; #1/#2 | Beat1 | **S3.3 T4 (iris) + P2 (queries)** | owned | |
| B2-1 golem-hartland Shem + model; #1/#2/#3 | Beat2 | **S3.3 T4 + P2** | owned | |
| B2-2 free-SQL path + gate | Beat2 | **G4 (constellation)** | cross-ref | platform capability, proven on bp-dsk |
| B2-2 D-6a exclusion enforced | Beat2 | **P2 (model)** | owned ✓done | no profit path (test-enforced) |
| B2-3 chips / ChartIntent→Vega-Lite / BlockProvenance | Beat2 | **G4 (constellation)** | cross-ref | Iris/Proteus/Golem features |
| B3-1 Pythia P1–P4 (budget, tree pane, conclusion+LooseEnds) | Beat3 | **S3.3 T4 + G4** | owned/cross-ref | |
| B3-2 HandoffContext; evidence #4/#6/#8/#9/#10/#11/#12/#13 | Beat3 | **G4 (HandoffContext) + P2 (queries)** | owned/cross-ref | |
| B3-3 seeds in dump; Pythia finds Memphis unaided ≤budget | Beat3 | **P1 (seeds) + S3.4 T6 / S3.5 T6 (E-5 #5)** | owned | |
| B4-1 Iris pin w/ provenance; replay-vs-reproduce | Beat4 | **G4 + S3.5 T2 (Channel Health dashboard)** | owned/cross-ref | |
| B5-1 Metis Fit/Project/Simulate; Charon | Beat5 | **S3.3 T4 (deps) + G4** | owned/cross-ref | |
| B5-2 NATS/Seaweed/Polars worker on-cluster | Beat5 | **S3.3 T4** | owned | up on the cluster (S3.1) |
| B6-1 Hebe create-from-chat; routine reconciled by reset | Beat6 | **G4 + S3.5 T1** | owned/cross-ref | |

### C — Satellites (G Governance · D Discover · SPLIT · ε coda)

| requirement | source | owning task(s) | status | notes |
|---|---|---|---|---|
| G-1 finance Shem + visibility-filtered routing | SatG | **S3.3 T4 + T7** | owned ✓(Shem done P2) | |
| G-2 both personas; Discover contrast (CFO 2 / Maya 1) | SatG | **S3.3 T5 + T7; E5-6** | owned | contrast verified for the **delivered locale's** persona set |
| G-3 rehearsed "what does Finance see" Q&A + frozen narration | SatG / 07-f §177,240 | **folded → S3.5 (R-ladder)** | folded | narration lines frozen during R2/R3 |
| D-1 Discover DomainCard + 6 chips (each a live question) | SatD | **S3.3 T7 + P2 (6 example_questions)** | owned ✓(P2) | |
| S-1 Themis SPLIT decompose (PD-13) | SPLIT | **S3.5 T7 (dry-run) + G4**; **folded → S3.4 T6 probe** | folded | was: exercised only in the dry-run; added a demo-check probe |
| ε-1 throwaway session; in/out-of-model; counter_example gap | ε | **S3.5 T7 + P2 (counter_examples en+cs)** | owned ✓ | cs counter_example ("zisková marže") exists (P2 verified) |
| ε-2 go-criteria/protocol | ε | **07-f script + S3.5 T7** | owned | |

### D — 06-e E-4 / E-5

| requirement | source | owning task(s) | status | notes |
|---|---|---|---|---|
| E4-1 demo-reset (preserve fixtures + warehouse) | E-4 | **S3.5 T1** | owned | preserve list cross-checked (T4 below) |
| E4-2 pre-show checklist | E-4 | **S3.5 T3** | owned | |
| E4-3 state backup (dump + fixture export) | E-4 | **S3.5 T2** | owned | |
| E5-1 estate green on pins; freeze declared | E-5 | **S3.5 T6 (+ S3.1/S3.5 T4)** | owned | |
| E5-2 DB restored; seed sanity | E-5 | **S3.2 T6 → S3.5 T6** | owned | |
| E5-3 ResolveArea + Shems + full-live-path | E-5 | **S3.3 T7 → S3.5 T6** | owned | |
| E5-4 15 queries return rows live | E-5 | **S3.4 T6 → S3.5 T6** | owned | |
| E5-5 routing / RCA / forecast probes | E-5 | **S3.4 T6 → S3.5 T6** | owned | SPLIT probe added (see S-1) |
| E5-6 persona visibility contrast | E-5 | **S3.3 T7 → S3.5 T6** | owned | |
| E5-7 twice-unaided arc | E-5 | **S3.5 T7** | owned | the phase exit criterion |

### E — 07-f rehearsal ladder & fallbacks

| requirement | source | owning task(s) | status | notes |
|---|---|---|---|---|
| R0 freeze numbers; **sync example_questions verbatim**; goldens | 07-f §226 | **P1 S1.6 (R0) + P2 S2.6 (example_qs) + P2 S2.6 T2 (goldens, cross-ref)** | owned ✓ | example_questions match the 07-f T-phrasings (spot-verified this review) |
| R1 table read | 07-f §227 | **folded → S3.5** | folded | |
| R2 beat drills **+ per-beat broken run ([FALL]/L1 drills)** | 07-f §228 | **folded → S3.5** | folded | the substantive gap — the fallback moves had no drill owner |
| R3 stopwatch full runs; capture L2/L4 artifacts | 07-f §229 | **folded → S3.5** (capture already in **S3.5 T7**) | folded | |
| R4 the bar (E-5 #7) | 07-f §230 | **S3.5 T7** | owned | |
| R5 freeze-window daily smoke | 07-f §231 | **S3.4 T6 (demo-check) + S3.5 T4 (freeze)** | owned | |
| L0 prevention | 07-f §216 | **S3.5 T3/T4 + E-5** | owned | |
| L1 in-beat retry (verbatim; chips) | 07-f §217 | **folded → S3.5 (R2 drills)** | folded | |
| L2 Rehearsal dashboard + rehearsal investigation | 07-f §218 | install **S3.5 T2**; preserve **S3.5 T1**; capture **S3.5 T7** | owned | |
| L3 seams | 07-f §219 | **07-f script (design property)** | N-A | no task — a property of the written arc |
| L4 recording (second machine) | 07-f §220 | capture **S3.5 T7** | owned | second-machine cue = presenter ops (noted in T7) |

### Cross-refs (server corpus / other repos — not owned here)

| requirement | source | pointer | status |
|---|---|---|---|
| SV-P4 · S5 conformance core → hartland model / `hartland_cz` | replan §2.2 | `project/server/design-corpus/implementation/tasks/tasks-sv-p4-s5-golem-conformance.md` T5 | cross-ref (wired live by S3.3/S3.4) |
| SV-P4 · S7 outsider dry run → collite-o1 + `hartland-pg` | replan | `.../tasks-sv-p4-s7-dry-run.md` T1/T2 | cross-ref (scratch host = S3.2 collite-o1 overlay) |
| nightly repoints (`bp-dsk-run-set.txt`, `integration-nightly.yml`) | replan §2.1 | kantheon [K] | cross-ref (owned in S3.4 T5) |
| new Proteus goldens (CASE-sum / md-derived) | D-2 | kantheon `tests/conformance` | cross-ref (referenced P2 S2.6 T2; **still open**) |

## T4 — standing-fixture install/preserve audit

Every fixture that survives `demo-reset` has **both** an install owner and a preserve clause — no
install-without-preserve (a demo-killer). All green:

| fixture | install owner | preserve owner |
|---|---|---|
| "Channel Health" dashboard | **S3.5 T2** | **S3.5 T1** (allow-list) |
| "Rehearsal" dashboard + pinned rehearsal investigation | **S3.5 T2** | **S3.5 T1** |
| "Monday channel health brief" Hebe routine | **S3.5 T2** (+ fired **T3**) | **S3.5 T1** |
| Keycloak users (both persona sets) | **S3.3 T5** | **S3.5 T1** |
| warehouse (read-only, never dirtied) | **S3.2** (restore) | **S3.5 T1** (never touch `hartland-pg`) |

## X-roster — RESOLVED (2026-07-18)

The E-3 roster + H3 wiring named services by their **pre-rename** identities. The rename is the
**read-spine extraction to the open-source `tatrman-server` repo** (2026-07, SV-P0/P1), deployed via
olymp under **functional** app names. **Source:** `kantheon/docs/architecture/kantheon-architecture.md`
§2.b + kantheon `CLAUDE.md` §2/§9 (doc dated 2026-07-11). **Validated:** every "current app" below
**exists as a deployed app** on the live bp-dsk / collite-o1 / hartland rosters (checked 2026-07-18) —
the doc is current, not stale.

| E-3 / demo name (old) | **current olymp app** | tatrman-server service | role |
|---|---|---|---|
| theseus (+mcp) | **query** (+ `query-mcp`) | ttr-query | query orchestrator (the OBO data-path edge) |
| proteus | **translate** | ttr-translate | lang ↔ RelNode ↔ SQL translator |
| argos | **validate** | ttr-validate | validator + RLS (roles from the bearer) |
| kyklop | **dispatch** | ttr-dispatch | worker dispatcher (`world.table-connections`) |
| **arges** | **postgres** | ttr-worker-postgres | ⚠ the Postgres **worker** that holds the `pg-hartland` connection + executes — **NOT** `argos`/validate |
| ariadne (+mcp) | **veles** (+ `veles-mcp`) | Veles | model graph/metadata; serves model+prompts (**Ariadne model Git source → the `veles` app**) |
| echo | **fuzzy** (+ `fuzzy-mcp`) | ttr-fuzzy | Czech-aware fuzzy matcher |
| kadmos | **nlp** (+ `nlp-mcp`) | ttr-nlp | NLP foundation (Python) |
| **prometheus** (real LLM keys) | **llm-gateway** | ttr-llm-gateway | ⚠ the **LLM gateway** — **NOT** the monitoring Prometheus (`platform/monitoring/prometheus`, stays) |
| brontes | **mssql** | ttr-worker-mssql | MSSQL worker — **OUT** for the demo (nothing routes to MSSQL) |
| steropes | **polars** | ttr-worker-polars | Polars worker — **IN** (Beat 5 Metis/forecast needs it, contra E-3's "if a dep surfaces") |
| whois | **identity** | ttr-identity | user/role directory (Argos role source = bearer default → off the hot path) |
| capabilities-mcp · charon(+mcp) · metis(+mcp) · iris · iris-bff · themis(+mcp) · pythia · golem · hebe · report-renderer · landing · health | **unchanged** | stay in kantheon | survivors (persona names kept) |

**Two gotchas the reconcile must respect** (both flagged inline above): (1) **argos vs arges** — the
demo substrate chain `theseus→proteus→argos→kyklop→arges` has *both*: `argos`→**validate** (validator)
and `arges`→**postgres** (the PG worker that carries the `ARGES_PG_HARTLAND_*` connection env). (2)
**two Prometheis** — E-3's "prometheus with real LLM keys" is the LLM gateway → **`llm-gateway`**; the
metrics Prometheus is a separate monitoring component that stays.

**One residual to confirm at S3.3 (not blocking):** the live rosters show both a `resolver` app and
`themis-mcp` — Themis is "the Resolver post-extraction", so the routing agent is likely deployed as
`resolver` with `themis-mcp` as its wrapper; confirm the app dir when wiring. Also: the live clusters
carry extra non-demo services (`kallimachos`/`pinakes`/`kleio` = DocWH; `grounding-mcp`/`chrono`/`geo`/
`money`) that the S3.1 trim removes — not part of the demo E-3.

## Orphan-resolution log (T3)

No orphan closed by assertion — each got a concrete home:

1. **X-roster (was amber → RESOLVED, see the section above).** Old→new mapping established from
   `kantheon-architecture.md` §2.b and **validated against the live cluster rosters**. Folded the
   concrete names into `tasks-p3-s1-fork-foundation.md` T5 (trim against current app names) and
   `tasks-p3-s3-estate-both-worlds.md` T1–T4 (wire `veles`/`postgres`/`dispatch`/`validate`/
   `translate`/`query`/`llm-gateway`). No longer blocks H2+; the S3.1 trim stays deferred only as a
   footprint optimization (full roster runs, 64 GB fits it).
2. **R1/R2/R3 rehearsal ladder (orphan → folded).** The ladder up to the dry-run had no owning
   task — critically **R2's per-beat "broken run" [FALL] drills** (the L1/L2/L4 fallback moves) and
   R3's stopwatch runs. **Resolution:** folded a new **T8 (rehearsal ladder R1–R3)** into
   `tasks-p3-s5-dry-run-readiness.md` (drives R1 table-read → R2 beat+[FALL] drills → R3 full runs,
   capturing L2/L4 en route to the T7 dry-run; also freezes the G-3 / LooseEnds narration lines).
3. **S-1 SPLIT (thin spot → folded).** Themis SPLIT (PD-13) was exercised **only** inside the S3.5 T7
   dry-run, with no earlier verification. **Resolution:** folded a SPLIT probe into
   `tasks-p3-s4-run-set-repoint.md` T6's `just demo-check` E-5-item-5 probe set.
