# run-set/cases — the nightly data-tier case catalog

One `*.case.yaml` = one distributable nightly test case (contract: olymp
`nightly/design/contracts.md` **N-C3**). Oracle rows live beside them in `../oracle/{us,cz}/`
(BM-9 — demo/test content lives in `Collite/hartland`); the runner lives in olymp
(`nightly/case-runner.py`).

## Authoring a case (the whole job — ~30 min)

1. **Copy** `_template.case.yaml` → `<query-slug>-<world>.case.yaml`; the `id:` equals the
   filename stem.
2. **Fill five fields**: `world`, `owner` (your GitHub handle — a red pings you), `source`
   (query name from `model/queries/q_hartland.ttrm` + every declared param), `expect.key`
   (the columns that uniquely identify a row), `expect.tolerance`.
3. **Freeze the oracle CSV** into `../oracle/<world>/<query>.csv` — from the frozen
   `data/recon/R0.md` / recon CSVs (`data/recon/results-{us,cz}/`), NOT from a live query you
   didn't eyeball against R0. Header row tags column classes: `revenue:money`, `share:ratio`,
   plain = exact. CZ money = US ×23 (FX, `data/localize-cz/fx.conf`).
4. **Run it locally** against bp-dsk:
   `python3 ../../../olymp/nightly/case-runner.py --cases . --only <id> --kube dsk`
5. **PR to `Collite/hartland`** (case + oracle CSV together). CI runs
   `case-runner.py --check` (schema + owner + oracle presence) — no cluster needed.

Rules: read-only cases target the standing `hartland_{us,cz}`; anything that writes targets
`hartland_*_nightly` (the T1 scratch DBs) and declares it in `target.db`. Changing an oracle
CSV is a reviewed change with an R0 anchor in the PR description. A flaky case is quarantined
via `quarantined: true` in a PR — never by deleting it.

## Layout

```
cases/           *.case.yaml (+ _template.case.yaml)
../queries/      <query>.sql — extracted SQL, one per q.hartland.* (P3-S4 T1)
../oracle/us/    <query>.csv — frozen expected rows, USD
../oracle/cz/    <query>.csv — frozen expected rows, CZK (= US ×23)
```
