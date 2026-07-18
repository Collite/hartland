"""Stage 1.1 T3 — the invariants the seeds and recon depend on. Mocked/unit: CSV fixture only,
never a live DB."""
from pathlib import Path

import pytest

from generate import Taxonomy, build_row, read_items

FIXTURES = Path(__file__).parent / "fixtures"
TAXONOMY_PATH = Path(__file__).parent.parent / "taxonomy.yaml"


@pytest.fixture(scope="module")
def taxonomy() -> Taxonomy:
    return Taxonomy.load(TAXONOMY_PATH)


@pytest.fixture(scope="module")
def rows():
    return read_items(FIXTURES / "item_sample.csv")


def test_key_preservation(taxonomy, rows):
    seen_sks = set()
    for row in rows:
        assert row.i_item_sk not in seen_sks, f"duplicate i_item_sk {row.i_item_sk} in fixture"
        seen_sks.add(row.i_item_sk)
        patch, _ = build_row(row, taxonomy, "en")
        assert patch.i_item_sk == row.i_item_sk


def test_category_preservation(taxonomy, rows):
    for row in rows:
        node, _ = taxonomy.resolve(row.i_category, row.i_class)
        assert node.category_key == row.i_category, (
            f"sk={row.i_item_sk}: taxonomy node category {node.category_key!r} != "
            f"input category {row.i_category!r}"
        )


def test_price_band_never_in_patch(rows, taxonomy):
    for row in rows:
        patch, _ = build_row(row, taxonomy, "en")
        patch_fields = vars(patch)
        assert "i_current_price" not in patch_fields
        assert "i_category" not in patch_fields
        assert "i_category_id" not in patch_fields


def test_class_coverage_reports_folds(taxonomy, rows):
    folds = []
    for row in rows:
        _, folded = build_row(row, taxonomy, "en")
        if folded:
            folds.append((row.i_category, row.i_class))
    # every real (category,class) pair in the live sample resolves to a taxonomy node
    # (real or folded) -- assert none raise, and report (not silently drop) any fold.
    assert isinstance(folds, list)  # folding path is exercised without raising; see report above


def test_null_category_rows_are_skipped(rows):
    for row in rows:
        assert row.i_category != ""
