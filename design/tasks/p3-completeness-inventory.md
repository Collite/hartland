# Phase 3 — completeness inventory (Stage 3.0 T1)

> Every actionable item from the prior design, source-line-cited. Feeds the
> [completeness matrix](p3-completeness-matrix.md) (T5), which maps each to an owning task.
> Sources: `demo-transcript.md` (App. A + the six beats' **Requires:** + the four satellites),
> `06-e-cluster-spec.md` (E-3/E-4/E-5), `07-f-script.md` (R0–R5 + L0–L4).
> Compiled 2026-07-18.

`id · source (file §/line) · what it requires · beat/satellite`

## A — Appendix A rollup (the /planning checklist)

| id | source | requires | block |
|---|---|---|---|
| A-repo-1 | transcript §App A:289–293 | hartland agent def | Repo |
| A-repo-2 | " | TTR model, 19 entities (D-5) | Repo |
| A-repo-3 | " | `q.hartland.*` #1–15 (D-2; CASE-sum → new Proteus goldens) | Repo |
| A-repo-4 | " | naming/synonym layer (D-6, D-6a exclusions) | Repo |
| A-repo-5 | " | both Shem overlays (Analytics + Finance, F-1) | Repo |
| A-repo-6 | " | prompts `en/` (+ `cs/`, BM-6) | Repo |
| A-data-1 | §App A:295–298 | seeds S1–S4 (idempotent, hash-keyed) | Data |
| A-data-2 | " | dim display-name UPDATEs (S-7 stores / S-8 warehouses / S-9 reasons) | Data |
| A-data-3 | " | re-run recon → **final demo dump** → `tpcds-staging/hartland/` (S-10) | Data |
| A-clu-1 | §App A:300–304 | fork of bp-dsk | Cluster |
| A-clu-2 | " | pinned MP-4 tags | Cluster |
| A-clu-3 | " | E-3 estate (incl. both golems, prometheus w/ real LLM keys) | Cluster |
| A-clu-4 | " | dedicated warehouse CNPG (S-14), restored from the demo dump | Cluster |
| A-clu-5 | " | `pg-hartland` connection + Kyklop mapping | Cluster |
| A-clu-6 | " | Keycloak demo realm (Maya, Dan) | Cluster |
| A-clu-7 | " | `hartland-query` run-set | Cluster |
| A-clu-8 | " | `demo-reset` recipe + standing fixtures | Cluster |
| A-rdy-1 | §App A:306–307 | E-5 bar 1–7 (06-e) | Readiness |
| A-rdy-2 | " | rehearsal ladder R0–R5 (07-f); R0 fills every ⟨R0⟩ | Readiness |

## B — Beats' `Requires:` lines

| id | source | requires | beat |
|---|---|---|---|
| B1-1 | transcript §Beat1:70–71 | Hebe P4 + routine fixture "Monday channel health brief" (fired pre-show) | 1 |
| B1-2 | " | Iris P4 inbox; envelope-render; queries #1/#2 on `pg-hartland` | 1 |
| B2-1 | §Beat2:138–140 | golem-hartland Shem + model (19 entities); pattern plans #1/#2/#3 | 2 |
| B2-2 | " | free-SQL path + confidence gate; D-6a exclusion enforced | 2 |
| B2-3 | " | chips (Filter/Project/Sort stacks); ChartIntent→Vega-Lite; BlockProvenance | 2 |
| B3-1 | §Beat3:185–187 | Pythia P1–P4 (budget, tree pane via Iris PD-2, conclusion+LooseEnds) | 3 |
| B3-2 | " | HandoffContext (PD-1/PD-4); evidence queries #4/#6/#8/#9/#10/#11/#12/#13 | 3 |
| B3-3 | " | seeds S1–S4 present in the demo dump; Pythia finds Memphis unaided in budget (E-5 #5) | 3 |
| B4-1 | §Beat4:199–200 | Iris P4 artifacts (PD-6): pin w/ provenance + display state; replay-vs-reproduce | 4 |
| B5-1 | §Beat5:227–228 | Metis arc + Pythia P4 S4.2 (Fit/Project/Simulate); Charon P3 | 5 |
| B5-2 | " | NATS/Seaweed/Polars worker on-cluster | 5 |
| B6-1 | §Beat6:242–243 | Hebe P4 create-from-chat; routine reconciled by demo-reset | 6 |

## C — Satellites

| id | source | requires | satellite |
|---|---|---|---|
| G-1 | transcript §SatG:263–266; 07-f §165–177 | `golem-hartland-finance` (`visibility_roles:[kantheon-role-finance]`); Themis visibility-filtered routing | G Governance |
| G-2 | " | Keycloak both personas; Discover contrast (CFO 2 cards / Maya 1) | G Governance |
| G-3 | 07-f §177 | rehearsed "what does Finance see that Maya's doesn't" Q&A | G Governance |
| D-1 | transcript §SatD:268–274; 07-f §183–189 | Analytics DomainCard + its six example-question chips (each a question that worked live) | D Discover |
| S-1 | transcript §If-time:278–279; 07-f §197 | Themis SPLIT decompose → Golem+Pythia one turn (PD-13) | SPLIT |
| ε-1 | transcript §ε:281–283; 07-f §200–208 | throwaway session; in-model→pattern/free-SQL; out-of-model→counter_example gap (delivery locale) | ε coda |
| ε-2 | 07-f §202 | ε go-criteria/protocol (base cut done · ≤27′ · room warm; hard stop 30′) | ε coda |

## D — 06-e E-4 (demo operations)

| id | source | requires | — |
|---|---|---|---|
| E4-1 | 06-e §E-4:36 | `demo-reset` (truncate session state; **preserve** the S-4 standing fixtures + warehouse) | ops |
| E4-2 | 06-e §E-4:37 | pre-show checklist (warm pods, throwaway turns, LLM latency probe, both browser logins) | ops |
| E4-3 | 06-e §E-4:38 | state backup (demo dump + fixture export) | ops |

## E — 06-e E-5 (the demo-ready bar, items 1–7)

| id | source | requires | — |
|---|---|---|---|
| E5-1 | 06-e §E-5:42 | estate green on pinned tags; freeze window declared | bar |
| E5-2 | 06-e §E-5:43 | DB restored; seed sanity r01/r08 (−10..12% H2, 17-week Memphis streak) | bar |
| E5-3 | 06-e §E-5:44 | `ResolveArea` + Shem assembly; every example_question hits a pattern plan via the **full live path** | bar |
| E5-4 | 06-e §E-5:45 | all 15 preferred queries return correct rows live (`hartland-query` run-set) | bar |
| E5-5 | 06-e §E-5:46 | Themis routes scripted beats incl. gap Q; Pythia finds Memphis unaided ≤ budget; Metis forecast w/ intervals | bar |
| E5-6 | 06-e §E-5:47 | both personas log in; visibility contrast (CFO 2 cards, Maya 1; finance routes for CFO, never Maya) | bar |
| E5-7 | 06-e §E-5:48 | `demo-reset` → full arc twice consecutively, zero operator intervention | bar |

## F — 07-f rehearsal ladder R0–R5 + fallbacks L0–L4

| id | source | requires | — |
|---|---|---|---|
| R0 | 07-f §226 | freeze the numbers (⟨placeholders⟩→R0); **sync Shem example_questions verbatim** w/ T-phrasings; new goldens | ladder |
| R1 | 07-f §227 | table read (script only, no cluster); tighten [BORA] lines | ladder |
| R2 | 07-f §228 | beat drills 3× clean each **+ one deliberately broken run per beat** (drill the [FALL] moves) | ladder |
| R3 | 07-f §229 | full stopwatch runs; **capture L2 pins + rehearsal investigation + L4 recording** on the best run | ladder |
| R4 | 07-f §230 | the bar (E-5 #7): `demo-reset` → full arc twice, zero intervention, ≤30′ | ladder |
| R5 | 07-f §231 | freeze-window daily smoke (pre-show + beat 1 + abbreviated beat 3 + teardown) | ladder |
| L0 | 07-f §216 | prevention: freeze + pre-show T-60 + E-5 bar | fallback |
| L1 | 07-f §217 | in-beat retry: verbatim phrasings; chips over typing; one retry then escalate | fallback |
| L2 | 07-f §218 | the **Rehearsal dashboard** (mirror of every key envelope) + the completed rehearsal investigation; survives demo-reset | fallback |
| L3 | 07-f §219 | seams: every beat's entry stands alone; satellites drop silently | fallback |
| L4 | 07-f §220 | full-run screen recording from the final rehearsal, cued on a second machine | fallback |

## Cross-cutting finding (from the Stage 3.1 bring-up, 2026-07-18)

| id | source | finding | — |
|---|---|---|---|
| X-roster | 06-e §E-3:30; s1 T5; s3 T2–T4 | **The E-3 roster + H3 wiring name services by their *pre-rename* names** (theseus/proteus/argos/kyklop/arges/ariadne/echo/kadmos/prometheus). None of those exist as apps on the live bp-dsk/collite-o1/hartland clusters — the constellation was renamed (current apps: dispatch, query, resolver, fuzzy, kallimachos, kleio, veles, llm-gateway, …; survivors: charon/metis/iris/hebe/pythia/themis/golem/capabilities-mcp). **RESOLVED 2026-07-18** — the rename is the read-spine extraction to `tatrman-server` (kantheon-architecture.md §2.b, validated vs the live rosters): theseus→`query`, proteus→`translate`, argos→`validate`, kyklop→`dispatch`, arges→`postgres`(worker), ariadne→`veles`, echo→`fuzzy`, kadmos→`nlp`, prometheus→`llm-gateway`, whois→`identity`. Full mapping + gotchas (argos≠arges; LLM≠monitoring prometheus) in `p3-completeness-matrix.md`. | roster |
