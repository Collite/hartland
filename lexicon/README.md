# `lexicon/` — hartland's declared lexicon area (RV-36)

The **root-level data area**: alias/value files, grounding trigger files and skill files that
compile into the estate's lexicon archive. Added at RV-P3.2.

This is **one of two surfaces of one DECLARED layer**, not a second area. The other is
`model/lexicon/{cs,en}/*.ttrm` — the TTR-M `def term` sugar Stage 2.5 authored. They sit at
different levels, never collide as paths, and both compile into the same entry table. Neither
gets renamed.

```
lexicon/
├── grounding/hartland.lex.yaml   estate additions to the chrono/money/geo trigger vocabulary
├── tests/area.test.mjs           structural guards (node --test, no dependencies)
└── README.md
```

Build it with `just build-lexicon`; `just check-lexicon` fails when the committed archive is
stale. Both need the sibling tatrman checkout's Kotlin CLI — see the recipes for the `cli=`
override.

## Why the archive is committed

`generated/lexicon.tar.zst` is compressed binary, which is not the usual thing to put in a repo.
It is committed anyway, for two reasons that outweigh it at this size:

- **`--check` is only a gate if there is something committed to check.** Without the artifact in
  the tree, `just check-lexicon` on a fresh clone has nothing to compare against and the drift
  gate is decoration.
- **`resolved-packages.json` set the precedent**, and the reviewable part of this artifact is not
  its bytes but its **id** and per-class counts, both printed by the build and recorded below.

It measured **7,856 bytes** at the counts below. If it grows past roughly a hundred kilobytes the
trade flips and the archive should move to a CI-built artifact — the drift gate would then be a CI
step rather than a local recipe.

## What is in the artifact today

From `just build-lexicon`, 2026-08-06 (rebuilt after RV-P3.4 taught the compiler md targets):

| | |
|---|---|
| archive id | `sha256:e022d94ecb6b7d0acab13146d8978eb6b24000504bb46f7802543e3a328e4632` |
| model id | `sha256:e434903b86466236149298b49039122ed307e701ba113c93ef46de4a838ddabf` |
| entries | **350** |
| — `MODEL_OBJECT` | 117 (60 DECLARED, 57 METADATA) |
| — `MEMBER` | **100** (METADATA — every one an md dimension attribute's `valueLabels`) |
| — `OPERATOR` | 35 (the six stdlib operators' triggers) |
| — `GROUNDING_TRIGGER` | 98 (72 stdlib + 26 from `grounding/hartland.lex.yaml`) |
| operators | 6 |
| build warnings | **0** |
| md-targeted rows | 138 (38 DECLARED + 100 members) |

Those numbers are what `p3-3` verifies a pod is actually serving.

**What changed at RV-P3.4** (was: 212 entries, MEMBER 0, 38 warnings): the compiler's reference
index now covers md, so the estate's measure and dimension vocabulary — *tržba*, *obrat*,
*revenue*, *turnover*, *reklamace*, *vyprodáno*, *produkt*, *sklad* — resolves instead of dangling,
and every `valueLabels` entry on an md dimension attribute (the DC names, the 35 return reasons)
becomes a MEMBER row. All 38 dangling-ref warnings are gone.

⚑ **The target shape is kinded**: `md.measure.revenue`, `md.dimension.Product`, attribute depth
`md.dimension.Customer.state`, member depth `md.dimension.DistributionCentre.dcCode.5`. Addressable
kinds are **measure, dimension (+ attribute/member depth), cubelet**; `domain`, `hierarchy` and
`map` deliberately are not. A ref in any other shape drops its row with a warning and the build
still exits 0 — so read the warning count, not just the exit code.

`lexicon/aliases/` and `lexicon/values/` are now authorable against md targets. They are still
empty: authoring them is `p3-2` T4, which this unblocked.
