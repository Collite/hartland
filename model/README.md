# model — the Hartland TTR-M model

One model set (BM-2/BM-5), served over `pg-hartland-us` (USD) and `pg-hartland-cz` (CZK).

- `db/` — `model db`: the physical TPC-DS subset (facts + used dims), types, PK/FK.
- `er/` — `model er` + `er2db` binding: the 19 curated entities + relationships (05-d/D-5).
- `md/` — `model md` + `md2db`/`md2er` binding: the ROLAP star (cubelets, measures, conformed
  dimensions incl. the Product hierarchy Category→Class→Brand→Manufacturer→Item).
- `lexicon/` — `model lexicon locale en` + `locale cs`: the bilingual naming layer + valueLabels.
- `queries/` — the `q.hartland.*` preferred queries (#1–15, D-2).
