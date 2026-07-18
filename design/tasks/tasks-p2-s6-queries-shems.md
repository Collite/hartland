# Stage 2.6 — Preferred queries (`q.hartland.*` #1–15) + both Shems

> **Phase 2, Stage 2.6.** Plan: [`../plan-demo-build.md`](../plan-demo-build.md) (§ Stage 2.6).
> Decisions: [`../08-czech-mirror-and-catalog-delta.md`](../08-czech-mirror-and-catalog-delta.md)
> — **BM-5** (drills re-expressed on the md star), **BM-6** (both Shems, cs prompts in scope),
> **Q-BM-4a** (new CZ personas + roles), **D-6a** (no profit).
> Query set + Shem overlays authority: `project/kantheon/design/demo-tpcds/05-d-ttrm-spec.md`
> (D-2 table #1–15; golem-hartland "Hartland Analytics"; golem-hartland-finance "Hartland
> Finance" F-1).
>
> **Goal:** the 15 `q.hartland.*` queries expressed on the model + both assembled Shems (en+cs
> example_questions, counter_examples, visibility_roles). This is the phase exit: every
> example_question resolves to a pattern plan; both Shems assemble.

## Where the code lives

```
model/queries/
├── q_hartland.ttrm        # T1 — def query for #1–15 (namespace q.hartland.*)
agents/
├── hartland.yaml          # T3 — the agent def (ai-models-analog, Ariadne source)
└── golem/shems/
    ├── golem-hartland/
    │   ├── shem.yaml       # T3 — "Hartland Analytics" overlay
    │   └── prompts/{en,cs}/  # T3/T5 — both prompt bundles (BM-6 — cs now in scope)
    └── golem-hartland-finance/
        ├── shem.yaml       # T4 — "Hartland Finance" overlay (F-1)
        └── prompts/{en,cs}/
```

Queries open `model query` (fixture `15-query.ttrm`); the Shem overlays are YAML (kantheon
assembled-Shem canon, golem-ucetnictvi precedent — mirror `agents/golem/shems/` layout).

## Library / syntax references (verified — do not guess)

- **`def query` (language, sourceText, params, search keywords):**
  `mnt/tatrman/tests/conformance/fixtures/15-query.ttrm`:
  ```ttrm
  model query
  def query topCustomers {
      language: SQL
      sourceText: """
          SELECT id, name FROM customers ORDER BY id DESC
      """
      parameters: [ { name: limit, type: int, label: "Limit" } ]
      search { keywords { en: ["customers", "clients"] }, searchable: true }
  }
  ```
  The `search { keywords { en: [...], cs: [...] } }` block carries the bilingual trigger words.
- **md drill expression:** drills #3/#4/#5 are re-expressed against the **md** dot-paths from
  Stage 2.3/2.4 (`marketplace.2025.november.revenue`, category/DC drills) rather than ad-hoc SQL
  where the shape allows — BM-5. Dot-path sugar: `mnt/tatrman/docs/features/md/dot-path-sugar.md`.
- **Query shape constraint (D-2):** stay within **proven Proteus unparse shapes** — join+group,
  agg+ORDER/LIMIT, window, CTE+UNION; conditional aggregation via **CASE-sums, NO `FILTER` clause**
  until a golden covers it. Year params default 2021–2026 (post-redate).
- **Proteus goldens are a kantheon service concern** (cross-repo, BM-9) — new goldens for the
  CASE-sum / md-derived shapes live with Proteus in kantheon; **referenced here, not authored
  here** (T2 is a hand-off + reference task, not a model-repo deliverable).
- **Shem overlay fields (05-d):** `agent_id`, display name/DomainCard, `area`, `visibility_roles`,
  `description_for_router`, `example_questions`, `counter_examples`, `locale_defaults`; template
  constants per canon (AREA_QA, theseus.query/compile, render.table/chart, INTERACTIVE).

## Pre-flight

- [ ] Stages 2.1–2.5 closed (db/er/md/binding/lexicon all resolve; `ResolveArea` green); branch
      `feat/p2-s6-queries-shems`.
- [ ] **Phase 1 CZ available** — cs example_questions are validated against `hartland_cz`; the cs
      lexicon (2.5) resolves. (This is the second Phase-1-CZ gate, per the plan-overview note.)
- [ ] The D-2 table (#1–15 with shapes/params) and both Shem specs (05-d) in hand.
- [ ] CZ persona roles known (Q-BM-4a): `kantheon-role-finance` (CFO — both worlds) and the CZ
      category-manager role alongside `kantheon-area-hartland` (Maya/Markéta Nováková). Confirm the
      exact role ids with the Keycloak realm owner (Phase 3 H3.2 wires them; here they're referenced
      in `visibility_roles`).

---

## Tasks

- [ ] **T1 — Author `q.hartland.*` #1–15 (`model/queries/q_hartland.ttrm`).**
  One `def query` per D-2 row, namespaced `q.hartland.*`, each with `language: SQL`, a `sourceText`
  triple-quoted body, `parameters` (typed, with `label`), and a `search { keywords { en:[...],
  cs:[...] } }` block. Map the D-2 shapes/params exactly:
  - #1 `channel_revenue_monthly` (join+group; `channel?, year_from, year_to`),
    #2 `channel_revenue_yoy` (CTE compare; `year, prior_year`),
    #3 `category_revenue` (join+group; `channel, year` — express via the Product md drill),
    #4 `marketplace_revenue_by_warehouse` (join+group; `year_from, year_to` — the DC drill / beat-3
    pivot), #5 `top_items_by_revenue` (agg+ORDER/LIMIT; `channel?, year, limit`),
    #6 `returns_by_reason` (join+group; `channel, year, quarter?` — resolves "Nedorazilo včas"),
    #7 `returns_rate_by_channel` (CTE sales⋈returns; `year`),
    #8 `warehouse_stockout_weeks` (join+group **CASE-sum**; `warehouse?, year` — the 17-week streak),
    #9 `inventory_on_hand_series` (join+group; `warehouse, year, category?`),
    #10 `customer_channel_overlap` (CTE + bool_or; `year`),
    #11 `revenue_by_customer_state` (join+group; `channel, year`),
    #12 `buyer_age_profile` (join+group; `channel, year`),
    #13 `promo_share` (**CASE-sum**; `channel, year`),
    #14 `store_sales_by_month` (join+group; no params — seed heritage),
    #15 `customer_running_total` (**window**; no params — window coverage).
  **Year params default into 2021–2026.** Keep every query within the proven unparse shapes
  (CASE-sums, no `FILTER`). **No query touches profit/cost** (D-6a — margin gaps gracefully). The
  `search.keywords` cs list uses the Stage 2.5 cs forms so the Discover chips trigger in Czech.

- [ ] **T2 — Proteus goldens hand-off (cross-repo reference, NOT a model deliverable).**
  For the **new** shapes (#8/#13 CASE-sum, the md-derived drills #3/#4), the PG unparse goldens are
  a kantheon Proteus service test asset (BM-9). Author a short reference note in
  `model/queries/README.md` listing which of the 15 need **new** goldens (the CASE-sum + md-derived
  ones; the join+group / window / CTE shapes are covered by existing Proteus goldens) and pointing
  at the kantheon Proteus golden dir. Open/track the kantheon-side task; do not write Proteus code
  here. The phase DONE bar's "goldens pass" is satisfied by that cross-repo task, referenced.

- [ ] **T3 — `golem-hartland` Shem overlay ("Hartland Analytics") + agent def.**
  Author `agents/hartland.yaml` (the ai-models-analog agent def — Ariadne source, Q-10 build-time
  concretization: mirror ai-models' agents/model/prompt layout) and
  `agents/golem/shems/golem-hartland/shem.yaml` per 05-d:
  - `agent_id: golem-hartland`, display name / DomainCard **"Hartland Analytics"**, `area: hartland`,
    `visibility_roles: [kantheon-area-hartland]`, `description_for_router` (the D-4 wording),
    `locale_defaults` (a per-delivery locale — en-US/USD **or** cs-CZ/CZK; BM-8 one-locale-per-delivery).
  - `example_questions` — the rehearsed beats, **en + cs** (BM-6): en "How did Marketplace revenue
    develop in 2025?" / "Which categories drove the H2 2025 drop?" / "What is our return rate by
    channel?" / "Which items were out of stock at Memphis DC in October 2025?" / "Compare Web and
    Marketplace revenue, 2024 vs 2025" / "Top products by revenue last year"; **cs mirrors** "Jak se
    vyvíjela tržba z tržiště v roce 2025?" / "Které kategorie způsobily propad v 2. pol. 2025?" /
    "Jaká je míra vrácení podle kanálu?" / "Které položky byly vyprodané v Brno DC v říjnu 2025?" …
    (cs uses the Brno DC / Czech places; en uses Memphis DC).
  - `counter_examples` (B-2 gap ammo): supplier contract terms, employee payroll, competitor
    pricing (+ "profitability/margin isn't modeled" — D-6a). Template constants per canon.
  - Mount `prompts/en/` and `prompts/cs/` (both bundles — cs no longer "unused per FI-4"; BM-6).

- [ ] **T4 — `golem-hartland-finance` Shem overlay ("Hartland Finance", F-1).**
  Author `agents/golem/shems/golem-hartland-finance/shem.yaml`: `agent_id: golem-hartland-finance`,
  DomainCard **"Hartland Finance"**, **same** `area: hartland` + same model (no new data),
  `visibility_roles: [kantheon-role-finance]` (CFO persona only — structurally unroutable for the
  category-manager persona, so B-2α holds), `description_for_router` "Financial analytics for
  Hartland Stores — returns exposure, revenue rollups." Preferred-query **subset**:
  `channel_revenue_yoy`, `returns_rate_by_channel` (+ optionally `returns_by_reason`).
  `example_questions` (en+cs): "What is our total returns exposure in dollars for 2025?" /
  "Revenue by channel, 2025 vs 2024?" + cs mirrors ("Jaká je celková expozice vrácení v korunách za
  2025?" / "Tržby podle kanálu, 2025 vs 2024?"). `counter_examples` shared with the main Shem; D-6a
  stands (no profitability anywhere). Mount both prompt bundles.

- [ ] **T5 — Persona roles → `visibility_roles` (Q-BM-4a).**
  Wire the persona roles: the US personas (Maya category manager → `kantheon-area-hartland`; Dan CFO
  → `kantheon-role-finance`) and the **new CZ personas** (Markéta Nováková, Senior Category Manager
  → the same `kantheon-area-hartland`; a CZ CFO → `kantheon-role-finance`). Record the mapping in
  `agents/README.md` and set `visibility_roles` on each Shem accordingly. The realm/Keycloak wiring
  is Phase 3 H3.2 — here it's the declared contract the Shems carry. Verify the **contrast**: the
  main Shem visible to the category-manager role; the finance Shem visible **only** to the finance
  role (absent for the category manager) — the governance cameo.

- [ ] **T6 — Verification (mocked): example_questions resolve; both Shems assemble (phase exit).**
  Mocked/unit (the LSP/semantics resolution harness + Shem-assembly checks per the kantheon
  assembled-Shem canon). Assert:
  1. **ListQueries = 15** — parsing `model/queries/q_hartland.ttrm` yields exactly the 15 named
     `q.hartland.*` queries, each with its declared params (types + labels).
  2. **Every example_question resolves to a pattern plan** — each en **and** cs example_question
     from both Shems maps to one of the 15 queries (via the Stage 2.5 lexicon triggers) — no
     free-SQL fallback except the one designed SHOULD moment; a cs question resolves to the same
     query as its en twin.
  3. **Both Shems assemble** — `golem-hartland` and `golem-hartland-finance` overlays parse, mount
     their prompt bundles (en+cs present), and register against `area: hartland`.
  4. **Visibility contrast** — the finance Shem's `visibility_roles` = `[kantheon-role-finance]`
     only; the main Shem's = `[kantheon-area-hartland]`; assert the finance Shem is **not** visible
     to the category-manager role.
  5. **No profit reachable** — no query/example resolves a profit/cost/margin path (D-6a); a
     margin probe gaps gracefully.
  6. **Phase-2 DONE roll-up** (assert the phase exit): model loads clean against **both**
     connection descriptors (schema-identical), `ResolveArea("hartland")` green, ListQueries = 15
     with params, cs+en lexicon resolves, both Shems assemble, no profit column reachable. (The
     Proteus goldens passing is the referenced kantheon cross-repo task, T2.)
  Run: `pnpm --filter @tatrman/integration-tests test -- queries` (+ the Shem-assembly checks).

## DONE bar (= the Phase 2 exit)

`model/queries/q_hartland.ttrm` declares the 15 `q.hartland.*` queries (D-2 shapes/params, year
default 2021–2026, within proven unparse shapes, no profit); both Shem overlays
(`golem-hartland` "Hartland Analytics", `golem-hartland-finance` "Hartland Finance") assemble with
en+cs example_questions, counter_examples, and the Q-BM-4a `visibility_roles`; **the phase exit
holds** — the model loads clean and resolves against **both** connections,
**`ResolveArea("hartland")` green**, **`ListQueries` returns 15 with params**, the new-shape
Proteus goldens pass (kantheon cross-repo, referenced), **no profit column reachable**, **cs + en
lexicon resolves**, and **both Shems assemble** with the CFO-only visibility contrast holding.
Committed on `feat/p2-s6-queries-shems`.

## Verify block

```sh
pnpm -r build
pnpm --filter @tatrman/integration-tests test -- queries    # ListQueries=15 + example_question→plan (en+cs) + Shem assemble
grep -cE 'def query' model/queries/q_hartland.ttrm           # == 15
grep -RnE 'net_profit|margin|cost|net_paid' model/queries    # → no matches (D-6a)
# Shem sanity: both shem.yaml parse; prompts/en + prompts/cs present under each; visibility_roles set
ls agents/golem/shems/golem-hartland/prompts/{en,cs} agents/golem/shems/golem-hartland-finance/prompts/{en,cs}
```

*(Proteus PG-unparse goldens for the new CASE-sum / md-derived shapes are a kantheon service test
asset (BM-9) — tracked as the T2 cross-repo hand-off, not run in this model-repo stage. The live
both-worlds resolution + persona routing is Phase 3 H3.)*
