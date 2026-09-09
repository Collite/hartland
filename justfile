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
#
# `check-investment-model` runs FIRST and this is the repo's CI lane for it (IE-P2·S2.3·T3):
# `model/investment/` is written by `sync-investment-model` out of kantheon, so a hand-edit there
# is a change to a model whose source of truth is another repository. Nothing else can see one.
verify-model:
    just check-investment-model
    node --test $(find model agents lexicon -name '*.test.mjs')

# The sync's own suite (IE-P2·S2.3·T2) — idempotency, the stamp, and the interpreted-face-only
# rule. Separate from `verify-model` for the same reason `verify-price-history` is: it drives
# `just` in a temp checkout and needs a kantheon beside this one (IE_KANTHEON_DIR overrides).
verify-investment-sync:
    node --test scripts/tests/sync-investment-model.test.mjs

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

# ── the interpreted investment model, synced from kantheon (IE-P2·S2.3, IE-C27) ───────────────
# Source of truth is `kantheon/packages/investment/model/` — one package, two faces (FO-12). Veles
# on hartland serves THIS repo's `model/` and nothing else, so the interpreted face is copied here
# and never hand-edited. `check-investment-model` is what makes "never hand-edited" checkable.
#
# ⛔ FOUR DIRECTORIES, AND NOT ONE MORE. kantheon's package also holds `model/book.ttrm`,
# `model/parties.ttrm`, `model/instruments.ttrm` (the entry face) and `model/entry/` (DDL + apply
# programs). Those three .ttrm files DO NOT PARSE — `model book` is not one of the grammar's model
# codes — and S2.1·D1 measured what a rejected file still costs: the parser recovers past the bad
# directive, keeps the `def entity` declarations underneath under a GUESSED `er` code, and
# `book.ttrm` sorts before `er/book.ttrm`, so `transaction` and `position` resolved to the wrong
# file. Alphabetical order decided which model a consumer was served. Whatever veles's own Kotlin
# loader does with a parse error, it is never handed one from here.
#
# ⛔ AND NO `tests/`. Each of the four directories has one in kantheon, importing a harness that is
# not synced — and `just verify-model` above runs `find model -name '*.test.mjs'`, so a copied test
# tree does not sit inertly, it turns this repo's own model gate red.
INVESTMENT_KINDS := "db er binding queries"

sync-investment-model kantheon="../kantheon" allow_dirty="false":
    #!/usr/bin/env bash
    set -euo pipefail
    src="{{kantheon}}/packages/investment/model"
    [ -d "$src" ] || { echo "no investment package at $src" >&2; exit 2; }
    for kind in {{INVESTMENT_KINDS}}; do
        [ -d "$src/$kind" ] || { echo "$src/$kind is missing — refusing a partial sync" >&2; exit 2; }
    done
    mkdir -p model/investment
    # --delete so a file DELETED in kantheon disappears here; --exclude tests/ per the note above.
    for kind in {{INVESTMENT_KINDS}}; do
        rsync -a --delete --exclude 'tests/' "$src/$kind" model/investment/
    done
    commit=$(git -C "{{kantheon}}" rev-parse HEAD)
    # ⛔ A STAMP THAT NAMES A COMMIT THE CONTENT IS NOT IS WORSE THAN NO STAMP. Caught on this
    # recipe's own first real run: kantheon's working tree carried the S2.3 query rewrites, so the
    # sync copied them and wrote the sha of the commit BEFORE them. `check-investment-model` would
    # then be green over a tree nobody can reproduce from the named commit — the drift check
    # confirming a lie. Refuse, unless the caller says out loud that they mean it.
    dirty=$(git -C "{{kantheon}}" status --porcelain -- packages/investment/model)
    if [ -n "$dirty" ] && [ "{{allow_dirty}}" != "true" ]; then
        echo "kantheon's investment model has uncommitted changes; the stamp would name $commit and carry something else:" >&2
        echo "$dirty" | sed 's|^|  |' >&2
        echo "Commit them there first, or re-run with: just sync-investment-model {{kantheon}} true" >&2
        exit 2
    fi
    [ -n "$dirty" ] && commit="$commit+dirty"
    tree=$(just --justfile "{{justfile()}}" --working-directory "$(pwd)" _investment-tree-sha)
    printf 'source-repo: kantheon\nsource-path: packages/investment/model/{%s}\nsource-commit: %s\nsynced-at: %s\ntree-sha256: %s\n' \
        "$(echo {{INVESTMENT_KINDS}} | tr ' ' ',')" "$commit" "$(date -u +%Y-%m-%d)" "$tree" > model/investment/SYNCED-FROM
    echo "synced $(find model/investment -type f ! -name SYNCED-FROM | wc -l | tr -d ' ') files from kantheon $commit"

# The tree hash the stamp records and `check-investment-model` recomputes. Content AND path, so a
# rename is a change; the stamp itself is excluded or the hash could never match what it contains.
_investment-tree-sha:
    #!/usr/bin/env bash
    set -euo pipefail
    cd model/investment
    find . -type f ! -name SYNCED-FROM -print0 | LC_ALL=C sort -z | xargs -0 shasum -a 256 | shasum -a 256 | cut -d' ' -f1

# Drift check: fail when `model/investment/` no longer matches its stamp. Runs in `verify-model`'s
# lane (this repo has no CI job for the model beyond that recipe).
check-investment-model:
    #!/usr/bin/env bash
    set -euo pipefail
    stamp=model/investment/SYNCED-FROM
    [ -f "$stamp" ] || { echo "$stamp is missing — run \`just sync-investment-model <kantheon>\`" >&2; exit 3; }
    want=$(grep '^tree-sha256: ' "$stamp" | cut -d' ' -f2)
    have=$(just --justfile "{{justfile()}}" --working-directory "$(pwd)" _investment-tree-sha)
    if [ "$want" = "$have" ]; then
        echo "model/investment is in sync with $(grep '^source-commit: ' "$stamp" | cut -d' ' -f2)"
        exit 0
    fi
    echo "model/investment has drifted from its stamp (want $want, have $have)." >&2
    echo "The source of truth is kantheon; edit it THERE and re-sync. Files that differ:" >&2
    # Name the files, not just the tree — a bare hash mismatch tells an operator nothing about what
    # to put back. Re-sync into a scratch copy and diff against it.
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    src=$(grep '^source-commit: ' "$stamp" | cut -d' ' -f2)
    if [ -d "${IE_KANTHEON_DIR:-../kantheon}/packages/investment/model" ]; then
        mkdir -p "$tmp/model"
        just --justfile "{{justfile()}}" --working-directory "$tmp" sync-investment-model "$(cd "${IE_KANTHEON_DIR:-../kantheon}" && pwd)" >/dev/null
        diff -rq model/investment "$tmp/model/investment" 2>&1 | grep -v SYNCED-FROM | sed 's|^|  |' >&2 || true
    else
        (cd model/investment && find . -type f ! -name SYNCED-FROM | sed 's|^\./|  |') >&2
        echo "  (no kantheon checkout at ${IE_KANTHEON_DIR:-../kantheon} — listing the whole tree instead of the diff)" >&2
    fi
    echo "stamped source commit: $src" >&2
    exit 3
