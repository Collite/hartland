#!/usr/bin/env python3
"""Check every mounted `intent.yaml` against the GX placeholder contract.

Hartland has no CI lane, and that is exactly why this exists as a file rather than as a
one-off command in a task list: the same check on the kantheon side found that five of six
shipped shem prompts were pre-v2 files naming placeholders `PlanComposer.buildVars` has never
supplied — every one of them rendering EMPTY, with nothing anywhere saying so. These prompts
are mounted into a live estate and can drift the same way.

The kantheon sibling is `IntentPromptContractSpec`; the contract is
`project/kantheon/features/golem-prompt-context/contracts.md` §2 (placeholders) and §8 (header).

Usage:  python3 scripts/verify-intent-prompts.py        # from the repo root
Exit:   0 = every file conforms, 1 = at least one finding (printed).
"""
from __future__ import annotations

import pathlib
import re
import sys

# GX contracts §2 — the eight a prompt author may name.
CONTRACT_KEYS = {
    "question",
    "locale",
    "prior_view",
    "annotated_question",
    "lexicon_hints",
    "normalized_question",
    "queries",
    "entities",
}

# The three GX-5 slots. Present in the `user:` half is what makes a file actually GX-shaped.
GX_SLOTS = {"annotated_question", "lexicon_hints", "normalized_question"}

# ⚑GXP-D3 — supplied for one deprecation window, WARNed by the composer. Legal in a mounted
# estate prompt, and a finding here anyway: these files are edited alongside the contract.
DEPRECATED_ALIASES = {"patterns", "schema", "bindings"}

PLACEHOLDER = re.compile(r"\{\{\s*(\w+)\s*}}")
HEADER_FIRST_LINE = re.compile(r"^# intent — .+")


def halves(text: str) -> tuple[str, str]:
    """`system:` and `user:` as raw text. A dumb split, deliberately: pulling in a YAML parser
    for two top-level block scalars would add a dependency to a check that has none."""
    system_at = text.index("\nsystem:")
    user_at = text.index("\nuser:")
    return text[system_at:user_at], text[user_at:]


def check(path: pathlib.Path) -> list[str]:
    text = path.read_text(encoding="utf-8")
    findings: list[str] = []

    first = text.splitlines()[0]
    if not HEADER_FIRST_LINE.match(first):
        findings.append(f"header: first line is not `# intent — …` (got: {first!r})")

    header = "\n".join(line for line in text.splitlines() if line.startswith("#"))
    undocumented = sorted(k for k in CONTRACT_KEYS if k not in header)
    if undocumented:
        findings.append(f"header: does not document {undocumented} (S-3: it is the only docs)")

    try:
        system, user = halves(text)
    except ValueError:
        return findings + ["structure: no `system:` / `user:` halves"]

    named = set(PLACEHOLDER.findall(system + user))
    uncontracted = sorted(named - CONTRACT_KEYS - DEPRECATED_ALIASES)
    if uncontracted:
        findings.append(f"placeholders: {uncontracted} are filled by nothing — they render EMPTY")

    deprecated = sorted(named & DEPRECATED_ALIASES)
    if deprecated:
        findings.append(f"placeholders: {deprecated} are deprecated (⚑GXP-D3) and log a WARN")

    missing = sorted(GX_SLOTS - set(PLACEHOLDER.findall(user)))
    if missing:
        findings.append(f"user half: missing the GX slots {missing}")

    return findings


def main() -> int:
    root = pathlib.Path(__file__).resolve().parent.parent
    files = sorted(root.glob("agents/golem/shems/*/prompts/*/intent.yaml"))
    if not files:
        print("no intent.yaml found under agents/golem/shems — wrong working directory?")
        return 1

    failed = 0
    for path in files:
        rel = path.relative_to(root)
        findings = check(path)
        if findings:
            failed += 1
            print(f"✗ {rel}")
            for finding in findings:
                print(f"    {finding}")
        else:
            print(f"✓ {rel}")

    print(f"\n{len(files) - failed}/{len(files)} conform to the GX placeholder contract")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
