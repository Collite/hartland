# `lexicon/` — hartland's declared lexicon area (RV-36)

The **root-level data area**: alias/value files, grounding trigger files and skill files that
compile into the estate's lexicon archive. Added at RV-P3.2.

This is **one of two surfaces of one DECLARED layer**, not a second area. The other is
`model/lexicon/{cs,en}/*.ttrm` — the TTR-M `def term` sugar Stage 2.5 authored. They sit at
different levels, never collide as paths, and both compile into the same entry table. Neither
gets renamed.

```
lexicon/
├── aliases/hartland.lex.yaml     the estate's words for model OBJECTS (measures,
│                                 dimensions, attributes, cubelets)
├── values/hartland.lex.yaml      the estate's words for member CODES
├── grounding/hartland.lex.yaml   estate additions to the chrono/money/geo trigger vocabulary
├── tests/area.test.mjs           structural guards (node --test, no dependencies)
└── README.md
```

Each data file's own header carries its sourcing — which line of `design/demo-transcript.md`,
which `search { patterns }` block in `model/queries/q_hartland.ttrm`, which
`example_questions` roster a term came from — plus the terms it deliberately does **not**
declare, and why. Read those before adding a word.

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

It measured **8,845 bytes** at the counts below. If it grows past roughly a hundred kilobytes the
trade flips and the archive should move to a CI-built artifact — the drift gate would then be a CI
step rather than a local recipe.

## What is in the artifact today

From `just build-lexicon`, 2026-08-06 (rebuilt after RV-P3.2 T4 authored the alias/value area):

| | |
|---|---|
| archive id | `sha256:2f1d28e1004da7f7c397f34b76482c7d2c54728751dec8ed10772341d8f560b3` |
| model id | `sha256:e434903b86466236149298b49039122ed307e701ba113c93ef46de4a838ddabf` |
| entries | **423** |
| — `MODEL_OBJECT` | 178 (121 DECLARED, 57 METADATA) |
| — `MEMBER` | **112** (12 DECLARED, 100 METADATA `valueLabels`) |
| — `OPERATOR` | 35 (the six stdlib operators' triggers) |
| — `GROUNDING_TRIGGER` | 98 (72 stdlib + 26 from `grounding/hartland.lex.yaml`) |
| operators | 6 |
| build warnings | **0** |
| md-targeted rows | 211 |

Those numbers are what `p3-3` verifies a pod is actually serving.

**What changed at RV-P3.2 T4** (was: 350 entries, MODEL_OBJECT 117, MEMBER 100): `aliases/` and
`values/` were authored, adding **73 rows** — 61 objects and 12 members. The vocabulary that
arrived is the half the `.ttrm` sugar surface never covered: orders and quantities, the Customer,
Promotion and ReturnReason dimensions, the category/state/age attributes the demo slices by, the
inventory cubelet, and the five distribution centres by bare name.

**What changed at RV-P3.4** (was: 212 entries, MEMBER 0, 38 warnings): the compiler's reference
index learned md, so the estate's measure and dimension vocabulary — *tržba*, *obrat*, *revenue*,
*turnover*, *reklamace*, *vyprodáno*, *produkt*, *sklad* — resolves instead of dangling, and every
`valueLabels` entry on an md dimension attribute (the DC names, the 35 return reasons) becomes a
MEMBER row. All 38 dangling-ref warnings are gone.

⚑ **The target shape is kinded**: `md.measure.revenue`, `md.dimension.Product`, attribute depth
`md.dimension.Customer.state`, member depth `md.dimension.DistributionCentre.dcCode.5`. Addressable
kinds are **measure, dimension (+ attribute/member depth), cubelet**; `domain`, `hierarchy` and
`map` deliberately are not. A ref in any other shape drops its row with a warning and the build
still exits 0 — so read the warning count, not just the exit code.

## Adding a word

1. Check it is not already declared — `model/lexicon/{cs,en}/*.ttrm` is the other surface of the
   same layer, and `just verify-model`'s T4 guard fails the build if you restate one of its forms.
2. Put it in the file that matches what it names: `aliases/` for an object, `values/` for a member
   code, `grounding/` for a chrono/money/geo trigger.
3. Name the corpus line it came from in the block comment. Every term in this area is attested in
   `design/demo-transcript.md`, `model/queries/q_hartland.ttrm`, a Shem's `example_questions` or
   `data/recon/R0.md` — that discipline is what keeps the estate's vocabulary the users' and not
   the author's.
4. Watch the method. Short codes and proper nouns take `EXACT` (a one-edit neighbourhood around a
   short name reaches its siblings — this estate has both `Brno` and `Reno` as distribution
   centres); anything at or below three characters cannot fire `typos` at all (⚑M-4).
5. `just build-lexicon`, then re-record the id and counts above. **Read the warning count**, and
   commit the rebuilt archive with the change.
