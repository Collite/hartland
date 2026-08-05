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

It measured **5,762 bytes** at the counts below. If it grows past roughly a hundred kilobytes the
trade flips and the archive should move to a CI-built artifact — the drift gate would then be a CI
step rather than a local recipe.

## What is in the artifact today

From `just build-lexicon`, 2026-08-06:

| | |
|---|---|
| archive id | `sha256:9422a7bacda4a6e6011bd7845d4b0a32d35c562b50425a2afc978c3d75d82cd5` |
| model id | `sha256:e434903b86466236149298b49039122ed307e701ba113c93ef46de4a838ddabf` |
| entries | **212** |
| — `MODEL_OBJECT` | 79 (22 DECLARED from the channel sugar, 57 METADATA from the model's labels) |
| — `OPERATOR` | 35 (the six stdlib operators' triggers) |
| — `GROUNDING_TRIGGER` | 98 (72 stdlib + 26 from `grounding/hartland.lex.yaml`) |
| — `MEMBER` | **0** — see the gap below |
| operators | 6 |
| build warnings | 38 |

Those numbers are what `p3-3` verifies a pod is actually serving.

## ⚠ The gap: `md.*` targets do not resolve

**38 of the 38 build warnings are `RG-LEXC-001` (dangling ref), and every one of them is an
`md.*` target.** Five distinct refs, covering the whole of `model/lexicon/{cs,en}/measures.ttrm`:

```
md.measure.revenue   md.measure.returnAmount   md.measure.onHandQty
md.dimension.Product   md.dimension.DistributionCentre
```

So the estate's measure and dimension vocabulary — "tržba", "obrat", "revenue", "turnover",
"reklamace", "vyprodáno", "produkt", "sklad" — **compiles to nothing today**, and every member
term would too: all of hartland's `valueLabels` live on md dimension attributes
(`model/md/dimensions.ttrm`, `model/md/product.ttrm`), not on er attributes, which is why the
`MEMBER` count is 0.

This is **not a content problem in this repo**. The compiler builds its reference index from
`ttr-metadata`'s `Model`, which has `db`/`er`/`cnc` schemas and no md schema at all — md
measures, dimensions and cubelets live in a different type (`ttr-semantics`' `MdModel`) that the
lexicon compiler never sees. Nothing hartland can author changes that.

Consequently `lexicon/aliases/` and `lexicon/values/` are **deliberately not authored yet**
(RV-P3.2 T4 is left open with this note). Authoring them against `er.*` targets instead would
point hartland's business vocabulary at the wrong objects and guarantee a duplicate of every term
the moment md refs start resolving — exactly the churn "content is authored once" exists to
prevent.

The contract already anticipates md targets: resolving `contracts.md` §2 shows
`target: md.account.class.expense` as an *"attribute-depth md ref (RV-24 clarification)"*. What is
missing is the implementation, and a ruling on the ref shapes (`md.measure.revenue` — the shape
this estate already uses — versus the `md.<Dimension>.<attribute>[.<member>]` form the contract
example shows).
