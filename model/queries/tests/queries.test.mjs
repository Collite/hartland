// Stage 2.6 T6.1 — ListQueries = 15 with declared params; no profit/cost.
// Mocked/unit: parses the whole model/ tree as one project (project-harness.mjs), no
// live DB (the 15 queries were also EXPLAIN-verified against live hartland_us ad hoc —
// see model/queries/README.md — but that's a bonus check, not part of this suite).
// Run: node --test model/queries/tests/queries.test.mjs (from the hartland repo root).

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { loadHartlandProject, ACCEPTED_RESIDUAL_CODES } from '../../tests/project-harness.mjs';

const EXPECTED_QUERIES = [
  'channel_revenue_monthly', 'channel_revenue_yoy', 'category_revenue',
  'marketplace_revenue_by_warehouse', 'top_items_by_revenue', 'returns_by_reason',
  'returns_rate_by_channel', 'warehouse_stockout_weeks', 'inventory_on_hand_series',
  'customer_channel_overlap', 'revenue_by_customer_state', 'buyer_age_profile',
  'promo_share', 'store_sales_by_month', 'customer_running_total',
];

const BANNED_TOKENS = ['net_profit', 'margin', 'wholesale_cost', 'list_price', 'net_paid'];

const project = await loadHartlandProject();

function allQueries() {
  const out = [];
  for (const [uri, ast] of project.asts) {
    for (const def of ast.definitions ?? []) {
      if (def.kind === 'query') out.push({ def, uri });
    }
  }
  return out;
}

test('T6.1 — parse-clean: q_hartland.ttrm parses with zero errors', () => {
  const errors = project.parseErrorsByFile.get('model/queries/q_hartland.ttrm');
  assert.ok(errors !== undefined, 'file not found by the harness');
  assert.deepEqual(errors, [], `parse errors: ${JSON.stringify(errors)}`);
});

test('T6.2 — ListQueries = 15, exactly the D-2 roster, each with typed+labeled params', () => {
  const queries = allQueries();
  const names = queries.map(({ def }) => def.name);
  assert.deepEqual([...names].sort(), [...EXPECTED_QUERIES].sort());
  assert.equal(queries.length, 15);
  for (const { def } of queries) {
    for (const p of def.parameters ?? []) {
      assert.ok(p.type, `${def.name}.${p.name} has no type`);
      assert.ok(p.label, `${def.name}.${p.name} has no label`);
    }
    assert.equal(def.language, 'SQL', `${def.name}: language must be SQL`);
    assert.ok(def.sourceText?.value?.length > 0, `${def.name}: empty sourceText`);
  }
});

test('T6.3 — year params default range 2021-2026 is documented (spot-check labels mention year)', () => {
  const yearParamNames = new Set(['year', 'year_from', 'year_to', 'prior_year']);
  const queries = allQueries();
  let sawYearParam = false;
  for (const { def } of queries) {
    for (const p of def.parameters ?? []) {
      if (yearParamNames.has(p.name)) {
        sawYearParam = true;
        assert.equal(p.type?.name, 'int', `${def.name}.${p.name} should be int`);
      }
    }
  }
  assert.ok(sawYearParam, 'expected at least one year-shaped param across the 15 queries');
});

test('T6.4 — no profit/cost/margin token anywhere in the queries file', () => {
  const offenders = [];
  for (const { def, uri } of allQueries()) {
    const text = def.sourceText?.value ?? '';
    for (const token of BANNED_TOKENS) {
      if (text.toLowerCase().includes(token)) offenders.push(`${uri}: ${def.name} contains '${token}'`);
    }
  }
  assert.deepEqual(offenders, [], `banned tokens found: ${offenders.join('; ')}`);
});

test('T6.5 — no unexpected diagnostics from the queries file (project-wide sweep still clean)', () => {
  const codes = project.diagnosticsByFile.get('model/queries/q_hartland.ttrm') ?? new Set();
  const real = [...codes].filter((c) => !ACCEPTED_RESIDUAL_CODES.has(c));
  assert.deepEqual(real, [], `unexpected diagnostics: ${real.join(', ')}`);
});

test('T6.6 — no query carries a `search { keywords }` block (RS-32 legacy — ttr/lexicon-legacy-keywords)', () => {
  // Real finding: the 15-query.ttrm conformance fixture's own `search { keywords {...} } }`
  // pattern is ITSELF a deprecated legacy form (RS-32 migrated it to locale-keyed lexicon
  // `term` entries). Discover-chip triggering rides Stage 2.5's lexicon terms over the
  // channel/measure/dimension carriers instead — this test guards against silently
  // reintroducing the legacy form (which would trip ttr/lexicon-legacy-keywords, covered
  // by T6.5's project-wide sweep, but asserted directly here too).
  const offenders = allQueries().filter(({ def }) => def.search != null).map(({ def }) => def.name);
  assert.deepEqual(offenders, [], `queries still carrying legacy search{}: ${offenders.join(', ')}`);
});
