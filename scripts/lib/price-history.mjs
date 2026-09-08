// IE-C64 — the simulated price history (⚑IE-12, ruled by Bora 2026-09-07: *simulate it, with some
// evolution*).
//
// DistrInfo's `Prices` method is CURRENT market data: one row per ISIN at that instrument's own last
// price date, and nothing behind it (IE-P0 V3b, re-measured at IE-P1·S1.5 — `max(rows per ISIN) = 1`
// across 2016 ISINs). IE-C30 values a past quarter as `Σ holdings(Q) × latest price ≤ Q`, so without
// history the demo's centrepiece reports `price_coverage: missing` on every historical row.
//
// This file is the PURE half — no database, no network, no clock. It is what the tests exercise, and
// keeping it pure is what makes "two runs produce identical proposals" a property you can check in
// milliseconds rather than a claim about a script that talks to a cluster.

/** Month-end grid. Quarter ends are what IE-C30 reads; the intermediate months cost nothing and make a chart plausible. */
export function monthEndsBetween(fromIso, toIso) {
  const out = [];
  const to = new Date(`${toIso}T00:00:00Z`);
  const from = new Date(`${fromIso}T00:00:00Z`);
  const cur = new Date(Date.UTC(from.getUTCFullYear(), from.getUTCMonth() + 1, 0));
  while (cur <= to) {
    out.push(cur.toISOString().slice(0, 10));
    cur.setUTCMonth(cur.getUTCMonth() + 2, 0); // month+1's day 0 = end of month+1
  }
  return out;
}

/**
 * FNV-1a over the ISIN. The seed must come from the INSTRUMENT, not from a run counter or a clock:
 * IE-C61 promises that a reset reproduces the estate, and the report fingerprint and the rehearsal
 * bar ("the same numbers twice") are worthless if reseeding shuffles the series.
 */
export function seedOf(isin) {
  let h = 0x811c9dc5;
  for (let i = 0; i < isin.length; i++) {
    h ^= isin.charCodeAt(i);
    h = Math.imul(h, 0x01000193) >>> 0;
  }
  return h >>> 0;
}

/** mulberry32 — small, fast, and stable across Node versions, which `Math.random` is not. */
export function rng(seed) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

// Monthly drift is drawn per ISIN and held for the whole walk. The band is deliberately asymmetric
// and deliberately straddles zero: ~29% of instruments draw a negative drift, which is the
// "meaningful minority of instruments FALL" the ruling asks for. IE-C62's acceptance question is
// *"which portfolios lost value this quarter?"* — a uniformly rising estate cannot answer it, and an
// estate where everything falls is not a story anyone would show either.
const DRIFT_MIN = -0.004;
const DRIFT_MAX = 0.010;
// Month-on-month noise. Funds are not equities; ±12% in a month would read as a data error on stage.
const VOL = 0.018;
const CLAMP = 0.12;
/** DistrInfo quotes fund NAVs at 6 dp (`1.454300`), so the synthetic rows match the real ones. */
const DP = 6;

/**
 * The series for ONE instrument, walked BACKWARDS from its real anchor.
 *
 * Backwards only, never forwards: the most recent point must be the provider's actual number, so
 * today's figures on stage are theirs and only history is ours. It also needs no forward-fill —
 * IE-C30 reads "the latest price ≤ Q", so an instrument last priced in 2025-12 correctly carries
 * that price into 2026's quarters without anyone inventing one.
 *
 * @returns rows ascending by date; the LAST is the untouched anchor.
 */
export function simulateSeries({ isin, anchorDate, anchorPrice, currency, from }) {
  const grid = monthEndsBetween(from, anchorDate).filter((d) => d < anchorDate);
  const next = rng(seedOf(isin));
  const drift = DRIFT_MIN + next() * (DRIFT_MAX - DRIFT_MIN);

  // Walk back from the anchor: price[t-1] = price[t] / (1 + r_t).
  const back = [];
  let price = Number(anchorPrice);
  for (let i = grid.length - 1; i >= 0; i--) {
    const shock = (next() - 0.5) * 2 * VOL;
    const r = Math.max(-CLAMP, Math.min(CLAMP, drift + shock));
    price = price / (1 + r);
    back.push({ isin, price_date: grid[i], price: round(price), currency });
  }
  back.reverse();
  return [...back, { isin, price_date: anchorDate, price: round(Number(anchorPrice)), currency }];
}

function round(x) {
  return Number(x.toFixed(DP));
}

/**
 * Every instrument's series, grouped into ONE BATCH PER MONTH-END (IE-C64).
 *
 * Per month-end rather than per instrument because that is the shape the estate already receives
 * prices in — the connector submits one `PRICES` batch covering every ISIN — so the journal reads
 * the same way for the real rows and the synthetic ones, and a reviewer comparing them is comparing
 * like with like.
 *
 * The anchor row is NOT re-submitted: it is already in the table, delivered by the provider, and
 * re-writing it under `sim-prices` would relabel a real observation as synthetic.
 */
export function buildBatches({ anchors, from, modelVersion = 'investment-v1', batchId }) {
  const byDate = new Map();
  for (const a of [...anchors].sort((x, y) => (x.isin < y.isin ? -1 : 1))) {
    const series = simulateSeries({ ...a, from });
    for (const row of series.slice(0, -1)) {
      if (!byDate.has(row.price_date)) byDate.set(row.price_date, []);
      byDate.get(row.price_date).push(row);
    }
  }
  return [...byDate.keys()]
    .sort()
    .map((date) => ({
      batchId: batchId(date),
      kind: 'row-proposal',
      // §5's oneOf, the live half only. The connector's own price batches target the ENTITY
      // (`investment.asset_price` lowered v1), so these land through the same apply program.
      target: { entity: 'investment.asset_price', lowering: 'v1' },
      modelVersion,
      proposals: byDate.get(date).map((r) => ({
        // `update`, keyed on (isin, price_date) — the shape the connector's PRICES leg uses, so the
        // apply program's upsert path is the one exercised. Copied from a real journalled batch
        // rather than guessed.
        op: 'update',
        key: { isin: r.isin, price_date: r.price_date },
        values: { isin: r.isin, price_date: r.price_date, price: String(r.price), currency: r.currency },
        baseRowVersion: null,
        effectiveDate: null,
      })),
      source: {
        type: 'import',
        ref: `sim-prices/${date}`,
        // ⚑ The label is the whole point (IE-C64). A synthetic row that SAYS it is synthetic keeps
        // the demo's "every row walks backwards to what produced it" claim true; a direct INSERT
        // would break it silently.
        pluginId: 'sim-prices',
        pluginVersion: '1.0.0',
      },
    }));
}

/** Total return over the generated window — what "did this instrument fall?" means. */
export function totalReturn(series) {
  return series[series.length - 1].price / series[0].price - 1;
}
