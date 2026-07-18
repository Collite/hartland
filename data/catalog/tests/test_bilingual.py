"""Stage 1.1 T4/T6 — bilingual rendering + coverage + hero-surfacing unit tests."""
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


def test_bilingual_coverage_no_null_or_empty(taxonomy, rows):
    for row in rows:
        for locale in ("en", "cs"):
            patch, _ = build_row(row, taxonomy, locale)
            for field in ("i_product_name", "i_brand", "i_manufact", "i_size", "i_container"):
                value = getattr(patch, field)
                assert value is not None
                assert value != "", f"sk={row.i_item_sk} locale={locale} field={field} is empty"


def test_mirror_property_same_node_across_locales(taxonomy, rows):
    for row in rows:
        p_en, _ = build_row(row, taxonomy, "en")
        p_cs, _ = build_row(row, taxonomy, "cs")
        assert p_en.class_key == p_cs.class_key
        assert p_en.brand_key == p_cs.brand_key
        assert p_en.container_key == p_cs.container_key
        assert p_en.size_key == p_cs.size_key


def test_czech_diacritics_survive_utf8_roundtrip(taxonomy, rows):
    diacritic_chars = set("áčďéěíňóřšťúůýž" + "áčďéěíňóřšťúůýž".upper())
    has_diacritic = False
    for row in rows:
        patch, _ = build_row(row, taxonomy, "cs")
        text = patch.i_product_name + patch.i_brand + patch.i_manufact + patch.i_size + patch.i_container
        if any(c in diacritic_chars for c in text):
            has_diacritic = True
            # round-trip through UTF-8 bytes unchanged
            assert text.encode("utf-8").decode("utf-8") == text
    assert has_diacritic, "fixture sample produced no Czech-diacritic content — check taxonomy coverage"


def test_hero_surfaces_in_top20_per_populated_category(taxonomy, rows):
    """Sort by the mock revenue proxy (i_current_price) and assert >=1 hero brand appears in the
    top-20 per populated category — guards Stage 1.2 T4 / 1.4 T4 spot-checks."""
    by_category: dict[str, list] = {}
    for row in rows:
        by_category.setdefault(row.i_category, []).append(row)

    hero_brand_names = set()
    for cat in taxonomy.categories.values():
        for node in cat["classes"]:
            for b in node["brands"]:
                if b.get("hero"):
                    hero_brand_names.add(b["en"])

    for category, cat_rows in by_category.items():
        if len(cat_rows) < 5:
            continue  # too small a sample in the mocked fixture to expect a hero to surface
        ranked = sorted(cat_rows, key=lambda r: float(r.i_current_price or 0), reverse=True)
        top20 = ranked[:20]
        brands_in_top20 = set()
        for row in top20:
            patch, _ = build_row(row, taxonomy, "en")
            brands_in_top20.add(patch.i_brand)
        assert brands_in_top20 & hero_brand_names, (
            f"category {category!r}: no hero brand in the top-20 by price"
        )
