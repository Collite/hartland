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
