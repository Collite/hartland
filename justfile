# hartland — local task runner (Phase 2, model verification).
#
# Borrows the sibling tatrman checkout's built toolchain (collite-gh/* convention: repos
# live side by side) rather than vendoring a node_modules of its own — this repo stays
# content-only (BM-9). Pass `cli=` to point at a different tatrman checkout.

# Run the Stage 2.x mocked unit-test suites (node's built-in test runner, no deps).
# find picks up every *.test.mjs under model/ and agents/ — new stages' test files are
# discovered automatically, no glob list to maintain here.
verify-model:
    node --test $(find model agents -name '*.test.mjs')

# Emit the deterministic resolved-packages.json artifact (packages, entities, areas) via
# the tatrman Modeler CLI — the same tool ai-models uses (`just resolve-packages`).
resolve-packages cli="node ../tatrman/packages/migrate/dist/cli.js":
    {{cli}} resolve-packages "$(pwd)" --out generated/resolved-packages.json --verbose

# Drift check: fail if the committed snapshot is stale.
check-model cli="node ../tatrman/packages/migrate/dist/cli.js":
    {{cli}} resolve-packages "$(pwd)" --check --out generated/resolved-packages.json
