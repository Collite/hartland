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

# GX (NLS-P6.2) — check every mounted `intent.yaml` against the plan-composer placeholder
# contract. The kantheon sibling is `IntentPromptContractSpec`; this repo has no CI lane, and
# an uncontracted placeholder renders EMPTY with nothing anywhere saying so — which is exactly
# how five of six kantheon shem prompts were found serving a question-less prompt.
verify-prompts:
    python3 scripts/verify-intent-prompts.py

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

# ── the simulated price history (IE-P1·S1.5·T0c, IE-C64) ──────────────────────
# ⚑IE-12, ruled by Bora 2026-09-07: *simulate it, with some evolution*. DistrInfo's `Prices` is
# CURRENT market data — one row per ISIN, no series — so IE-C30 values every PAST quarter with
# nothing to read. These two recipes generate the history and write it through the door.
#
# DEMO CONTENT, and it says so: every row is labelled `sourcePluginId: sim-prices` in the journal,
# and the runbook's "what is dummy" list names it (IE-P5·S5.1). The most recent point of every
# series is the provider's real number at its real date — only history is ours.
CTX := "hartland"
NS := "data"
PGPOD := "postgres-1"

# The real anchors: one `Prices` row per instrument the estate has ever held. See scripts/anchors.sql.
price-anchors:
    @kubectl --context {{CTX}} -n {{NS}} exec {{PGPOD}} -c postgres -- \
        psql -U postgres -d entry -tAc "$(cat scripts/anchors.sql)"

# Generate + (optionally) submit. DRY RUN by default; the argument is POSITIONAL:
#
#     just seed-price-history          # dry run — prints what it would write
#     just seed-price-history true     # writes
#
# ⚑ NOT `submit=true`. In just, `name=value` before the recipe sets a VARIABLE; after it, it is
# passed as the positional argument's literal text — so `just seed-price-history submit=true` runs
# a DRY RUN and says so, which is a quiet way to believe you have seeded an estate you have not.
# Needs a bearer for the substrate, which is on `jwks` — the door's service token carries the right
# audience and role (olymp apps/investment-door/README.md), and a port-forward to reach it:
#
#   kubectl --context hartland -n kantheon port-forward svc/entry-substrate 18080:8080 &
#   export ENTRY_BEARER=$(kubectl --context hartland -n kantheon get secret investment-door-entry-token \
#                          -o jsonpath='{.data.DOOR_ENTRY_TOKEN}' | base64 -d)
#   just seed-price-history submit=true
seed-price-history submit="false" from="":
    #!/usr/bin/env bash
    set -euo pipefail
    just price-anchors > /tmp/sim-price-anchors.json
    n=$(python3 -c "import json;print(len(json.load(open('/tmp/sim-price-anchors.json'))))")
    echo "anchors: $n instruments"
    node scripts/seed-price-history.mjs --anchors /tmp/sim-price-anchors.json \
        {{ if from != "" { "--from " + from } else { "" } }} \
        {{ if submit == "true" { "--submit" } else { "" } }}

# The T0c property tests (IE-C64's three, plus the two that make them meaningful). No DB, no network.
verify-price-history:
    node --test scripts/tests/price-history.test.mjs
