#!/usr/bin/env python3
"""IE-P3·S3.3 — the report fingerprint's comparison engine (IE-C35).

The shell script does the I/O (render through studio-bff, download the workbook, run the reference
query with psql); everything that decides whether two answers AGREE lives here, because that is the
part worth testing without an estate.

## What is compared with what, and why not the obvious thing

IE-C35 says "Summary totals equal `q.investment.quarterly_evolution` run directly". The obvious
reading — ask the door for that program — is impossible and always was: ⚑IE-15 (a) ruled the program
un-runnable through the door (no date arithmetic, no LAG), the renderer assembles the same table from
`period_values` instead, and a live walk re-confirmed the 404 on 2026-09-14. So the two sides are:

  * the WORKBOOK the renderer produced, read back out of the `.xlsx` — the assembly, through the door,
    through Arrow, through POI;
  * the REFERENCE SQL, run on the book with psql — the same statement kantheon's conformance suite
    holds to hand-computed expectations.

They are independent all the way down to the rows in the table, which is what makes agreement mean
something.

## Two known, RULED differences this must not report as defects

  * **Rounding (S3.1·D7).** The renderer rounds each currency's period total; the reference rounds each
    holding line first. Equal on the fixture; a real book can differ by a cent per holding. So money is
    compared with a tolerance, stated in the output rather than hidden.
  * **An `as_of` ON a quarter end (S3.1·D2).** The reference reports that day twice — once whole, once
    as a partial row; the renderer reports it once, per IE-C30's "≤". The shell refuses such an `as_of`
    rather than papering over it here.

Subcommands:

    fingerprint.py sheet <workbook.xlsx> [--sheet Summary]   → canonical CSV
    fingerprint.py reference <psql.csv>                      → canonical CSV
    fingerprint.py compare <a.csv> <b.csv> [--tolerance 0.01] [--label-a X] [--label-b Y]
    fingerprint.py expect <a.csv> <expectations.json> <portfolio>
"""

from __future__ import annotations

import argparse
import csv
import io
import json
import re
import sys
import zipfile
from datetime import date, timedelta
from decimal import Decimal
from xml.etree import ElementTree

NS = {"m": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}

#: The canonical row — §4.1's columns, minus the two the sheet does not print (`portfolio_id` is in
#: the title block; `partial` is said by the note). Order is the comparison's order.
COLUMNS = [
    "period_end",
    "currency",
    "total_value",
    "market_value",
    "cash_balance",
    "net_flow_q",
    "pnl_q",
    "return_q_pct",
    "price_coverage",
]

#: The Summary sheet's headers (IE-C34), mapped to the canonical names. Read BY HEADER, never by
#: position: the workbook's column order is the template author's decision and may change.
HEADERS = {
    "Period end": "period_end",
    "Currency": "currency",
    "Total value": "total_value",
    "Market value": "market_value",
    "Cash": "cash_balance",
    "Net flows": "net_flow_q",
    "P&L": "pnl_q",
    "Return %": "return_q_pct",
    "Coverage": "price_coverage",
}

MONEY = ["total_value", "market_value", "cash_balance", "net_flow_q", "pnl_q"]
#: Excel's day 0 — 1899-12-30, not 12-31: the serial numbering carries Lotus's 1900 leap-year bug.
EXCEL_EPOCH = date(1899, 12, 30)


def money(value: str) -> str:
    return f"{Decimal(value):.2f}" if value not in ("", None) else ""


def percent(value: str) -> str:
    return f"{Decimal(value):.6f}" if value not in ("", None) else ""


# ── the workbook ─────────────────────────────────────────────────────────────────────────────────


def _shared_strings(zf: zipfile.ZipFile) -> list[str]:
    try:
        xml = zf.read("xl/sharedStrings.xml")
    except KeyError:
        return []
    out = []
    for si in ElementTree.fromstring(xml).findall("m:si", NS):
        out.append("".join(t.text or "" for t in si.iter(f"{{{NS['m']}}}t")))
    return out


def _sheet_path(zf: zipfile.ZipFile, name: str) -> str:
    workbook = ElementTree.fromstring(zf.read("xl/workbook.xml"))
    rels = ElementTree.fromstring(zf.read("xl/_rels/workbook.xml.rels"))
    target_by_id = {
        r.attrib["Id"]: r.attrib["Target"] for r in rels
    }
    rid = "{http://schemas.openxmlformats.org/officeDocument/2006/relationships}id"
    for i, sheet in enumerate(workbook.find("m:sheets", NS).findall("m:sheet", NS)):
        if sheet.attrib.get("name") == name:
            target = target_by_id.get(sheet.attrib.get(rid), f"worksheets/sheet{i + 1}.xml")
            return target if target.startswith("xl/") else f"xl/{target.lstrip('/')}"
    raise SystemExit(f"the workbook has no sheet named {name!r}")


