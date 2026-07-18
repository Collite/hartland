# hartland

The **Hartland** demo world — the single home for everything about the Kantheon capabilities
demo (the `ai-models`-analog for the demo, D-7/BM-9). Kantheon is code; **all demo assets live
here**.

Two worlds, one model (BM-1/BM-2): **`hartland_us`** (English, USD) and **`hartland_cz`** (Czech,
CZK) — the same physical TPC-DS schema, the same seeded "DC-meltdown" story, served by **one**
TTR-M model over two connections.

## Layout

| Folder | What |
|---|---|
| `model/` | the TTR-M model — `db/` (physical), `er/` (logical + er2db), `md/` (ROLAP star + md2db), `lexicon/` (en+cs), `queries/` (`q.hartland.*`) |
| `agents/` | the agent def (Ariadne source) + both Golem Shems (`golem-hartland`, `golem-hartland-finance`) with `prompts/{en,cs}` |
| `data/` | the data build — `redate/`, `localize-cz/`, `catalog/`, `seed/`, `recon/` (produces the two versioned demo dumps) |
| `run-set/` | the `hartland-query` e2e run-set (both worlds) |
| `design/` | the design + planning docs (delta, plan, e2e re-plan) and `tasks/` (the per-stage task lists) |

## Where to start

`design/plan-demo-build.md` — the three-phase build plan. `design/08-czech-mirror-and-catalog-delta.md`
— the decisions (BM-1..BM-10). `design/test-fixture-hartland-replan.md` — hartland as the
ecosystem e2e fixture. Task lists: `design/tasks/`.

The olymp GitOps overlay `clusters/hartland` (in the **olymp** repo) deploys the showcase cluster
and reads this repo for the model (Ariadne source) + run-set.
