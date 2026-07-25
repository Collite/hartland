# SD — Tatrman Studio demo on Hartland · Contracts

> Demo-specific artifacts only. The product contracts are **frozen inputs, cited not
> restated**: FO-A1 `designer/authoring/contracts.md` (§1 ProcessingGraphOp · §2
> ttrp/validate · §3 preview-run · §4 graduate/saveProgram · §5 member lineage · §6 canvas
> tokens) and FO-A2 `studio-planning/planner/contracts.md` (§A pins/gestures · §B committed
> spread · §C cube batch/journal · §D reservations · §E doors + entry record + form-load ·
> §G planning form · §H round; wire v4). Anything below that contradicts those is a bug in
> *this* file.

## 1. Naming (on-stage register — FO-33/FO-30)

Spoken/visible: **Tatrman Studio**, **Studio Viewer/Modeler/Designer/Planner**, "the Studio
shell", "check-out / check-in", "reservation", "entry record", "round". Never spoken:
package names, `ttrp/*`, CAP codes, branch names, "Kantheon" (except the one continuity
line), retired personas. IDs/testids/schemas keep technical names (A2-D6 discipline).

## 2. The demo workspace (model source)

- Beat 1/M/D operate on a **git clone of this repo** opened as the Designer's Worker
  workspace (edit half): branch **`studio-demo`**, subtree `model/`.
- Two prepared states, switched by the reset script (SD-R1, §8):
  `pre-delta` = `studio-demo` **without** the §3 files (Beat M starting point) ·
  `post-delta` = full `studio-demo` (every other beat, and the rehearsal byte-compare
  reference).
- The cluster-served model (`demo-p2` + veles) is **untouched** by this effort.

## 3. The plan-model delta (TTR-M, committed on `studio-demo`)

Exact text is normative once SD-P1.T2 lands and a Modeler round-trip proves emission
parity (D-6); the shape is fixed now. Files:

**`model/md/versions.ttrm`** (NEW)

```ttrm
package hartland

model md

// SD: the planning axis. `actual` is loaded from hartland_us; `plan-fy26` is authored
// in Studio Planner. Members are closed-set for the demo (no open version admin in v1).
def dimension Version {
    level version { key: versionCode, attributes: [versionName] }
}
```

**`model/md/measures.ttrm`** (EXTEND — one def appended)

```ttrm
// SD: planned revenue — same Money domain as revenue (currency stays a display fact).
def measure planRevenue { domain: md.Money, class: additive, aggregation: sum }
```

**`model/md/cubelets.ttrm`** (EXTEND — one def appended)

```ttrm
// SD: the planning cubelet — month × category × channel × version (SD-D3). Channel is
// the SalesChannel dimension member (store|web|marketplace), NOT three cubelets: plans
// are cross-channel by nature. Grain = load grain = reservation/ripple boundary (A2).
def cubelet revenuePlan {
    grain: [SalesChannel.channelCode, Product.categoryName, Calendar.month, Version.versionCode],
    measures: [planRevenue]
}
```

**`model/md/dimensions.ttrm`** (EXTEND) — `def dimension SalesChannel` with the closed
member set `store | web | marketplace` (labels via lexicon, en+cs), **iff** no channel
dimension exists in the committed model (SD-P1.T1 verifies; the recording cubelets encode
channel by *cubelet identity*, so this is expected to be new).

Lexicon: en/cs labels for Version, SalesChannel, planRevenue appended under
`model/lexicon/{en,cs}/` (same file conventions as `measures.ttrm` there).

Grammar caveat: member/attribute syntax above follows the existing hartland `md` files'
conventions; SD-P1.T1 (the model probe task) validates against the real TTR-M grammar and
amends **this section** if the dialect differs — the *semantic* shape (2 dims, 1 measure,
1 cubelet) is the contract.

## 4. `hartland_plan` — the writable store

One PostgreSQL database, owned by the demo rig. Contents:

1. **Cube storage** `plan.revenue_plan` — the storage-grain fact for `revenuePlan`:

```sql
CREATE SCHEMA IF NOT EXISTS plan;
CREATE TABLE plan.revenue_plan (
  channel_code   text        NOT NULL,             -- store|web|marketplace
  category_name  text        NOT NULL,             -- Product.categoryName (10 values, TPC-DS)
  month_key      integer     NOT NULL,             -- yyyymm, 202401..202612
  version_code   text        NOT NULL,             -- actual|plan-fy26
  plan_revenue   numeric(15,2) NOT NULL DEFAULT 0,
  PRIMARY KEY (channel_code, category_name, month_key, version_code)
);
```

