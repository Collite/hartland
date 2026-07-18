"""Stage 1.4 T2 — mirror integrity: every i_item_sk present in both worlds maps to the same
taxonomy node (class_key from mirror-map.csv), localized text only differs by locale. Reads the
exported item CSVs from both live DBs (paths passed via env vars) -- integration-flavoured
verification, not a mocked unit test, per the stage's own framing."""
import csv
import os
from pathlib import Path

import pytest

MIRROR_MAP = Path(__file__).parent.parent / "mirror-map.csv"


def _load_mirror_map():
    with MIRROR_MAP.open(encoding="utf-8") as f:
        return {row["i_item_sk"]: row for row in csv.DictReader(f)}


def _load_items(path):
    # i_brand/i_class are fixed-width character(N) columns -- \copy exports them padded.
    with open(path, encoding="utf-8") as f:
        return {row[0]: {"i_brand": row[1].strip(), "i_class": row[2].strip()} for row in csv.reader(f)}


@pytest.mark.skipif(
    "US_ITEMS_CSV" not in os.environ or "CZ_ITEMS_CSV" not in os.environ,
    reason="requires US_ITEMS_CSV / CZ_ITEMS_CSV env vars pointing at exported item CSVs from live DBs",
)
def test_mirror_same_node_across_worlds():
    mirror = _load_mirror_map()
    us_items = _load_items(os.environ["US_ITEMS_CSV"])
    cz_items = _load_items(os.environ["CZ_ITEMS_CSV"])

    assert set(us_items) == set(cz_items), "item_sk population differs between worlds"

    mismatches = []
    for sk in us_items:
        node = mirror.get(sk)
        if node is None:
            mismatches.append((sk, "not in mirror-map.csv"))
            continue
        us_brand_key = node["brand_key"]
        # the mirror-map's brand_key is the en brand name, which IS i_brand verbatim in the US world
        if us_items[sk]["i_brand"] != us_brand_key:
            mismatches.append((sk, f"us brand {us_items[sk]['i_brand']!r} != mirror brand_key {us_brand_key!r}"))

    assert not mismatches[:10], f"{len(mismatches)} mismatches, first 10: {mismatches[:10]}"
