#!/usr/bin/env node
// IE-P1·S1.5·T0c — seed the simulated price history (IE-C64).
//
//   node scripts/seed-price-history.mjs --anchors anchors.json [--from 2024-09-30] [--submit]
//
// Reads ANCHORS (one real `Prices` row per instrument the estate has ever held) as JSON on stdin or
// from --anchors, generates each instrument's series BACKWARDS from its own anchor, and — with
// --submit — writes them through the entry substrate as §5 batches under `sourcePluginId:
// sim-prices`. Without --submit it prints what it would do and writes nothing, which is how you look
// at the numbers before they are in the estate.
//
// ⚑ Never a direct INSERT. The demo's claim is that any row walks backwards to what produced it; a
// synthetic row that is LABELLED synthetic in the journal keeps that claim true (IE-C64).
//
// The generation itself is in lib/price-history.mjs and is pure — this file is only I/O.

import { readFileSync } from 'node:fs';
import { randomUUID } from 'node:crypto';
import { buildBatches, simulateSeries, totalReturn } from './lib/price-history.mjs';

const args = process.argv.slice(2);
const flag = (name, fallback = undefined) => {
  const i = args.indexOf(`--${name}`);
  return i >= 0 && args[i + 1] !== undefined && !args[i + 1].startsWith('--') ? args[i + 1] : fallback;
};
const has = (name) => args.includes(`--${name}`);

const entryUrl = flag('entry-url', process.env.ENTRY_URL ?? 'http://localhost:18080');
const bearer = process.env.ENTRY_BEARER ?? '';
const submit = has('submit');

// Default window: 8 quarters back, month-aligned. IE-C31's `quarters` defaults to 4, so this covers
// the default report twice over — the intermediate months "cost nothing" (IE-C64) and a `quarters=8`
// run should not need a re-seed.
const from = flag('from', defaultFrom());
function defaultFrom() {
  const d = new Date();
  d.setUTCMonth(d.getUTCMonth() - 24, 1);
  return d.toISOString().slice(0, 10);
}

const raw = flag('anchors') ? readFileSync(flag('anchors'), 'utf8') : readFileSync(0, 'utf8');
const anchors = JSON.parse(raw);
if (!Array.isArray(anchors) || anchors.length === 0) {
  fail('anchors must be a non-empty JSON array of {isin, anchorDate, anchorPrice, currency}');
}
for (const a of anchors) {
  for (const k of ['isin', 'anchorDate', 'anchorPrice', 'currency']) {
    if (a[k] == null || a[k] === '') fail(`anchor ${JSON.stringify(a)} is missing ${k}`);
  }
}

// A deterministic batchId, so a re-run REPLACES its own batches rather than journalling a second
// copy of the same history beside the first. The estate's `start over` is not the only way this
// script gets run twice.
const batches = buildBatches({ anchors, from, batchId: (date) => `sim-prices-${date}` });

const rows = batches.reduce((n, b) => n + b.proposals.length, 0);
const fallen = anchors.filter((a) => totalReturn(simulateSeries({ ...a, from })) < 0);

console.log(`sim-prices — window ${from} .. (each instrument's own anchor)`);
console.log(`  instruments : ${anchors.length}`);
console.log(`  batches     : ${batches.length}  (one per month-end, ${batches[0]?.source.ref.split('/')[1]} … ${batches.at(-1)?.source.ref.split('/')[1]})`);
console.log(`  rows        : ${rows}`);
console.log(`  falling     : ${fallen.length}/${anchors.length} (${((fallen.length / anchors.length) * 100).toFixed(0)}%) — IE-C62 needs losers to exist`);

if (!submit) {
  console.log('\n(dry run — pass --submit to write them through the door)');
  process.exit(0);
}
if (!bearer) fail('ENTRY_BEARER is required to submit (the substrate is on jwks; see apps/investment-door/README.md)');

let journalled = 0;
let committed = 0;
for (const batch of batches) {
  const body = JSON.stringify(batch);
  // AUTOCOMMIT is two calls, exactly as the door does it: journal first so the batch exists to
  // replay from, then apply. A commit whose journal write failed would be a row with no provenance.
  await post(`${entryUrl}/v1/batches?intent=auto`, body, `journal ${batch.batchId}`);
  journalled++;
  await post(`${entryUrl}/v1/apply/commit`, body, `commit ${batch.batchId}`);
  committed++;
  process.stdout.write(`\r  submitted ${committed}/${batches.length}`);
}
console.log(`\n✅ ${journalled} journalled, ${committed} committed, ${rows} price rows under sourcePluginId=sim-prices`);

async function post(url, body, what) {
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'content-type': 'application/json', authorization: `Bearer ${bearer}` },
    body,
  });
  if (!res.ok) {
    // Print the substrate's own code — it is the one sentence that says what to fix.
    fail(`${what} → ${res.status} ${await res.text()}`);
  }
  return res;
}

function fail(msg) {
  console.error(`❌ ${msg}`);
  process.exit(1);
}
