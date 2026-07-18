#!/usr/bin/env python3
"""Deterministic bilingual per-item catalog generator (Hartland demo, Stage 1.1).

Reads a CSV export of the `item` dimension (i_item_sk, i_item_id, i_category,
i_category_id, i_class, i_class_id, i_current_price) plus the curated
`taxonomy.yaml`, and emits idempotent SQL UPDATE scripts that patch
i_product_name/i_brand/i_brand_id/i_manufact/i_manufact_id/i_size/i_container
per world (en for US, cs for CZ). No random(), no wall-clock — every choice is
sha256(f"{i_item_sk}:{salt}") reduced mod a candidate-list length, so two runs
on the same inputs are byte-identical (BM-4's reproducibility guarantee).

i_item_sk, i_category, i_category_id, i_current_price, i_class_id, and the
SCD validity window are never written — they are the invariants the seeds
and recon depend on.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import sys
from dataclasses import dataclass
from pathlib import Path

import yaml

GENERATOR_VERSION = "1.0.0"
BASE36_ALPHABET = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"

# TPC-DS `item` column widths (character(n) — exceeding these fails the UPDATE server-side).
COLUMN_WIDTHS = {
    "i_brand": 50,
    "i_manufact": 50,
    "i_size": 20,
    "i_container": 10,
    "i_product_name": 50,
}


# --------------------------------------------------------------------------- hashing

def _digest(*parts: str) -> int:
    """Deterministic, wall-clock-free, process-independent hash (unlike builtin hash())."""
    h = hashlib.sha256(":".join(parts).encode("utf-8")).digest()
    return int.from_bytes(h, "big")


def hash_pick(salt: str, key: str, n: int) -> int:
    if n <= 0:
        raise ValueError(f"cannot pick from an empty candidate list (salt={salt!r}, key={key!r})")
    return _digest(key, salt) % n


def base36(n: int) -> str:
    if n == 0:
        return "0"
    digits = []
    while n:
        n, r = divmod(n, 36)
        digits.append(BASE36_ALPHABET[r])
    return "".join(reversed(digits))


# --------------------------------------------------------------------------- taxonomy

@dataclass(frozen=True)
class ClassNode:
    category_key: str
    key: str
    en: str
    cs: str
    brands: list[dict]
    product_lines: list[dict]


class Taxonomy:
    def __init__(self, doc: dict, source_bytes: bytes):
        self.sha256 = hashlib.sha256(source_bytes).hexdigest()
        self.categories = doc["categories"]
        # (category, class) -> ClassNode, and category -> [ClassNode, ...] for folding
        self._pair_index: dict[tuple[str, str], ClassNode] = {}
        self._by_category: dict[str, list[ClassNode]] = {}
        for cat_key, cat in self.categories.items():
            nodes = []
            for c in cat["classes"]:
                node = ClassNode(
                    category_key=cat_key,
                    key=c["key"],
                    en=c["en"],
                    cs=c["cs"],
                    brands=c["brands"],
                    product_lines=c["product_lines"],
                )
                nodes.append(node)
                self._pair_index[(cat_key, c["key"])] = node
            self._by_category[cat_key] = nodes

    @classmethod
    def load(cls, path: Path) -> "Taxonomy":
        raw = path.read_bytes()
        doc = yaml.safe_load(raw)
        return cls(doc, raw)

    def resolve(self, category: str, klass: str) -> tuple[ClassNode, bool]:
        """Returns (node, folded). Raises if the category itself is unknown (outside the 10)."""
        if category not in self.categories:
            raise KeyError(f"category {category!r} is not one of the 10 curated categories")
        node = self._pair_index.get((category, klass))
        if node is not None:
            return node, False
        # Fold: deterministic, reported, never silent.
        nodes = self._by_category[category]
        idx = hash_pick("fold", klass, len(nodes))
        return nodes[idx], True

    def containers(self, category: str) -> list[dict]:
        return self.categories[category]["containers"]

    def sizes(self, category: str) -> list[dict]:
        return self.categories[category]["sizes"]


# --------------------------------------------------------------------------- rows

@dataclass(frozen=True)
class ItemRow:
    i_item_sk: str
    i_item_id: str
    i_category: str
    i_category_id: str
    i_class: str
    i_class_id: str
    i_current_price: str


@dataclass(frozen=True)
class CatalogPatch:
    i_item_sk: str
    i_product_name: str
    i_brand: str
    i_brand_id: int
    i_manufact: str
    i_manufact_id: int
    i_size: str
    i_container: str
    # locale-independent node identity, for the Stage 1.4 mirror check
    class_key: str
    brand_key: str
    container_key: str
    size_key: str


def read_items(csv_path: Path) -> list[ItemRow]:
    rows = []
    with csv_path.open(newline="", encoding="utf-8") as f:
        for r in csv.DictReader(f):
            category = (r.get("i_category") or "").strip()
            if not category:
                continue  # NULL-category SCD-tail row — carries no on-screen product (T5)
            rows.append(
                ItemRow(
                    i_item_sk=r["i_item_sk"].strip(),
                    i_item_id=r["i_item_id"].strip(),
                    i_category=category,
                    i_category_id=r["i_category_id"].strip(),
                    i_class=(r.get("i_class") or "").strip(),
                    i_class_id=r["i_class_id"].strip(),
                    i_current_price=r["i_current_price"].strip(),
                )
            )
    return rows


def build_row(item_row: ItemRow, tax: Taxonomy, locale: str) -> tuple[CatalogPatch, bool]:
    """Returns (patch, folded). locale is 'en' or 'cs'; node selection is locale-independent —
    only the rendered strings differ, so en/cs of the same i_item_sk always share one node."""
    if locale not in ("en", "cs"):
        raise ValueError(f"locale must be 'en' or 'cs', got {locale!r}")

    node, folded = tax.resolve(item_row.i_category, item_row.i_class)
    sk = item_row.i_item_sk

    brands = node.brands
    hero_indices = [i for i, b in enumerate(brands) if b.get("hero")]
    weighted = list(range(len(brands))) + hero_indices  # heroes get 2x candidate slots
    brand = brands[weighted[hash_pick("brand", sk, len(weighted))]]
    brand_key = brand["en"]  # locale-independent identity for ids + the mirror map

    product_lines = node.product_lines
    line = product_lines[hash_pick("line", sk, len(product_lines))]

    containers = tax.containers(node.category_key)
    container = containers[hash_pick("container", sk, len(containers))]

    sizes = tax.sizes(node.category_key)
    size = sizes[hash_pick("size", sk, len(sizes))]

    model_token = "MX-" + base36(_digest(sk, "model") % 46656)

    brand_name = brand[locale]
    manufact_name = brand["manufact"][locale]
    line_name = line[locale]
    container_name = container[locale]
    size_name = size[locale]

    product_name = f"{brand_name} {line_name} {model_token}"[:50]

    i_brand_id = 1000 + (_digest(brand_key, "brand_id") % 9000)
    i_manufact_id = 100 + (_digest(brand["manufact"]["en"], "manufact_id") % 900)

    for field, value in (
        ("i_brand", brand_name),
        ("i_manufact", manufact_name),
        ("i_size", size_name),
        ("i_container", container_name),
        ("i_product_name", product_name),
    ):
        limit = COLUMN_WIDTHS[field]
        if len(value) > limit:
            raise ValueError(
                f"taxonomy value too long for item.{field} character({limit}): "
                f"{value!r} ({len(value)} chars) — sk={sk} locale={locale} category={node.category_key} class={node.key}"
            )

    patch = CatalogPatch(
        i_item_sk=sk,
        i_product_name=product_name,
        i_brand=brand_name,
        i_brand_id=i_brand_id,
        i_manufact=manufact_name,
        i_manufact_id=i_manufact_id,
        i_size=size_name,
        i_container=container_name,
        class_key=f"{node.category_key}:{node.key}",
        brand_key=brand_key,
        container_key=container["en"],
        size_key=size["en"],
    )
    return patch, folded


# --------------------------------------------------------------------------- SQL emission

def _sql_escape(s: str) -> str:
    return s.replace("'", "''")


def emit_sql(patches: list[CatalogPatch], taxonomy: Taxonomy, locale: str) -> str:
    lines = [
        "BEGIN;",
        f"-- generated by data/catalog/generate.py v{GENERATOR_VERSION}"
        f" from taxonomy.yaml sha256={taxonomy.sha256}; locale={locale}; DO NOT EDIT BY HAND",
    ]
    for p in patches:
        lines.append(
            "UPDATE item SET "
            f"i_product_name='{_sql_escape(p.i_product_name)}', "
            f"i_brand='{_sql_escape(p.i_brand)}', "
            f"i_brand_id={p.i_brand_id}, "
            f"i_manufact='{_sql_escape(p.i_manufact)}', "
            f"i_manufact_id={p.i_manufact_id}, "
            f"i_size='{_sql_escape(p.i_size)}', "
            f"i_container='{_sql_escape(p.i_container)}' "
            f"WHERE i_item_sk={p.i_item_sk};"
        )
    lines.append("COMMIT;")
    return "\n".join(lines) + "\n"


def emit_mirror_map(patches_en: list[CatalogPatch]) -> str:
    lines = ["i_item_sk,class_key,brand_key,container_key,size_key"]
    for p in patches_en:
        lines.append(f"{p.i_item_sk},{p.class_key},{p.brand_key},{p.container_key},{p.size_key}")
    return "\n".join(lines) + "\n"


# --------------------------------------------------------------------------- CLI

def run(items_csv: Path, taxonomy_path: Path, out_us: Path, out_cz: Path, mirror_map: Path | None) -> None:
    tax = Taxonomy.load(taxonomy_path)
    rows = read_items(items_csv)

    patches_en: list[CatalogPatch] = []
    patches_cs: list[CatalogPatch] = []
    folded_report: list[tuple[str, str]] = []

    for row in rows:
        p_en, folded_en = build_row(row, tax, "en")
        p_cs, folded_cs = build_row(row, tax, "cs")
        patches_en.append(p_en)
        patches_cs.append(p_cs)
        if folded_en:
            folded_report.append((row.i_category, row.i_class))

    out_us.write_text(emit_sql(patches_en, tax, "en"), encoding="utf-8")
    out_cz.write_text(emit_sql(patches_cs, tax, "cs"), encoding="utf-8")
    if mirror_map is not None:
        mirror_map.write_text(emit_mirror_map(patches_en), encoding="utf-8")

    if folded_report:
        uniq = sorted(set(folded_report))
        print(f"WARNING: {len(uniq)} (category,class) pair(s) folded (not in taxonomy):", file=sys.stderr)
        for cat, klass in uniq:
            print(f"  - {cat!r} / {klass!r}", file=sys.stderr)

    print(f"{len(rows)} live rows -> {out_us} / {out_cz}", file=sys.stderr)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--items", required=True, type=Path, help="CSV export of the item dimension")
    ap.add_argument("--taxonomy", required=True, type=Path, help="taxonomy.yaml")
    ap.add_argument("--out-us", required=True, type=Path, help="output path for the en/US UPDATE script")
    ap.add_argument("--out-cz", required=True, type=Path, help="output path for the cs/CZ UPDATE script")
    ap.add_argument("--mirror-map", type=Path, default=None, help="optional mirror-map.csv output (Stage 1.4 T2)")
    args = ap.parse_args()
    run(args.items, args.taxonomy, args.out_us, args.out_cz, args.mirror_map)


if __name__ == "__main__":
    main()