2. **The A2 substrate tables** — created by `:services:studio-planner`'s own migrations
   (journal, entry records, reservations, drafts, prefs, done-flags — A2 contracts §C–§H;
   the demo does NOT define these, it points the service's datasource here).
3. **Roles:** `plan_rw` (the service) · `plan_ro` (inspection). The Hartland warehouses'
   read-only roles are reused for the actuals side; **no demo component gets write on
   `hartland_us`/`_cz`** (assert in SD-P1 verify).

## 5. Seed & round fixture (deterministic, oracle-checked)

**`data/plan/seed-plan.sql` + `data/plan/seed-actuals.sql`** (or one `.mjs` driver):

1. `version_code='actual'` rows 2024-01…2025-12 = aggregation of `hartland_us`
   (store_sales/web_sales/catalog_sales → channel; item→category; day→month). **Oracle:**
   FY2025 totals must equal R0 (`data/recon/R0.md`): Marketplace **$683.4M**, Stores
   $1,024.8M, Web $365.0M — the same numbers the January audience saw; a mismatch fails
   the seed test.
2. `version_code='plan-fy26'` rows 2026-01…2026-12 = the starting shape: FY2025 actuals
   ×1.0 per cell (categories × months × channels), so the stage gesture (+type $755M
   Marketplace total, ≈+10.5%) produces visible, explainable deltas. Zero-base cells for
   the Beat-P step 5 cameo: one (category, channel) plane seeded at 0 with no history —
   fixed choice recorded in the seed script header.
3. **Round state:** version `plan-fy26` = OPEN; no reservations; no drafts; done-flags
   clear. Maya's demo scope (reservation slice) = `channel_code='marketplace'` ×
   full category × 2026 months (load grain, A2 grain discipline).
4. **`data/plan/expected/`** — oracle CSVs for the seed test + the two stage numbers the
   script quotes (FY26 Marketplace seed total; post-spread Q1-pinned expected values for
   rehearsal spot-checks).

## 6. The Designer program & form fixtures

1. **`model/queries/q_hartland_plan.ttrm`** — `q.hartland.plan_vs_actual` (TTR-P):
   inputs `revenuePlan[version=plan-fy26]` + monthly actuals (reuse the #1
   channel-revenue-monthly source shape); join channel×category×month; outputs
   `actual`, `plan`, `variance`, `variance_pct`. Committed text = the Beat-D graduate
   target (byte-compare in rehearsal, same D-6 discipline as Beat M). A staged-error
   variant (`plan_vs_actual.broken` — one mistyped member) lives in the demo script
   only, never committed.
2. **`data/plan/forms/revenue-plan-form.ttrl`** — kind
   `tatrman.ttrl.cube-planning-form` (A2 §G, fixture-fed per A2-D5): cube `revenuePlan`,
   load grain = storage grain (SD-D3), rows = Product.categoryName, columns =
   Calendar.month, slicer = SalesChannel + Version pinned `plan-fy26`, reference overlay =
   `actual` FY2025. Must pass the §8.2 six-rule author-time catalogue (the A2
   `validate-form` mirrors it client-side — the demo form is also a nice live test of it).

## 7. The demo rig (variant A — local; contracts for C land only after SD-⚑1)

**`rig/` in this repo** (new top-level, gitignored state). Host = **Bora's machine,
Rancher Desktop's docker engine** (⚑1 ruling; size the RD VM before the PG restore —
olymp README's `rdctl set` example):

- `rig/docker-compose.yml` — `postgres:16` (databases `hartland_plan` + `hartland_us`
  restored from the versioned demo dump per `data/recon/dump-manifest.md`) · **no
  Keycloak in A** (⚑2 relaxed: dev-auth; a keycloak service block may be added later but
  real SSO is verified at C graduation) · the two Kotlin services if containerized, else
  run via gradle:
- **Ports (fixed, in every script):** Studio shell/launcher **:5173** · designer-server WS
  **:7351** · studio-planner **:7461** · Postgres **:5442** · Keycloak **:8080**.
  *(SD-P0.T4 verifies the services' actual default ports and amends — these are
  placeholders until probed; the contract is "fixed and written here", not the numbers.)*
- `rig/up.sh` · `rig/reset.sh` (SD-R1, §8) · `rig/preshow.sh` — the only three entry
  points an operator needs; each idempotent, each printing a PASS/FAIL tail.
- Env/config files pinning: designer-server run-connection → `hartland_us` (read-only
  role) · studio-planner datasource → `hartland_plan` · launcher tile registry (4 tiles)
  · auth mode = dev-auth with `maya`/`dan` identities (⚑2 ruling; Keycloak at C).

## 8. Reset & readiness contracts

**SD-R1 `rig/reset.sh` (the Studio demo-reset):** restore `hartland_plan` from the seeded
dump → release all reservations → reopen version `plan-fy26` → clear drafts/prefs/done →
reset the workspace clone to `pre-delta` → print fixture checklist. Idempotent; < 60 s;
**never** touches `hartland_us`/`_cz` beyond re-restore-on-demand (flag `--with-warehouse`).

**SD-R2 pre-show:** `reset.sh` → rig up → warm each surface (open all four tiles once) →
run the seed oracle spot-check → login checklist (profile 1 Maya, profile 2 Dan) → print
the two stage numbers (§5.4).

**SD-B — the readiness bar (E-5 analog, recorded per rehearsal in
`design/studio-demo/readiness/`):**

1. rig up from cold in ≤ 10 min, all surfaces healthy;
2. seed oracle green (R0 reconciliation);
3. Beat M byte-compare green (re-enacted emission == committed delta);
4. Beat D loop green in the ⚑3-ruled variant (validate error shows + clears; result rows
   land; graduate → catalog + deep-link);
5. Beat P full loop green (check-out → spread+pins → preview chips all ✓ → check-in →
   entry record persisted → Dan sees "checked out by", then done-flag flips the
   dashboard);
6. reset-and-repeat: SD-R1 then the full arc again, zero operator intervention;
7. **the dry run: twice consecutively, ≤ 25′, zero intervention** (the Kantheon demo's R4
   discipline, one notch tighter since there's no LLM latency).

## 9. Issue routing (SD-D2 mechanics)

Product defects found while building: **tatrman / tatrman-platform issues** tagged
`fo-a1-demo` / `fo-a2-demo`, linked in a `findings.md` here; the demo build takes the
honest-degradation path meanwhile (the shipped CAP chips are presentable — narrate, don't
hide). Anything needing a *contract* change → ⚑ to Bora via the owning corpus, never a
silent local fork.
