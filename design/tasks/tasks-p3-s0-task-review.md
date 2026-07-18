# Stage 3.0 — Task-completeness review (the sign-off gate before H2+)

> **Phase 3, Stage 3.0.** Plans: [`../plan-demo-build.md`](../plan-demo-build.md) (§ Stage 3.0) ·
> [`../test-fixture-hartland-replan.md`](../test-fixture-hartland-replan.md) ·
> `olymp/clusters/hartland/plan-cluster.md`. Decisions:
> [`../08-czech-mirror-and-catalog-delta.md`](../08-czech-mirror-and-catalog-delta.md).
> Design sources to sweep: `demo-transcript.md` (Appendix A rollup + the satellites), `06-e-cluster-spec.md`
> (E-3/E-4/E-5), `07-f-script.md` (R0–R5 + fallbacks L0–L4).
>
> **Goal:** nothing from the prior design is dropped before the dry run. Produce the **requirement→owning-task
> matrix** — the Phase-3 entry doc — and get Bora's sign-off. Repos touched: none (this is a paper stage —
> it *reads* [O][H][K] artifacts and edits the plan/task docs where orphans are found).

## Depends on

- **Phases 1 + 2 task lists exist** (P1 `tasks-p1-*`, P2 `tasks-p2-*`) and the Phase-3 stage files 3.1–3.5.
- Read access to `demo-transcript.md`, `06-e-cluster-spec.md`, `07-f-script.md`, `05-d-ttrm-spec.md`,
  the control-room log, and `test-fixture-hartland-replan.md`.

## Pre-flight

- [ ] Stage 3.0 branch (docs-only): `feat/p3-s0-task-review`.
- [ ] All P1/P2/P3 task-list files present in `tasks/` (this stage cross-checks against them).
- [ ] The BM decisions are all resolved (they are — 2026-07-18); no design gate remains, only completeness.

## Tasks

- [ ] **T1 — Inventory every actionable item across the prior design.**
  Enumerate, verbatim source-line-cited, into `tasks/p3-completeness-inventory.md`:
  - **`demo-transcript.md` Appendix A** — the four rollup blocks: **Repo** (agent def, TTR model, `q.hartland.*`
    #1–15, naming/synonym layer, both Shem overlays, prompts), **Data** (seeds S1–S4, dim display-name UPDATEs,
    recon, demo dump), **Cluster** (fork, pins, E-3 estate, warehouse CNPG, `pg-hartland` conn + Kyklop map,
    Keycloak realm, `hartland-query` run-set, `demo-reset` + fixtures), **Readiness** (E-5 1–7, R0–R5).
  - Each Beat's **Requires:** line (Beats 1–6) + the **satellites**: **G** (governance cameo — golem-hartland-finance
    visibility contrast, CFO 2 cards / Maya 1), **D** (Discover closer — DomainCard + 6 example-question chips),
    **SPLIT** (Themis decompose, Golem+Pythia one turn — PD-13), **ε coda** (throwaway-session live audience Q, F-2).
  - **`06-e` E-4** (demo-reset, pre-show checklist, state backup) + **E-5 items 1–7**.
  - **`07-f`** R0–R5 rehearsal ladder + fallbacks **L0–L4** (esp. **L2** pinned Rehearsal investigation/dashboard,
    **L4** recording capture).
  Each row: `id · source (file §/line) · what it requires · beat/satellite`.

- [ ] **T2 — Cross-check each item against the Phase 1/2/3 stages; list orphans.**
  For every inventory row, find its owning task (`tasks-pN-sM ... Tx`) and record it. Rows with **no owner** are
  **orphans**. Expected candidates to scrutinize (they cut across the phase boundary and are easy to drop):
  - the **cs mirror of 07-f / transcript** (BM-8 — only if a CZ delivery is planned; owned by **Stage 3.5 T5**);
  - the **CZ personas** (Markéta Nováková + CZ CFO — Q-BM-4a; owned by **Stage 3.3 T5**) vs Maya/Dan;
  - **golem-hartland-finance** visibility contrast for **both** persona sets (satellite G);
  - the **ε coda** counter_example gap over the *delivery locale* (does a cs counter_example exist? — Phase 2 2.6);
  - **L4 recording** capture on-cluster (Stage 3.5) and **L2** pinned Rehearsal fixtures (Stage 3.2/3.5);
  - the **BM-10 repoints** (SV-P4 S5/S7, nightly contexts) — cross-referenced, not re-authored (Stage 3.4 + overview).

