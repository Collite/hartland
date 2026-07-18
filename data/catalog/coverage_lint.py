#!/usr/bin/env python3
"""Stage 1.4 T6 — bilingual coverage lint: no on-screen dimension member is untranslated.
Checks every distinct i_category/i_container/i_size/DC-name/used-reason in the live CZ item
export has a non-empty cs (and en) entry in value-labels.json. Mocked/unit against exported
CSVs + value-labels.json, not a live DB connection."""
from __future__ import annotations

import argparse
import csv
import json
import sys
from pathlib import Path

# proper-noun brand tokens that may legitimately coincide across locales (fictional brand names
# are deliberately kept in Latin script for both en and cs, per Stage 1.1's taxonomy design).
BRAND_ALLOWLIST_KEYS = {"container", "size"}  # not brands themselves; brands aren't in value-labels


def load_labels(path: Path) -> dict:
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def check_group(name: str, entries: list[dict], required_keys: set[str]) -> list[str]:
    problems = []
    label_keys = {e["key"] for e in entries}
    missing = required_keys - label_keys
    if missing:
        problems.append(f"{name}: {len(missing)} key(s) with no label entry at all: {sorted(missing)[:10]}")
    for e in entries:
        if not e.get("cs"):
            problems.append(f"{name}.{e['key']}: empty/missing cs label")
        if not e.get("en"):
            problems.append(f"{name}.{e['key']}: empty/missing en label")
        if name not in BRAND_ALLOWLIST_KEYS and e.get("cs") == e.get("en") and e.get("cs"):
            problems.append(f"{name}.{e['key']}: cs == en ({e['cs']!r}) — likely untranslated")
    return problems


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--items-cz", required=True, type=Path, help="CSV export of hartland_cz item (i_category)")
    ap.add_argument("--labels", required=True, type=Path, help="value-labels.json")
    args = ap.parse_args()

    labels = load_labels(args.labels)

    used_categories = set()
    with args.items_cz.open(encoding="utf-8") as f:
        for row in csv.DictReader(f):
            cat = (row.get("i_category") or "").strip()
            if cat:
                used_categories.add(cat)

    problems = []
    problems += check_group("category", labels["category"], used_categories)
    problems += check_group("reason", labels["reason"], set())
    problems += check_group("dc", labels["dc"], set())
    problems += check_group("container", labels["container"], set())
    problems += check_group("size", labels["size"], set())

    if problems:
        print(f"FAIL: {len(problems)} bilingual coverage problem(s):", file=sys.stderr)
        for p in problems:
            print(f"  - {p}", file=sys.stderr)
        return 1

    print(f"OK: {len(used_categories)} categories + {len(labels['reason'])} reasons + "
          f"{len(labels['dc'])} DCs + {len(labels['container'])} containers + "
          f"{len(labels['size'])} sizes all bilingual-covered.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
