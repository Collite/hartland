# run-set — the hartland-query e2e run-set

The sibling of the retired `tpcds-query` context (Q-BM-7: DB retired, `tpc-ds-1g` dump kept).
Oracle rows for the 15 `q.hartland.*` queries on BOTH worlds (US in USD, CZ = US ×FX). Pointed at
the standing cluster estate; run by `just demo-check hartland` and by the nightlies on every
cluster (bp-dsk, collite-o1, hartland) against the shared `hartland-pg` (BM-10).

## `fingerprints/` — the investment report's rehearsal oracle (IE-P3·S3.3, IE contracts §7.2)

A second kind of oracle, in the same spirit and kept apart from `cases/`: one CSV per
`(template, portfolio, as_of)`, holding the quarter rows of the workbook the Reports tile produced.
`just report-fingerprint --save` writes one; a later run compares the report a client downloads with
the reference query run on the book, so a fingerprint is what a rehearsal can be held to rather than
a screenshot. ⚑ The saved file is the WORKBOOK's side — the book is the other side and is read live.
