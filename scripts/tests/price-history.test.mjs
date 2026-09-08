// IE-P1·S1.5·T0c — the three properties IE-C64 names, plus the two that make them meaningful.
//
// Run: node --test scripts/tests/price-history.test.mjs
//
// These run against the PURE generator — no database, no network, no clock — which is the only way
// "two runs produce identical proposals" is a property rather than an anecdote about one afternoon.

import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  buildBatches,
  monthEndsBetween,
  simulateSeries,
  totalReturn,
  seedOf,
} from '../lib/price-history.mjs';

// A slice of the real anchors, copied off hartland (`investment_asset_price` joined to the ISINs the
// estate has ever held). Real ISINs, real prices, real month-end dates — including the spread that
// matters: these instruments are last priced in DIFFERENT months, which is instrument staleness, not
// history, and is why the walk is backwards-only.
const ANCHORS = [
  { isin: 'CZ0008044328', anchorDate: '2025-12-31', anchorPrice: '1.454300', currency: 'CZK' },
  { isin: 'CZ0008045044', anchorDate: '2026-07-31', anchorPrice: '1.561500', currency: 'CZK' },
  { isin: 'CZ0008045168', anchorDate: '2025-12-31', anchorPrice: '0.219510', currency: 'EUR' },
  { isin: 'CZ0008045580', anchorDate: '2026-06-30', anchorPrice: '1.734900', currency: 'CZK' },
];
const FROM = '2024-09-30';

test('the month-end grid is month ENDS, and handles February and year boundaries', () => {
  const g = monthEndsBetween('2024-12-15', '2025-04-02');
  assert.deepEqual(g, ['2024-12-31', '2025-01-31', '2025-02-28', '2025-03-31']);
  assert.deepEqual(monthEndsBetween('2028-01-01', '2028-03-01'), ['2028-01-31', '2028-02-29']);
});

test('(b) the anchor is the PROVIDER\'s number, untouched, and it is the last point', () => {
  // The stage's current figures must be Conseq's. Only history is ours — so the series ends exactly
  // on the real observation, at the real date, to the digit.
  for (const a of ANCHORS) {
    const s = simulateSeries({ ...a, from: FROM });
    const last = s[s.length - 1];
    assert.equal(last.price_date, a.anchorDate);
    assert.equal(last.price, Number(a.anchorPrice));
    assert.equal(last.currency, a.currency);
    // …and nothing is invented AFTER it.
    assert.ok(s.every((r) => r.price_date <= a.anchorDate));
  }
});

test('(a) determinism — two runs are byte-identical, and the seed is the ISIN', () => {
  const one = JSON.stringify(buildBatches({ anchors: ANCHORS, from: FROM, batchId: (d) => `sim-${d}` }));
  const two = JSON.stringify(buildBatches({ anchors: [...ANCHORS].reverse(), from: FROM, batchId: (d) => `sim-${d}` }));
  // Identical even though the anchors arrived in a different ORDER: the seed comes from the
  // instrument, so nothing depends on iteration order, a run counter or a clock. IE-C61 promises a
  // reset reproduces the estate; that is only true if this holds.
  assert.equal(one, two);
  assert.notEqual(seedOf('CZ0008044328'), seedOf('CZ0008045044'));
});

test('(c) a meaningful minority FALL over the window — IE-C62 asks which portfolios lost value', () => {
  // Generated across the real held-ISIN population size (56) so the proportion is measured, not
  // assumed from four samples.
  const many = Array.from({ length: 56 }, (_, i) => ({
    isin: `TEST${String(i).padStart(8, '0')}`,
    anchorDate: '2026-06-30',
    anchorPrice: '100.000000',
    currency: 'CZK',
  }));
  const fallen = many.filter((a) => totalReturn(simulateSeries({ ...a, from: FROM })) < 0);
  const share = fallen.length / many.length;
  // A MINORITY (an estate where most things fall is not the story either), and MEANINGFUL (one
  // unlucky instrument out of 56 would let a reviewer call the losers a rounding artefact).
  assert.ok(share > 0.15, `only ${(share * 100).toFixed(0)}% fell — too few to answer IE-C62`);
  assert.ok(share < 0.5, `${(share * 100).toFixed(0)}% fell — an estate in freefall is not the demo`);
});

test('prices stay positive and move plausibly — no fund NAV halves in a month', () => {
  for (const a of ANCHORS) {
    const s = simulateSeries({ ...a, from: FROM });
    assert.ok(s.every((r) => r.price > 0), 'a non-positive NAV would be visible nonsense on stage');
    for (let i = 1; i < s.length; i++) {
      const step = Math.abs(s[i].price / s[i - 1].price - 1);
      assert.ok(step <= 0.14, `${a.isin} moved ${(step * 100).toFixed(1)}% in one month`);
    }
  }
});

test('batches are one per month-end, exclude the anchor row, and are labelled synthetic', () => {
  const batches = buildBatches({ anchors: ANCHORS, from: FROM, batchId: (d) => `sim-${d}` });
  const dates = batches.map((b) => b.source.ref.replace('sim-prices/', ''));
  assert.deepEqual(dates, [...dates].sort(), 'batches ascend by month-end');
  assert.ok(dates.every((d) => d < '2026-07-31'), 'no batch at or after the newest anchor');

  for (const b of batches) {
    assert.equal(b.kind, 'row-proposal');
    // §5's target oneOf — the live half only. `table` must be ABSENT, not null: a null sibling makes
    // the payload match neither branch and the ingress validator refuses it (IE-P1·S1.3·D2).
    assert.deepEqual(Object.keys(b.target).sort(), ['entity', 'lowering']);
    // ⚑ The label is the claim. A synthetic row that says so keeps "every row walks backwards to
    // what produced it" true.
    assert.equal(b.source.pluginId, 'sim-prices');
    assert.ok(b.proposals.length > 0);
    for (const p of b.proposals) {
      assert.deepEqual(Object.keys(p.key).sort(), ['isin', 'price_date']);
      // §5 REQUIRES these three present, null and all.
      assert.ok('baseRowVersion' in p && 'effectiveDate' in p && 'key' in p);
    }
  }

  // Every instrument reaches the oldest month-end: a portfolio valued at the window start must not
  // be missing a price for something it held.
  const oldest = batches[0];
  assert.equal(oldest.proposals.length, ANCHORS.length);
});
