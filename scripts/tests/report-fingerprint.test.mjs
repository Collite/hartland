// IE-P3·S3.3 — `scripts/report-fingerprint.sh` driven against a stub studio-bff, a canned psql and a
// workbook this suite writes itself.
//
// Run: node --test scripts/tests/report-fingerprint.test.mjs
//
// The fingerprint's whole job is to say whether the report a client downloads agrees with the book.
// That claim is only worth something if it can FAIL, so every check here is shown failing against a
// workbook that is wrong on purpose — a cent too far, a currency missing, a coverage word changed —
// and each failure has to NAME what disagreed. The two ruled differences (per-line rounding, S3.1·D7;
// an `as_of` on a quarter end, S3.1·D2) are asserted as ACCEPTED and REFUSED respectively, because
// both would otherwise read as defects.
//
// No estate, no database, no renderer: a stub BFF answers `/api/reports/*`, a fake `psql` prints a
// canned answer, and `fakes/xlsx.mjs` writes the workbook.

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { spawn, execFileSync } from 'node:child_process';
import { createServer } from 'node:http';
import { chmodSync, mkdirSync, mkdtempSync, readFileSync, writeFileSync, existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { writeWorkbook } from './fakes/xlsx.mjs';

const here = path.dirname(fileURLToPath(import.meta.url));
const SCRIPT = path.resolve(here, '../report-fingerprint.sh');
const PORTFOLIO = 'conseq:900000001';
const AS_OF = '2026-08-31';

/** The Summary sheet's header row (IE-C34), in the template author's order. */
const HEADERS = ['Period end', 'Currency', 'Total value', 'Market value', 'Cash', 'Net flows', 'P&L', 'Return %', 'Coverage'];

/** One §4.1 row, as the two sides each spell it. */
const ROWS = [
  { period: '2025-09-30', ccy: 'CZK', total: 995000, market: 700000, cash: 295000, flow: 995000, pnl: 0, ret: null, cover: 'full' },
  { period: '2025-12-31', ccy: 'CZK', total: 1220000, market: 875000, cash: 345000, flow: 200000, pnl: 25000, ret: 2.512563, cover: 'full' },
  { period: '2026-03-31', ccy: 'CZK', total: 1379800, market: 874800, cash: 505000, flow: 125000, pnl: 34800, ret: 2.852459, cover: 'stale:2026-03-15' },
  { period: '2026-06-30', ccy: 'EUR', total: 3025, market: 3025, cash: 0, flow: 0, pnl: 125, ret: 4.310345, cover: 'missing:1' },
];

function sheetRows(rows) {
  return [
    [{ text: 'Quarterly evolution — a portfolio' }],
    [],
    HEADERS.map((h) => ({ text: h })),
    ...rows.map((r) => [
      { date: r.period },
      { text: r.ccy },
      { number: r.total },
      { number: r.market },
      { number: r.cash },
      { number: r.flow },
      { number: r.pnl },
      r.ret == null ? null : { number: r.ret },
      { text: r.cover },
    ]),
    [{ text: 'Return % = P&L ÷ opening value, in percent (not time-weighted).' }],
  ];
}

/** psql's own shape: §4.1's eleven columns, unaligned, `-F,`, SQL NULL as an empty field. */
function referenceCsv(rows) {
  return rows
    .map((r) => [
      PORTFOLIO, r.period, 'f', r.ccy,
      r.market.toFixed(2), r.cash.toFixed(2), r.total.toFixed(2), r.flow.toFixed(2), r.pnl.toFixed(2),
      r.ret == null ? '' : r.ret.toFixed(6), r.cover,
    ].join(','))
    .join('\n') + '\n';
}

/** A model file holding the one query the script lifts its SQL out of. */
const MODEL = `
def query positions_at {
    sourceText: """
        SELECT 1
    """
}

def query quarterly_evolution {
    description: "the reference"
    language: SQL
    sourceText: """
        SELECT * FROM reference
         WHERE portfolio_ref = {portfolio_id}
           AND period_end <= ({as_of})::date
         LIMIT ({quarters})::int
    """
    parameters: [ { name: "portfolio_id" } ]
}
`;

function harness(opts = {}) {
  const dir = mkdtempSync(path.join(tmpdir(), 'ie-fp-'));
  const calls = [];

  const workbook = path.join(dir, 'report.xlsx');
  writeWorkbook(workbook, [{ name: 'Summary', rows: sheetRows(opts.workbookRows ?? ROWS) }]);
  if (opts.artifactBody) writeFileSync(workbook, opts.artifactBody);

  writeFileSync(path.join(dir, 'model.ttrm'), opts.model ?? MODEL);
  writeFileSync(path.join(dir, 'reference.csv'), referenceCsv(opts.referenceRows ?? ROWS));

  // A fake `psql`: it proves the script BOUND every parameter (the SQL it is handed must carry no
  // `{…}` left) and then prints the canned answer.
  const psql = path.join(dir, 'psql');
  writeFileSync(
    psql,
    `#!/usr/bin/env node
const { readFileSync, writeFileSync } = require('node:fs');
const args = process.argv.slice(2);
const file = args[args.indexOf('-f') + 1];
const sql = readFileSync(file, 'utf8');
writeFileSync(${JSON.stringify(path.join(dir, 'psql-saw.sql'))}, sql);
if (/\\{[a-z_]+\\}/.test(sql)) { console.error('unbound parameter reached psql'); process.exit(1); }
process.stdout.write(readFileSync(${JSON.stringify(path.join(dir, 'reference.csv'))}, 'utf8'));
`,
    { mode: 0o755 },
  );
  chmodSync(psql, 0o755);

  const server = createServer((req, res) => {
    calls.push(`${req.method} ${req.url}`);
    const json = (status, body) => {
      res.writeHead(status, { 'content-type': 'application/json' });
      res.end(JSON.stringify(body));
    };
    if (req.method === 'POST' && req.url === '/api/reports/render') {
      let body = '';
      req.on('data', (c) => (body += c));
      req.on('end', () => {
        calls.push(`render ${body}`);
        if (opts.renderRefusal) return json(opts.renderRefusal.status, opts.renderRefusal.body);
        json(200, { artifactId: 'a-1', artifactUrl: '/artifacts/a-1', sizeBytes: '5922', mimeType: 'xlsx' });
      });
      return;
    }
    if (req.method === 'GET' && req.url.startsWith('/api/reports/artifacts/')) {
      res.writeHead(200, { 'content-type': 'application/octet-stream' });
      res.end(readFileSync(workbook));
      return;
    }
    json(404, { code: 'NOT_FOUND', message: req.url });
  });

  return { dir, calls, server, psql };
}

function run(h, extraEnv = {}, args = []) {
  const { port } = h.server.address();
  const env = {
    ...process.env,
    PATH: `${h.dir}:${process.env.PATH}`,
    IE_FP_BFF: `http://127.0.0.1:${port}`,
    IE_FP_BEARER: 'tok-1',
    IE_FP_DSN: 'postgresql://fake/entry',
    IE_FP_PORTFOLIO: PORTFOLIO,
    IE_FP_AS_OF: AS_OF,
    IE_FP_QUARTERS: '4',
    IE_FP_MODEL: path.join(h.dir, 'model.ttrm'),
    ...extraEnv,
  };
  return new Promise((resolve) => {
    const proc = spawn('bash', [SCRIPT, ...args], { env, cwd: h.dir });
    let out = '';
    proc.stdout.on('data', (c) => (out += c));
    proc.stderr.on('data', (c) => (out += c));
    proc.on('close', (code) => resolve({ code, out }));
  });
}

async function withHarness(opts, body) {
  const h = harness(opts);
  await new Promise((r) => h.server.listen(0, '127.0.0.1', r));
  try {
    return await body(h);
  } finally {
    h.server.close();
  }
}

test('the tools the fingerprint needs are on PATH', () => {
  for (const tool of ['bash', 'curl', 'jq', 'python3']) {
    assert.doesNotThrow(() => execFileSync('sh', ['-c', `command -v ${tool}`]), `${tool} is not on PATH`);
  }
});

test('a workbook that matches the book passes, and says what it compared', async () => {
  await withHarness({}, async (h) => {
    const { code, out } = await run(h);
    assert.equal(code, 0, out);
    assert.match(out, /workbook vs book agree/);
    assert.match(out, /the report matches the book/);
    // the render went through the tile's own route, with the args as STRINGS (the proto's args_json)
    const render = h.calls.find((c) => c.startsWith('render '));
    assert.deepEqual(JSON.parse(render.slice('render '.length)), {
      templateId: 'investment-evolution:v1',
      args: { portfolio_id: PORTFOLIO, as_of: AS_OF, quarters: '4' },
    });
    assert.ok(h.calls.includes(`GET /api/reports/artifacts/a-1?asOf=${AS_OF}`), h.calls.join('\n'));
  });
});

test('⛔ a cent too far FAILS, naming the row, the column and the gap', async () => {
  const wrong = ROWS.map((r, i) => (i === 1 ? { ...r, total: r.total + 0.02 } : r));
  await withHarness({ workbookRows: wrong }, async (h) => {
    const { code, out } = await run(h);
    assert.equal(code, 1, out);
    assert.match(out, /2025-12-31 CZK total_value/);
    assert.match(out, /off by 0\.02/);
  });
});

test('⚑ a difference INSIDE the ruled rounding tolerance passes (S3.1·D7)', async () => {
  // The renderer rounds each currency's period total; the reference rounds each holding line first.
  // A cent of disagreement is the ruled consequence, not a defect — and the run says so.
  const rounded = ROWS.map((r, i) => (i === 2 ? { ...r, market: r.market + 0.01 } : r));
  await withHarness({ workbookRows: rounded }, async (h) => {
    const { code, out } = await run(h);
    assert.equal(code, 0, out);
    assert.match(out, /money to ±0\.01/);
  });
});

// ⚑ Measured on hartland 2026-09-14: every money column agreed to the cent and the RETURN was apart by
// 0.000008 percentage points, because the two sides round at different moments and a ratio amplifies
// it (S3.1·D7). The sheet prints two decimals, so this must pass — and a real error must not.
test('⚑ a return apart by rounding ORDER passes; one that is actually wrong fails', async () => {
  const nudged = ROWS.map((r, i) => (i === 1 ? { ...r, ret: r.ret + 0.000008 } : r));
  await withHarness({ workbookRows: nudged }, async (h) => {
    const { code, out } = await run(h);
    assert.equal(code, 0, out);
    assert.match(out, /return % to ±0\.0001/);
  });

  const wrong = ROWS.map((r, i) => (i === 1 ? { ...r, ret: r.ret + 0.01 } : r));
  await withHarness({ workbookRows: wrong }, async (h) => {
    const { code, out } = await run(h);
    assert.equal(code, 1, out);
    assert.match(out, /2025-12-31 CZK return_q_pct/);
  });
});

test('⛔ a currency the workbook left out FAILS — a short report is not a passing one', async () => {
  await withHarness({ workbookRows: ROWS.slice(0, 3) }, async (h) => {
    const { code, out } = await run(h);
    assert.equal(code, 1, out);
    assert.match(out, /2026-06-30 EUR: in book, absent from workbook/);
  });
});

test('⛔ a coverage word that disagrees FAILS — the prices behind a number are part of it', async () => {
  const wrong = ROWS.map((r, i) => (i === 3 ? { ...r, cover: 'full' } : r));
  await withHarness({ workbookRows: wrong }, async (h) => {
    const { code, out } = await run(h);
    assert.equal(code, 1, out);
    assert.match(out, /price_coverage: workbook='full' book='missing:1'/);
  });
});

// ⚑ Rows are matched on (period_end, currency) through a dict, which cannot see a SECOND copy of a
// key: both copies compare against the one row on the other side and agree. So a duplicate is refused
// before any comparison — on either side, because both sides can produce one (review-093 ⑶).
test('⛔ a quarter the WORKBOOK reports twice FAILS — two copies that each "agree" are not a match', async () => {
  await withHarness({ workbookRows: [...ROWS, ROWS[1]] }, async (h) => {
    const { code, out } = await run(h);
    assert.equal(code, 1, out);
    assert.match(out, /2025-12-31 CZK: workbook reports this period 2 times/);
  });
});

test('⛔ a quarter the BOOK reports twice FAILS — the quarter-end double row is the reachable case', async () => {
  await withHarness({ referenceRows: [...ROWS, ROWS[2]] }, async (h) => {
    const { code, out } = await run(h);
    assert.equal(code, 1, out);
    assert.match(out, /2026-03-31 CZK: book reports this period 2 times/);
  });
});

test('⛔ an as_of ON a quarter end is refused before anything is sent (S3.1·D2)', async () => {
  await withHarness({}, async (h) => {
    const { code, out } = await run(h, { IE_FP_AS_OF: '2026-06-30' });
    assert.equal(code, 1, out);
    assert.match(out, /quarter end/);
    assert.match(out, /reports the day twice/);
    assert.deepEqual(h.calls, [], 'nothing may be sent when the date itself is refused');
  });
});

test('⛔ a refused render shows the RENDERER’s own code and sentence', async () => {
  const refusal = { status: 400, body: { code: 'invalid_args', message: "parameter 'quarters' must be at most 12, got 13" } };
  await withHarness({ renderRefusal: refusal }, async (h) => {
    const { code, out } = await run(h);
    assert.equal(code, 1, out);
    assert.match(out, /invalid_args/);
    assert.match(out, /must be at most 12/);
  });
});

test('⛔ an artifact that is not a workbook is named, not parsed', async () => {
  await withHarness({ artifactBody: Buffer.from('{"code":"UPSTREAM_UNAVAILABLE"}') }, async (h) => {
    const { code, out } = await run(h);
    assert.equal(code, 1, out);
    assert.match(out, /not a zip/);
  });
});

test('⛔ a reference query with a parameter the script cannot bind is refused', async () => {
  const model = MODEL.replace('LIMIT ({quarters})::int', 'LIMIT ({quarters})::int AND x = {unknown_param}');
  await withHarness({ model }, async (h) => {
    const { code, out } = await run(h);
    assert.equal(code, 1, out);
    assert.match(out, /does not bind: \{unknown_param\}/);
  });
});

test('the SQL handed to psql is the model’s, with every parameter bound', async () => {
  await withHarness({}, async (h) => {
    const { code, out } = await run(h);
    assert.equal(code, 0, out);
    const sql = readFileSync(path.join(h.dir, 'psql-saw.sql'), 'utf8');
    assert.match(sql, /SELECT \* FROM reference/);
    assert.match(sql, new RegExp(`portfolio_ref = '${PORTFOLIO}'`));
    assert.match(sql, /\('2026-08-31'\)::date/);
    assert.doesNotMatch(sql, /\{[a-z_]+\}/);
    // ⚑ and it is the RIGHT query: `positions_at` sits above it in the same file.
    assert.doesNotMatch(sql, /SELECT 1/);
  });
});

// ⛔ RULED 2026-09-14 (S3.3·D8): a fingerprint is a real portfolio's balances and this repository is
// PUBLIC. The two cases below are the guard: `--save` alone writes nothing, and a save directory inside
// this repo is refused.
const REPO = path.resolve(here, '../..');

test('⛔ --save with no directory PRINTS the fingerprint and writes nothing into this repository', async () => {
  await withHarness({}, async (h) => {
    const { code, out } = await run(h, {}, ['--save']);
    assert.equal(code, 0, out);
    assert.match(out, /-----BEGIN FINGERPRINT investment-evolution-v1-conseq-900000001-2026-08-31\.csv-----/);
    assert.equal(existsSync(path.join(REPO, 'run-set/fingerprints')), false, 'nothing may land in the public repo');
  });
});

test('⛔ a save directory INSIDE this public repository is refused, naming why', async () => {
  const inside = path.join(REPO, 'run-set/fingerprints-must-never-exist');
  await withHarness({}, async (h) => {
    const { code, out } = await run(h, { IE_FP_SAVE_DIR: inside }, ['--save']);
    assert.equal(code, 1, out);
    assert.match(out, /PUBLIC/);
    assert.match(out, /S3\.3·D8/);
    assert.equal(existsSync(inside), false, 'the refused directory must not be created');
  });
});

test('--save writes the fingerprint, where it is told to', async () => {
  await withHarness({}, async (h) => {
    // ⚑ IE_FP_SAVE_DIR, not the default: the default is the REPO's run-set/fingerprints (§7.2, where
    // the rehearsal fingerprint is committed), and a suite that wrote there would leave a file in the
    // working tree on every run — which is exactly what the first version of this test caught.
    const saveDir = path.join(h.dir, 'fingerprints');
    const { code, out } = await run(h, { IE_FP_SAVE_DIR: saveDir }, ['--save']);
    assert.equal(code, 0, out);
    const file = path.join(saveDir, `investment-evolution-v1-conseq-900000001-${AS_OF}.csv`);
    assert.match(out, /fingerprint saved: .*investment-evolution-v1-conseq-900000001/);
    assert.ok(existsSync(file), `${file}\n${out}`);
    const csv = readFileSync(file, 'utf8').trim().split('\n');
    assert.equal(csv[0], 'period_end,currency,total_value,market_value,cash_balance,net_flow_q,pnl_q,return_q_pct,price_coverage');
    // …and PRINTED between markers: the run that matters happens in a pod, whose filesystem goes away
    // with the Job, so the log is the only way the rehearsal fingerprint gets out.
    assert.match(out, /-----BEGIN FINGERPRINT investment-evolution-v1-conseq-900000001-2026-08-31\.csv-----/);
    assert.match(out, /-----END FINGERPRINT-----/);
    assert.equal(csv.length, 1 + ROWS.length);
    assert.match(csv[2], /^2025-12-31,CZK,1220000\.00,875000\.00,345000\.00,200000\.00,25000\.00,2\.512563,full$/);
  });
});
