"""Stage 1.3 T6a — mocked/unit test over geo-map.csv: total, single-valued, distribution-preserving."""
import csv
from collections import defaultdict
from pathlib import Path

MAP_PATH = Path(__file__).parent.parent / "geo-map.csv"

US_STATES = {
    "AK","AL","AR","AZ","CA","CO","CT","DC","DE","FL","GA","HI","IA","ID","IL","IN",
    "KS","KY","LA","MA","MD","ME","MI","MN","MO","MS","MT","NC","ND","NE","NH","NJ",
    "NM","NV","NY","OH","OK","OR","PA","RI","SC","SD","TN","TX","UT","VA","VT","WA",
    "WI","WV","WY",
}


def load_map():
    with MAP_PATH.open(encoding="utf-8") as f:
        return list(csv.DictReader(f))


def test_total_every_us_state_covered():
    rows = load_map()
    covered = {r["us_state"] for r in rows}
    missing = US_STATES - covered
    assert not missing, f"states missing from geo-map.csv: {missing}"


def test_single_valued_state_to_kraj():
    rows = load_map()
    seen = {}
    for r in rows:
        st = r["us_state"]
        assert st not in seen, f"duplicate row for state {st}"
        seen[st] = r["kraj_code"]


def test_kraj_codes_fit_column_and_form_exactly_14_kraje():
    rows = load_map()
    codes = [r["kraj_code"] for r in rows if r["us_state"] != "(null)"]
    assert all(len(c) == 2 for c in codes), "kraj_code must fit char(2) columns"
    assert len(set(codes)) == 14, "expected exactly the 14 Czech kraje in use (many US states per kraj)"


def test_null_state_fallback_present():
    rows = load_map()
    null_rows = [r for r in rows if r["us_state"] == "(null)"]
    assert len(null_rows) == 1


def test_distribution_preserving():
    """A fixture of (state -> revenue) must map to the same aggregate (kraj -> revenue) totals
    as summing the per-state revenue grouped by each state's assigned kraj -- i.e. the mapping
    doesn't smear one state's revenue across multiple kraje."""
    rows = load_map()
    state_to_kraj = {r["us_state"]: r["kraj_code"] for r in rows}

    fixture_revenue = {st: (i + 1) * 1000 for i, st in enumerate(sorted(US_STATES))}

    by_kraj_via_map = defaultdict(float)
    for st, rev in fixture_revenue.items():
        by_kraj_via_map[state_to_kraj[st]] += rev

    # recompute independently by grouping the fixture directly against the map rows
    by_kraj_direct = defaultdict(float)
    for r in rows:
        if r["us_state"] in fixture_revenue:
            by_kraj_direct[r["kraj_code"]] += fixture_revenue[r["us_state"]]

    assert dict(by_kraj_via_map) == dict(by_kraj_direct)
    assert sum(by_kraj_via_map.values()) == sum(fixture_revenue.values())
