# HB-P2 — Fixtures

> Contracts §3–§4 + §6. TDD: the oracles are written BEFORE the fixtures are seeded.
> Shared-fixture rule (task-mgmt rule 4): `monday-brief` + demo-reset changes go through
> the Kantheon demo's E-4 standing-fixture scripts only.

- [ ] **T1 — Oracles first.** `data/hebe/expected/memory-answers.md`: for each Beat-2
  question (contracts §3), the MUST-contain facts + the fixture file each must trace to —
  Memphis numbers quoted from `data/recon/R0.md` (17 weeks · wks 31–47 · −10.62% incident
  window — cite-check every figure). `data/hebe/expected/deliveries.md`: per routine, the
  channel-message shape (conclusion + artifact count + deep-link pattern) + oracle
  numbers (returns ≈5%-of-revenue baseline; weekly figures from the `hartland-query`
  run-set oracles — reference, don't invent).
- [ ] **T2 — Workspace fixture files.** `data/hebe/workspace/`: `MEMORY.md`, `USER.md`,
  `daily/2026-01-19.md` + 1–2 February notes, per contracts §3 — plausible, dated,
  consistent with the January transcript and the Keycloak persona attributes. Every fact
  a Beat-2 answer needs appears in exactly one obvious place (graders must be able to
  point at the source line).
- [ ] **T3 — Workspace install script.** `data/hebe/seed-workspace.sh` (or `.mjs`):
  writes T2's files through the workspace **write path** (console API / workspace tools —
  never raw SQL; revision semantics must hold). Idempotent: re-run replaces fixture files,
  touches nothing else. Verify via the memory browser + a hybrid-search spot-check
  ("Memphis" returns the conclusion note first).
- [ ] **T4 — Routine fixtures.** `data/hebe/routines/friday-returns.md` (schedule Fri
  16:00 Europe/Prague · `kantheon_question` body wording pinned · delivery Telegram+inbox)
  and `clarify-demo.md` (wording TBD-at-P3, placeholder marked). Install script creates
  them via console/API; `monday-brief` is NOT created here — reconcile T5.
- [ ] **T5 — Monday-brief reconciliation.** Read the E-4 standing-fixture install script
  (Kantheon demo, Stage 3.5 T2 lineage): does its `monday-brief` deliver to Telegram, or
  inbox-only? If inbox-only: extend THAT script (PR to its home) to add the Telegram
  target — do not create a parallel routine. Verify one fire reaches both surfaces.
- [ ] **T6 — HB-R1 reset.** `data/hebe/reset-hebe.sh` per contracts §6: clear sessions/
  drafts/approvals/recent run history · preserve routines, workspace fixtures,
  chat_user_map · **never touch receipts**. Idempotent.
- [ ] **T7 — Joint-reset proof.** Run the Kantheon demo's `demo-reset` (or its manual
  equivalent, ops-manual §7.1) + HB-R1 together: Kantheon preserve-list intact AND hebe
  fixtures intact; nothing double-deleted. Record in `../probes.md` addendum.
- [ ] **T8 — Determinism pass.** seed → oracle spot-checks → HB-R1 → spot-checks again:
  identical. Commit `data/hebe/`; check boxes.

## Verify block

```sh
data/hebe/seed-workspace.sh && data/hebe/reset-hebe.sh && data/hebe/seed-workspace.sh  # idempotent
# memory browser: "Memphis" → conclusion note top hit; routines list shows friday-returns
# joint reset (T7) leaves both demos' fixtures standing
```
