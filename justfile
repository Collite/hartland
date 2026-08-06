# hartland — local task runner (Phase 2, model verification).
#
# Borrows the sibling tatrman checkout's built toolchain (collite-gh/* convention: repos
# live side by side) rather than vendoring a node_modules of its own — this repo stays
# content-only (BM-9). Pass `cli=` to point at a different tatrman checkout.

# Run the Stage 2.x mocked unit-test suites (node's built-in test runner, no deps).
# find picks up every *.test.mjs under model/, agents/ and lexicon/ — new stages' test
# files are discovered automatically, no glob list to maintain here. (`lexicon/` joined at
# RV-P3.2: the root data area is a third authored surface, and its guards belong in the
# same command as the model's.)
verify-model:
    node --test $(find model agents lexicon -name '*.test.mjs')

# Emit the deterministic resolved-packages.json artifact (packages, entities, areas) via
# the tatrman Modeler CLI — the same tool ai-models uses (`just resolve-packages`).
resolve-packages cli="node ../tatrman/packages/migrate/dist/cli.js":
    {{cli}} resolve-packages "$(pwd)" --out generated/resolved-packages.json --verbose

# Drift check: fail if the committed snapshot is stale.
check-model cli="node ../tatrman/packages/migrate/dist/cli.js":
    {{cli}} resolve-packages "$(pwd)" --check --out generated/resolved-packages.json

# ── lexicon (RV-P3.2) ─────────────────────────────────────────────────────────
# Compile the DECLARED (lexicon/ area + model/lexicon/*.ttrm sugar) and METADATA layers
# into the deterministic `kind: "lexicon"` archive. Kotlin, not Node — the compiler and
# the packer are Kotlin (RV-P1.2's (a3) ruling), so this pair does not share the `cli=`
# default with resolve-packages/check-model above. Same override shape, different binary.
#
# The archive IS committed to generated/, beside resolved-packages.json — same precedent,
# and `check-lexicon` is only a gate if there is something committed to check. Reasoning and
# the size measurement: lexicon/README.md.
build-lexicon cli="../tatrman/packages/kotlin/ttr-lexicon-cli/build/install/ttr-lexicon/bin/ttr-lexicon":
    {{cli}} build "$(pwd)" --out generated/lexicon.tar.zst --verbose

# Drift check: recompile in memory and compare the archive id against generated/. Exits 3
# when stale or absent, mirroring `check-model`. Only meaningful where the archive exists
# (a fresh clone has none) — CI runs `build-lexicon` first.
check-lexicon cli="../tatrman/packages/kotlin/ttr-lexicon-cli/build/install/ttr-lexicon/bin/ttr-lexicon":
    {{cli}} build "$(pwd)" --check --out generated/lexicon.tar.zst