def _cells(zf: zipfile.ZipFile, path: str, strings: list[str]) -> list[dict[str, str]]:
    """Each row as {column letter: text}. A numeric cell keeps its digits; a date stays a serial."""
    rows = []
    root = ElementTree.fromstring(zf.read(path))
    for row in root.find("m:sheetData", NS).findall("m:row", NS):
        cells: dict[str, str] = {}
        for c in row.findall("m:c", NS):
            ref = c.attrib.get("r", "")
            col = re.sub(r"\d", "", ref)
            kind = c.attrib.get("t")
            if kind == "inlineStr":
                # ⛔ Should never happen: POI cannot FILL a placeholder in an inline-string cell
                # (S3.1·D4), so an inline string here means the workbook was not authored as Excel
                # writes them and half the sheet is unrendered markers.
                raise SystemExit(f"{ref} is an inline string — the template is not shared-string (S3.1·D4)")
            v = c.find("m:v", NS)
            if v is None or v.text is None:
                continue
            cells[col] = strings[int(v.text)] if kind == "s" else v.text
        rows.append(cells)
    return rows


def sheet_rows(path: str, sheet: str) -> list[dict[str, str]]:
    with zipfile.ZipFile(path) as zf:
        strings = _shared_strings(zf)
        rows = _cells(zf, _sheet_path(zf, sheet), strings)

    header_at = None
    for i, row in enumerate(rows):
        if "Period end" in row.values() and "Coverage" in row.values():
            header_at = i
            break
    if header_at is None:
        raise SystemExit(f"the {sheet} sheet has no quarter-table header row (Period end … Coverage)")

    column_of = {col: HEADERS[text] for col, text in rows[header_at].items() if text in HEADERS}
    missing = set(COLUMNS) - set(column_of.values())
    if missing:
        raise SystemExit(f"the {sheet} sheet's table is missing {', '.join(sorted(missing))}")

    out = []
    for row in rows[header_at + 1:]:
        period_cell = next((v for c, v in row.items() if column_of.get(c) == "period_end"), "")
        # The table ends at the first row whose period is not a DATE. ⚑ Not "not empty": the note row
        # under the table (IE-C34) carries text in that very cell, and reading emptiness alone made the
        # note the first data row.
        try:
            serial = int(Decimal(period_cell))
        except Exception:
            break
        record = {name: "" for name in COLUMNS}
        for col, name in column_of.items():
            record[name] = row.get(col, "")
        # A date is a serial number in the file; the format that displays it is a style, not a value.
        record["period_end"] = (EXCEL_EPOCH + timedelta(days=serial)).isoformat()
        for name in MONEY:
            record[name] = money(record[name])
        record["return_q_pct"] = percent(record["return_q_pct"])
        out.append(record)
    if not out:
        raise SystemExit(f"the {sheet} sheet's quarter table has no rows")
    return out


# ── the reference query's answer ─────────────────────────────────────────────────────────────────

#: §4.1's own column order, as `quarterly_evolution` projects it.
REFERENCE_COLUMNS = [
    "portfolio_id",
    "period_end",
    "partial",
    "currency",
    "market_value",
    "cash_balance",
    "total_value",
    "net_flow_q",
    "pnl_q",
    "return_q_pct",
    "price_coverage",
]


def reference_rows(path: str) -> list[dict[str, str]]:
    """psql's unaligned output (`-A -F,` `-t`): one row per line, SQL NULL as an empty field."""
    out = []
    with open(path, newline="", encoding="utf-8") as fh:
        for line in csv.reader(fh):
            if not line or not any(f.strip() for f in line):
                continue
            if len(line) != len(REFERENCE_COLUMNS):
                raise SystemExit(
                    f"the reference answered {len(line)} columns, not {len(REFERENCE_COLUMNS)}: {line}"
                )
            row = dict(zip(REFERENCE_COLUMNS, line))
            record = {
                "period_end": row["period_end"][:10],
                "currency": row["currency"],
                "price_coverage": row["price_coverage"],
                "return_q_pct": percent(row["return_q_pct"]),
            }
            for name in MONEY:
                record[name] = money(row[name])
            out.append({name: record[name] for name in COLUMNS})
    if not out:
        raise SystemExit("the reference query answered no rows")
    return out


# ── comparison ───────────────────────────────────────────────────────────────────────────────────


def write_csv(rows: list[dict[str, str]], out: io.TextIOBase) -> None:
    writer = csv.DictWriter(out, fieldnames=COLUMNS, lineterminator="\n")
    writer.writeheader()
    writer.writerows(rows)


def read_csv(path: str) -> list[dict[str, str]]:
    with open(path, newline="", encoding="utf-8") as fh:
        return [dict(row) for row in csv.DictReader(fh)]


