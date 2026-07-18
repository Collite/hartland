"""Stage 1.1 T6 — determinism + FK-integrity unit tests. Mocked/unit: CSV fixture only."""
import hashlib
from pathlib import Path

import pytest

from generate import Taxonomy, build_row, emit_sql, read_items, run

FIXTURES = Path(__file__).parent / "fixtures"
TAXONOMY_PATH = Path(__file__).parent.parent / "taxonomy.yaml"


@pytest.fixture(scope="module")
def taxonomy() -> Taxonomy:
    return Taxonomy.load(TAXONOMY_PATH)


@pytest.fixture(scope="module")
def rows():
    return read_items(FIXTURES / "item_sample.csv")


def test_determinism_two_runs_byte_identical(tmp_path):
    out1_us, out1_cz = tmp_path / "us1.sql", tmp_path / "cz1.sql"
    out2_us, out2_cz = tmp_path / "us2.sql", tmp_path / "cz2.sql"
    run(FIXTURES / "item_sample.csv", TAXONOMY_PATH, out1_us, out1_cz, None)
    run(FIXTURES / "item_sample.csv", TAXONOMY_PATH, out2_us, out2_cz, None)

    def sha(p: Path) -> str:
        return hashlib.sha256(p.read_bytes()).hexdigest()

    assert sha(out1_us) == sha(out2_us), "two runs produced different us.sql — determinism broken"
    assert sha(out1_cz) == sha(out2_cz), "two runs produced different cz.sql — determinism broken"


def test_fk_integrity(taxonomy, rows):
    input_sks = {row.i_item_sk for row in rows}
    for row in rows:
        patch, _ = build_row(row, taxonomy, "en")
        assert isinstance(patch.i_brand_id, int)
        assert isinstance(patch.i_manufact_id, int)
        assert patch.i_item_sk in input_sks


def test_class_id_never_emitted(rows, taxonomy):
    sql = emit_sql([build_row(r, taxonomy, "en")[0] for r in rows], taxonomy, "en")
    assert "i_class_id" not in sql
    assert "i_item_sk=" in sql  # WHERE clause present


def test_sql_wraps_single_transaction(rows, taxonomy):
    sql = emit_sql([build_row(r, taxonomy, "en")[0] for r in rows], taxonomy, "en")
    assert sql.strip().startswith("BEGIN;")
    assert sql.strip().endswith("COMMIT;")
    assert sql.count("BEGIN;") == 1
    assert sql.count("COMMIT;") == 1