- [ ] **T3 — Fold orphans into the right stage (or a `plan-cluster.md` [O] task); record the mapping.**
  For each orphan: either (a) add a task/sub-bullet to the correct P3 stage file here, or (b) if it is an olymp
  `[O]` bring-up detail, add it to `olymp/clusters/hartland/plan-cluster.md` and note the pointer. Every fold is
  logged in the inventory (`orphan-id → resolution`). **No orphan is closed by assertion** — each gets a concrete home.

- [ ] **T4 — Confirm the standing fixtures are each owned by a task.**
  The demo depends on **standing** state that survives `demo-reset` (E-4/S-4). Verify each has an install-owner and a
  preserve-owner:
  - **"Channel Health"** dashboard (Beat 4 pins) · **"Rehearsal"** fallback dashboard + its **pinned rehearsal
    investigation** (07-f L2) · the **"Monday channel health brief"** Hebe routine (Beat 1/6) · **Keycloak users**
    (both persona sets) · the **warehouse** (read-only, never dirtied).
  Map each to its install task (**Stage 3.5 T2** standing-fixture install) and its preserve clause (**Stage 3.5 T1**
  demo-reset allow-list). Flag any fixture that has an install owner but no `demo-reset` preserve clause (a demo-killer).

- [ ] **T5 — Produce the completeness matrix (requirement → owning task) as the Phase-3 entry doc.**
  Write `tasks/p3-completeness-matrix.md`: a table `requirement · source · owning task(s) · status
  (owned/folded/cross-ref/N-A) · notes`. Group by beat/satellite/E-4/E-5/07-f. Cross-ref rows (SV-P4 S5/S7, the
  nightly repoints) are marked `cross-ref` with the server-corpus path, not `owned`. This matrix is the artifact the
  rest of Phase 3 is checked against; link it from `tasks-p3-overview.md`.

- [ ] **T6 — Sign-off checkpoint with Bora before H2+ starts.**
  Present the matrix + the orphan-resolution log. Bora's sign-off = the gate: **Stage 3.1 may already be in flight
  (fork/trim/pin is orphan-independent), but Stage 3.2+ (H2+) does not proceed until the matrix is all-green or
  every amber has an accepted disposition.** Record the sign-off (date + any Bora dispositions) at the head of the
  matrix and in the effort STATUS.md.

## DONE bar

- [ ] Inventory (T1) covers Appendix A + all six beats' Requires + all four satellites + E-4 + E-5 1–7 + 07-f
      R0–R5/L0–L4, each source-line-cited.
- [ ] Every inventory row maps to an owning task, a folded task, or an accepted cross-ref/N-A (no silent orphans).
- [ ] Standing fixtures (T4) each have an install owner **and** a `demo-reset` preserve clause.
- [ ] `p3-completeness-matrix.md` published and linked from the overview; **Bora sign-off recorded** → H2+ unblocked.

## Verify block

```sh
# every inventory row resolves to an owner (no blank owner column):
grep -nE '^\|' tasks/p3-completeness-matrix.md | grep -viE 'owned|folded|cross-ref|N-A' | grep -v 'owning task'   # expect empty
# the four satellites are each present in the matrix:
for s in "Governance" "Discover" "SPLIT" "coda"; do grep -q "$s" tasks/p3-completeness-matrix.md || echo "MISSING: $s"; done
# each standing fixture named in both install + preserve context:
for f in "Channel Health" "Rehearsal" "Monday channel health"; do
  grep -c "$f" tasks/p3-completeness-matrix.md; done   # each ≥ 1
grep -qi "Bora sign-off" tasks/p3-completeness-matrix.md   # the gate is recorded
```