def compare(
    a: list[dict],
    b: list[dict],
    tolerance: Decimal,
    label_a: str,
    label_b: str,
    return_tolerance: Decimal = Decimal("0.0001"),
) -> list[str]:
    """Every difference, named. Rows are matched on (period_end, currency) — never on order."""
    problems = []
    keys_a = {(r["period_end"], r["currency"]) for r in a}
    keys_b = {(r["period_end"], r["currency"]) for r in b}
    for key in sorted(keys_a - keys_b):
        problems.append(f"{key[0]} {key[1]}: in {label_a}, absent from {label_b}")
    for key in sorted(keys_b - keys_a):
        problems.append(f"{key[0]} {key[1]}: in {label_b}, absent from {label_a}")

    by_b = {(r["period_end"], r["currency"]): r for r in b}
    for row in a:
        key = (row["period_end"], row["currency"])
        other = by_b.get(key)
        if other is None:
            continue
        for name in COLUMNS[2:]:
            left, right = row[name], other[name]
            if name in MONEY or name == "return_q_pct":
                if left == "" or right == "":
                    if left != right:
                        problems.append(f"{key[0]} {key[1]} {name}: {label_a}={left or '(blank)'} {label_b}={right or '(blank)'}")
                    continue
                gap = abs(Decimal(left) - Decimal(right))
                # ⚑ The return is a RATIO of two rounded figures, so it inherits their disagreement
                # amplified: measured live on hartland 2026-09-14, a quarter whose money matched to the
                # cent still differed by 0.000008 percentage points, because the two sides round at
                # different moments (S3.1·D7). The sheet prints two decimals; a ten-thousandth of a
                # percentage point is far below anything a reader or a rehearsal can see, and still
                # catches a genuinely wrong return by orders of magnitude.
                limit = tolerance if name in MONEY else return_tolerance
                if gap > limit:
                    problems.append(f"{key[0]} {key[1]} {name}: {label_a}={left} {label_b}={right} (off by {gap})")
            elif left != right:
                problems.append(f"{key[0]} {key[1]} {name}: {label_a}={left!r} {label_b}={right!r}")
    return problems


def expectations_rows(path: str, portfolio: str) -> list[dict[str, str]]:
    """kantheon's hand-computed answers — the third side, for a run against the fixture book (T4)."""
    data = json.loads(open(path, encoding="utf-8").read())
    key = "quarterly_evolution_two_currencies" if data.get("quarterly_evolution_two_currencies") and portfolio.endswith("149") else "quarterly_evolution"
    rows = [dict(zip(REFERENCE_COLUMNS, row)) for row in data[key]]
    out = []
    for row in rows:
        if row["portfolio_id"] != portfolio:
            continue
        record = {
            "period_end": (row["period_end"] or "")[:10],
            "currency": row["currency"],
            "price_coverage": row["price_coverage"],
            "return_q_pct": percent(row["return_q_pct"] or ""),
        }
        for name in MONEY:
            record[name] = money(row[name] or "")
        out.append({name: record[name] for name in COLUMNS})
    if not out:
        raise SystemExit(f"{path} holds no expectations for {portfolio}")
    return out


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    p_sheet = sub.add_parser("sheet", help="the workbook's quarter table as canonical CSV")
    p_sheet.add_argument("workbook")
    p_sheet.add_argument("--sheet", default="Summary")

    p_ref = sub.add_parser("reference", help="psql's answer as canonical CSV")
    p_ref.add_argument("csv")

    p_cmp = sub.add_parser("compare", help="two canonical CSVs, row by row")
    p_cmp.add_argument("a")
    p_cmp.add_argument("b")
    p_cmp.add_argument("--tolerance", default="0.01")
    p_cmp.add_argument("--return-tolerance", default="0.0001")
    p_cmp.add_argument("--label-a", default="workbook")
    p_cmp.add_argument("--label-b", default="reference")

    p_exp = sub.add_parser("expect", help="a canonical CSV against kantheon's expectations.json")
    p_exp.add_argument("a")
    p_exp.add_argument("expectations")
    p_exp.add_argument("portfolio")

    args = parser.parse_args()
    if args.command == "sheet":
        write_csv(sheet_rows(args.workbook, args.sheet), sys.stdout)
        return 0
    if args.command == "reference":
        write_csv(reference_rows(args.csv), sys.stdout)
        return 0

    if args.command == "compare":
        problems = compare(
            read_csv(args.a), read_csv(args.b), Decimal(args.tolerance), args.label_a, args.label_b,
            Decimal(args.return_tolerance),
        )
        tolerance_note = (
            f" (money to ±{args.tolerance}, return % to ±{args.return_tolerance}"
            " — the ruled rounding-order difference, S3.1·D7)"
        )
        label = f"{args.label_a} vs {args.label_b}"
    else:
        problems = compare(
            read_csv(args.a), expectations_rows(args.expectations, args.portfolio),
            Decimal("0.01"), "workbook", "expectations",
        )
        tolerance_note = ""
        label = "workbook vs kantheon's hand-computed expectations"

    if problems:
        print(f"✗ {label} DISAGREE:")
        for p in problems:
            print(f"    {p}")
        return 1
    print(f"✓ {label} agree{tolerance_note}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
