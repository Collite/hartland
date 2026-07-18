# model — the Hartland TTR-M model

One model set (BM-2/BM-5), served over `pg-hartland-us` (USD) and `pg-hartland-cz` (CZK).

- `db/` — `model db`: the physical TPC-DS subset (facts + used dims), types, PK/FK.
- `er/` — `model er` + `er2db` binding: the 19 curated entities + relationships (05-d/D-5).
- `md/` — `model md` + `md2db`/`md2er` binding: the ROLAP star (cubelets, measures, conformed
  dimensions incl. the Product hierarchy Category→Class→Brand→Manufacturer→Item).
- `lexicon/` — `model lexicon locale en` + `locale cs`: the bilingual naming layer + valueLabels.
- `queries/` — the `q.hartland.*` preferred queries (#1–15, D-2).
- `binding/` — cross-model mapping: `er2db` (Stage 2.2) + `md2db` (Stage 2.4) `.ttrm` files.
- `connections.toml` — the two connection descriptors (`pg-hartland-us`/`pg-hartland-cz`).
  **Not a TTR-M construct** (the grammar has no `connection` def and no per-connection
  currency `unit` — verified against `packages/grammar/src/TTR.g4`): this is a repo-level
  descriptor Ariadne/Arges consumes at deploy time (Phase 3, plan-cluster.md H3). Both
  connections point at the *same* physical model (`modeler.toml`'s `[schemas.dbo]` handle) —
  the two databases are schema-identical (Phase 1); currency is a display fact carried by
  the lexicon locale (Stage 2.5), not a structural difference. "Loads clean and resolves
  against both connections" (the Phase 2 DONE bar) therefore means: the one model parses
  and resolves clean, and both connection descriptors target the identical schema — the
  live per-world round-trip is Phase 3 H3, not a Phase 2 blocker.

**Verify:** `just verify-model` (mocked parse/resolution unit tests, no live DB) and
`just resolve-packages` / `just check-model` (the tatrman Modeler CLI's deterministic
`resolved-packages.json`, same tool `ai-models` uses) — both run from the repo root,
borrowing the sibling `tatrman` checkout's built toolchain rather than vendoring one here.

**Packaging (Stage 2.2 finding — read before adding a new model/*.ttrm file):** the BM-9
tree groups files by model kind (`db/`, `er/`, `md/`, ...), which would normally give each
subfolder its own directory-inferred package, forcing an `import` in nearly every
cross-kind binding. Instead, **every model/*.ttrm file declares `package hartland`
explicitly** (first line, after any file-level comment), collapsing the whole model into
one flat package — same-package refs (`db.dbo.*`, `er.entity.*`) need no import anywhere.
`modeler.toml`'s `[packages] layout = "off"` suppresses the resulting intentional
directory/declaration mismatch; verified this doesn't block resolution (zero
`ttr/unresolved-reference` project-wide). One residual, accepted, non-blocking diagnostic
remains on every file — `ttr/package-prefix-divergence` — documented in `modeler.toml`.
**Also:** `date` is a reserved grammar keyword — don't use it as a bare attribute name
(hit this on `date_dim`/`inventory`; used `cal_date`/`as_of_date` instead). Entity-level
`aliases:` is deprecated (`ttr/lexicon-legacy-aliases`) — declare a lexicon `term` instead
(Stage 2.5). New accepted-residual diagnostic codes go in
`model/tests/project-harness.mjs`'s `ACCEPTED_RESIDUAL_CODES` (shared across every stage's
test file, not copy-pasted per file).

**MD calendar (Stage 2.3 finding):** the v1 calc-map catalog (`docs/features/md/map-
catalog.md`) ships `yearOfDate` as an EXTRACTION straight from `Day`, not a `Quarter->Year`
ROLL-UP (no such entry ships in v1 — only `quarterOfMonth` does). So `model/md/calendar.ttrm`
declares **three** hierarchies sharing the `day` leaf (`calendarMonthly`: day→month→quarter,
`calendarYearly`: day→year, `calendarWeekly`: day→week) rather than one Day→Month→Quarter→Year
chain — the pattern `docs/manual/en/15-md-model.md`'s own hierarchy section sanctions ("a
second hierarchy sharing the day leaf"). The MD "dot-path" drill notation
(`product.electronics.<class>`) named in the Stage 2.3 task list is unimplemented design-stage
sugar (`docs/features/md/dot-path-sugar.md`: "brainstorm output... Not yet a contract") — the
mocked test suite checks hierarchy-level resolution through the real resolver instead.
