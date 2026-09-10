// IE-P2·S2.4 — `scripts/investment-dod.sh` driven against a stub studio-bff and a fake psql.
//
// Run: node --test scripts/tests/investment-dod.test.mjs
//
// The drill is the one check that crosses the whole path a person crosses, and in `full` mode it
// WRITES to an append-only ledger — so whether its own checks can fail cannot be found out against
// a real estate. This suite drives it against:
//
//   · a stub BFF (node:http) whose write side applies the ledger's reverse-and-replace rule the way
//     the entry substrate does (`X-rev` + `X-rep`, a second correction of X refused), and whose
//     read side answers the programs FROM THE SAME BOOK — or, per test, answers wrongly on purpose:
//     a door that never sees the writes, a replacement at the old amount, a price read at scale 0;
//   · a fake `psql` on PATH that EXECUTES the script's SQL against that book (SQLite — see
//     fakes/psql.mjs), so the movement selector and the net-flow sum are run, not canned.
//
// Every "must fail" case asserts that the failure NAMES its reason, so a test cannot pass because
// the script fell over somewhere else. Needs bash >= 4, curl and jq on PATH, as the script does.

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { spawn, execFileSync } from 'node:child_process';
import { createServer } from 'node:http';
import { chmodSync, existsSync, mkdirSync, mkdtempSync, readFileSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { DatabaseSync } from 'node:sqlite';

const here = path.dirname(fileURLToPath(import.meta.url));
const SCRIPT = path.resolve(here, '../investment-dod.sh');
const FAKE_PSQL = path.join(here, 'fakes/psql.mjs');

/** The script dates everything with `date -u +%F`; so does the fake book. */
const TODAY = new Date().toISOString().slice(0, 10);
const P = 'conseq:900000001';
const TR = 'q.investment.transactions_recent';
const PA = 'q.investment.positions_at';

test('the tools the drill needs are on PATH', () => {
  // ⛔ Not a skip. A drill suite that quietly passes when it cannot run the drill proves nothing.
  for (const tool of ['bash', 'curl', 'jq']) {
    assert.doesNotThrow(() => execFileSync('sh', ['-c', `command -v ${tool}`]), `${tool} is not on PATH`);
  }
  const major = Number(execFileSync('bash', ['-c', 'echo ${BASH_VERSINFO[0]}'], { encoding: 'utf-8' }).trim());
  assert.ok(major >= 4, `the drill needs bash >= 4 (associative arrays); PATH's bash is ${major}`);
});

// ── the book ─────────────────────────────────────────────────────────────────────────────────────

const COLUMNS = ['external_id', 'portfolio_ref', 'leg', 'operation', 'trade_date', 'asset_ref', 'quantity', 'amount', 'currency', 'reversal_of'];

const SCHEMA = `
  CREATE TABLE investment_transaction (
    external_id TEXT PRIMARY KEY, portfolio_ref TEXT NOT NULL, leg TEXT NOT NULL, operation TEXT NOT NULL,
    trade_date TEXT NOT NULL, asset_ref TEXT, quantity NUMERIC, amount NUMERIC, currency TEXT, reversal_of TEXT);
  CREATE TABLE investment_asset_price (
    isin TEXT NOT NULL, price_date TEXT NOT NULL, price NUMERIC, currency TEXT, PRIMARY KEY (isin, price_date));`;

function tx(id, leg, operation, tradeDate, extra = {}) {
  return { external_id: id, portfolio_ref: P, leg, operation, trade_date: tradeDate, asset_ref: null, quantity: null, currency: 'CZK', reversal_of: null, ...extra };
}

/** A small throwaway portfolio: two buys (p:b2 is the latest), their cash legs, one old deposit. */
function baseBook() {
  return {
    transactions: [
      tx('p:b1', 'security', 'buy', '2024-02-01', { asset_ref: 'CZ0000000001', quantity: 100, amount: 1000 }),
      tx('p:b2', 'security', 'buy', '2024-03-01', { asset_ref: 'CZ0000000002', quantity: 50, amount: 1600.16 }),
      tx('p:c1', 'cash', 'credit', '2024-01-15', { amount: 5000 }),
      tx('p:c2', 'cash', 'debit', '2024-02-01', { amount: 1000 }),
      tx('p:c3', 'cash', 'debit', '2024-03-01', { amount: 1600.16 }),
      tx('p:f1', 'external-flow', 'deposit', '2024-01-15', { amount: 5000 }),
      // Another portfolio's later buy: the selector must never reach outside the named portfolio.
      { ...tx('q:b9', 'security', 'buy', '2025-01-01', { asset_ref: 'CZ0000000001', quantity: 1, amount: 10 }), portfolio_ref: 'conseq:900000002' },
    ],
    prices: [
      ['CZ0000000001', '2024-01-31', 9.5],
      ['CZ0000000001', '2024-06-30', 10.25],
      ['CZ0000000002', '2024-06-30', 2.1031],
    ],
  };
}

function insertRow(db, row) {
  db.prepare(`INSERT INTO investment_transaction (${COLUMNS.join(', ')}) VALUES (${COLUMNS.map(() => '?').join(', ')})`)
    .run(...COLUMNS.map((c) => row[c] ?? null));
}

/**
 * The substrate's ledger program, as LedgerApplyProgram states it: an insert posts; an update of a
 * row not yet posted posts it; an identical update is skipped; otherwise X is reversed by `X-rev`
 * (amount negated, reversal_of = X) and replaced by `X-rep` (X with the proposed values), and a
 * correction of X when `X-rev` already exists is refused — LEDGER_CHAIN_UNSUPPORTED.
 */
function applyBatch(db, batch, { dryRun = false } = {}) {
  const get = (id) => db.prepare('SELECT * FROM investment_transaction WHERE external_id = ?').get(id);
  db.exec('BEGIN');
  try {
    for (const p of batch.proposals) {
      if (p.op === 'insert') { insertRow(db, p.values); continue; }
      const id = p.key.external_id;
      const original = get(id);
      if (!original) { insertRow(db, { ...p.key, ...p.values }); continue; }
      if (Object.entries(p.values).every(([k, v]) => Number(original[k]) === Number(v) || String(original[k]) === String(v))) continue;
      if (get(`${id}-rev`)) throw Object.assign(new Error(`${id} has already been corrected`), { code: 'LEDGER_CHAIN_UNSUPPORTED' });
      insertRow(db, { ...original, external_id: `${id}-rev`, amount: -Number(original.amount), reversal_of: id });
      insertRow(db, { ...original, ...p.values, external_id: `${id}-rep`, reversal_of: null });
    }
    db.exec(dryRun ? 'ROLLBACK' : 'COMMIT');
  } catch (e) {
    db.exec('ROLLBACK');
    throw e;
  }
}

// ── the door: the programs, answered from the book ───────────────────────────────────────────────

const EFFECTIVE = `
  SELECT t.*,
    CASE WHEN t.leg = 'security' AND t.operation IN ('buy', 'transfer-in', 'reversal-of-sell') THEN abs(t.quantity)
         WHEN t.leg = 'security' AND t.operation IN ('sell', 'transfer-out', 'payout', 'reversal-of-buy') THEN -abs(t.quantity) END AS qty_signed,
    CASE WHEN t.leg = 'cash' AND t.operation = 'credit' THEN abs(t.amount)
         WHEN t.leg = 'cash' AND t.operation = 'debit' THEN -abs(t.amount)
         WHEN t.leg = 'external-flow' AND t.operation = 'deposit' THEN abs(t.amount)
         WHEN t.leg = 'external-flow' AND t.operation = 'withdrawal' THEN -abs(t.amount) END AS amt_signed
  FROM investment_transaction t
  WHERE t.reversal_of IS NULL AND NOT EXISTS (SELECT 1 FROM investment_transaction r WHERE r.reversal_of = t.external_id)`;

/** A stored decimal crosses the door as a decimal STRING; a computed one as a float (S2.3·D6). */
const dec = (v, dp) => (v === null || v === undefined ? null : Number(v).toFixed(dp));

const PROGRAMS = {
  'q.investment.positions_current': {
    columns: ['portfolio_id', 'isin', 'quantity'],
    sql: `WITH e AS (${EFFECTIVE}) SELECT portfolio_ref, asset_ref, SUM(qty_signed) FROM e
          WHERE portfolio_ref = :portfolio_id AND leg = 'security' GROUP BY portfolio_ref, asset_ref ORDER BY asset_ref`,
  },
  'q.investment.cash_balance': {
    columns: ['portfolio_id', 'currency', 'cash_balance'],
    sql: `WITH e AS (${EFFECTIVE}) SELECT portfolio_ref, currency, SUM(amt_signed) FROM e
          WHERE portfolio_ref = :portfolio_id AND leg = 'cash' AND trade_date <= :as_of GROUP BY portfolio_ref, currency ORDER BY currency`,
  },
  [TR]: {
    columns: ['transaction_id', 'trade_date', 'leg', 'operation', 'isin', 'quantity', 'qty_signed', 'amount', 'amt_signed', 'currency'],
    sql: `WITH e AS (${EFFECTIVE}) SELECT external_id, trade_date, leg, operation, asset_ref, quantity, qty_signed, amount, amt_signed, currency
          FROM e WHERE portfolio_ref = :portfolio_id AND trade_date >= :since ORDER BY trade_date DESC, external_id DESC`,
    shape: (r) => [r[0], r[1], r[2], r[3], r[4], dec(r[5], 6), r[6], dec(r[7], 2), r[8], r[9]],
  },
  // EIGHT columns, `line_rank` last (0 = holding, 1 = cash) — the shape kantheon's program answers with.
  [PA]: {
    columns: ['line_id', 'line_name', 'quantity', 'last_price', 'last_price_date', 'market_value', 'currency', 'line_rank'],
    sql: `WITH e AS (${EFFECTIVE}),
          h AS (SELECT asset_ref, SUM(qty_signed) AS quantity FROM e
                 WHERE portfolio_ref = :portfolio_id AND leg = 'security' AND trade_date <= :as_of GROUP BY asset_ref),
          c AS (SELECT currency, SUM(amt_signed) AS balance FROM e
                 WHERE portfolio_ref = :portfolio_id AND leg = 'cash' AND trade_date <= :as_of GROUP BY currency),
          lp AS (SELECT ap.isin, ap.price, ap.price_date, ap.currency FROM investment_asset_price ap
                   JOIN (SELECT isin, MAX(price_date) AS d FROM investment_asset_price WHERE price_date <= :as_of GROUP BY isin) m
                     ON m.isin = ap.isin AND m.d = ap.price_date)
          SELECT * FROM (
            SELECT h.asset_ref AS line_id, h.asset_ref AS line_name, h.quantity AS quantity, lp.price AS last_price,
                   lp.price_date AS last_price_date, h.quantity * lp.price AS market_value, lp.currency AS currency, 0 AS line_rank
              FROM h LEFT JOIN lp ON lp.isin = h.asset_ref
            UNION ALL
            SELECT 'CASH:' || currency, 'Cash (' || currency || ')', NULL, NULL, NULL, balance, currency, 1 FROM c)
          ORDER BY line_rank, line_id`,
  },
};

function answer(db, program, params, cap) {
  const spec = PROGRAMS[program];
  const named = Object.fromEntries(Object.entries(params).map(([k, v]) => [`:${k}`, v]));
  const used = Object.fromEntries(Object.entries(named).filter(([k]) => spec.sql.includes(k)));
  let rows = db.prepare(spec.sql).all(used).map((r) => Object.values(r));
  if (spec.shape) rows = rows.map(spec.shape);
  // The estate's governance cap: validate injects a LIMIT into every plan, and says nothing (S2.4·D9).
  if (cap) rows = rows.slice(0, cap);
  return { columns: spec.columns.map((name) => ({ name })), rows, rowCount: rows.length, truncated: false, messages: [] };
}

/** A copy of `a` with `column` set to `value` on the row whose `idColumn` is `id`. */
function setCell(a, idColumn, id, column, value) {
  const names = a.columns.map((c) => c.name);
  const i = names.indexOf(idColumn);
  const j = names.indexOf(column);
  return { ...a, rows: a.rows.map((r) => (r[i] === id ? r.map((v, k) => (k === j ? value : v)) : r)) };
}

/** A door that never sees a write: every program answers what it answered the first time. */
function staleDoor() {
  const first = {};
  return (program, a) => (first[program] ??= a);
}

// ── the estate ───────────────────────────────────────────────────────────────────────────────────

async function estate({ book = baseBook(), cap, door, qevo = { status: 404, code: 'PROGRAM_NOT_COMPILABLE' }, mutate } = {}) {
  const dir = mkdtempSync(path.join(tmpdir(), 'ie-dod-'));
  const dbPath = path.join(dir, 'book.sqlite');
  const db = new DatabaseSync(dbPath);
  db.exec(SCHEMA);
  for (const row of book.transactions) insertRow(db, row);
  for (const [isin, date, price] of book.prices) {
    db.prepare('INSERT INTO investment_asset_price VALUES (?, ?, ?, ?)').run(isin, date, price, 'CZK');
  }
  const bin = path.join(dir, 'bin');
  mkdirSync(bin);
  writeFileSync(path.join(bin, 'psql'), `#!/bin/sh\nNODE_NO_WARNINGS=1 exec "${process.execPath}" "${FAKE_PSQL}" "$@"\n`);
  chmodSync(path.join(bin, 'psql'), 0o755);

  const ctx = { dir, db, dbPath, bin, requests: [], calls: {}, held: new Map(), psqlLog: path.join(dir, 'psql.log') };
  const server = createServer(async (req, res) => {
    let raw = '';
    for await (const chunk of req) raw += chunk;
    const body = raw ? JSON.parse(raw) : {};
    const url = new URL(req.url, 'http://stub');
    ctx.requests.push(`${req.method} ${url.pathname}${url.search}`);
    const reply = (status, obj) => {
      res.writeHead(status, { 'content-type': 'application/json' });
      res.end(JSON.stringify(obj));
    };
    if (req.headers.authorization !== 'Bearer test-bearer') return reply(401, { code: 'AUTH_MISSING', message: 'no verified caller' });

    if (url.pathname === '/api/query/run') {
      if (body.program === 'q.investment.quarterly_evolution') {
        if (qevo.drop) return req.socket.destroy();
        return reply(qevo.status, { code: qevo.code, message: 'stub' });
      }
      const n = (ctx.calls[body.program] = (ctx.calls[body.program] ?? 0) + 1);
      let a = answer(db, body.program, body.params ?? {}, cap);
      if (door) a = door(body.program, a, n) ?? a;
      return reply(200, a);
    }
    if (url.pathname === '/api/entry/batches') {
      ctx.held.set(body.batchId, body);
      return reply(201, { batchId: body.batchId });
    }
    if (url.pathname === '/api/entry/preview' || url.pathname === '/api/entry/commit') {
      const commit = url.pathname.endsWith('/commit');
      try {
        applyBatch(db, commit && mutate ? mutate(structuredClone(body)) : body, { dryRun: !commit });
        return reply(200, commit ? { batchId: body.batchId } : { rejects: [] });
      } catch (e) {
        return reply(422, { code: e.code ?? 'INTERNAL', message: e.message });
      }
    }
    return reply(404, { code: 'NOT_FOUND', message: url.pathname });
  });
  await new Promise((r) => server.listen(0, '127.0.0.1', r));

  ctx.port = server.address().port;
  ctx.ids = () => db.prepare('SELECT external_id FROM investment_transaction ORDER BY external_id').all().map((r) => r.external_id);
  ctx.entryRequests = () => ctx.requests.filter((r) => r.includes('/api/entry/'));
  ctx.psqlCalls = () => (existsSync(ctx.psqlLog) ? readFileSync(ctx.psqlLog, 'utf-8').split('\n').filter(Boolean).length : 0);
  ctx.run = (env = {}) => runDrill(ctx, env);
  ctx.close = async () => {
    server.closeAllConnections?.();
    await new Promise((r) => server.close(r));
    db.close();
  };
  return ctx;
}

function runDrill(ctx, env) {
  return new Promise((resolve) => {
    const child = spawn(SCRIPT, [], {
      env: {
        PATH: `${ctx.bin}:${process.env.PATH}`,
        HOME: process.env.HOME ?? ctx.dir,
        TMPDIR: process.env.TMPDIR ?? '/tmp',
        IE_DOD_BFF: `http://127.0.0.1:${ctx.port}`,
        IE_DOD_BEARER: 'test-bearer',
        IE_DOD_DSN: 'postgresql://fake/entry',
        IE_DOD_PORTFOLIO: P,
        FAKE_PSQL_DB: ctx.dbPath,
        FAKE_PSQL_LOG: ctx.psqlLog,
        ...env,
      },
    });
    let out = '';
    child.stdout.on('data', (d) => (out += d));
    child.stderr.on('data', (d) => (out += d));
    const timer = setTimeout(() => child.kill('SIGKILL'), 60_000);
    child.on('close', (status) => {
      clearTimeout(timer);
      // eslint-disable-next-line no-control-regex
      resolve({ status, out: out.replace(/\x1b\[[0-9;]*m/g, '') });
    });
  });
}

/** Run the drill and require it to FAIL, for the reason `why`. */
async function mustFail(ctx, env, why) {
  const r = await ctx.run(env);
  assert.notEqual(r.status, 0, `the drill passed when it must not have:\n${r.out}`);
  assert.match(r.out, why, `the drill failed, but not for the reason under test:\n${r.out}`);
  return r;
}

async function mustPass(ctx, env) {
  const r = await ctx.run(env);
  assert.equal(r.status, 0, `the drill failed:\n${r.out}`);
  return r;
}

const FULL = { IE_DOD_MODE: 'full' };

// ── the controls: an honest estate passes ────────────────────────────────────────────────────────

test('readonly against an honest estate passes, and writes nothing', async () => {
  const e = await estate();
  try {
    const before = e.ids();
    const r = await mustPass(e, { IE_DOD_MODE: 'readonly' });
    assert.match(r.out, /readonly mode/);
    assert.deepEqual(e.entryRequests(), [], 'readonly mode sent a request to the entry substrate');
    assert.deepEqual(e.ids(), before);
  } finally {
    await e.close();
  }
});

test('full against an honest estate passes, and leaves exactly the reversal, the replacement and a deposit', async () => {
  const e = await estate();
  try {
    const before = e.ids();
    await mustPass(e, FULL);
    const added = e.ids().filter((id) => !before.includes(id));
    assert.equal(added.length, 3, `added ${added.join(', ')}`);
    assert.ok(added.includes('p:b2-rev') && added.includes('p:b2-rep'), `the latest buy was not the one corrected: ${added}`);
    assert.ok(added.some((id) => id.startsWith('ie-dod:')), 'no deposit');
  } finally {
    await e.close();
  }
});

// ── ⑸ the mode is exactly `readonly` or `full` ───────────────────────────────────────────────────

test('⑸ an IE_DOD_MODE that is not exactly readonly or full fails before any request', async () => {
  const e = await estate();
  try {
    const before = e.ids();
    for (const mode of ['read-only', 'READONLY', 'ro', 'Full']) {
      await mustFail(e, { IE_DOD_MODE: mode }, /IE_DOD_MODE/);
    }
    assert.deepEqual(e.requests, [], 'a request reached the BFF');
    assert.equal(e.psqlCalls(), 0, 'the book was queried');
    assert.deepEqual(e.ids(), before, 'the book changed');
  } finally {
    await e.close();
  }
});

// ── ⑹ after a write, the door must show the write ────────────────────────────────────────────────

test('⑹ a door that never sees the writes fails full mode', async () => {
  const e = await estate({ door: staleDoor() });
  try {
    await mustFail(e, FULL, /still shows the ORIGINAL p:b2/);
  } finally {
    await e.close();
  }
});

test('⑹ the replacement shown at the OLD amount fails — the door must carry the new one', async () => {
  const door = (program, a, n) => (program === TR && n >= 2 ? setCell(a, 'transaction_id', 'p:b2-rep', 'amount', '1600.16') : a);
  const e = await estate({ door });
  try {
    await mustFail(e, FULL, /p:b2-rep at 1600\.16, not the new amount 1601\.27/);
  } finally {
    await e.close();
  }
});

test('⑹ a holding that moves on a line other than the first fails — the whole answer is compared', async () => {
  const door = (program, a, n) => (program === PA && n >= 2 ? setCell(a, 'line_id', 'CZ0000000002', 'quantity', 51) : a);
  const e = await estate({ door });
  try {
    await mustFail(e, FULL, /changed the holdings/);
  } finally {
    await e.close();
  }
});

/** p:b2 sits below four later cash credits, so a 3-row cap keeps it out of the door's window. */
function cappedBook() {
  const book = baseBook();
  for (const d of ['01', '02', '03', '04']) book.transactions.push(tx(`p:c4${d}`, 'cash', 'credit', `2024-04-${d}`, { amount: 10 }));
  return book;
}

test('⑹ under a cap, a replacement outside the window is confirmed by the book — and passes', async () => {
  const e = await estate({ book: cappedBook(), cap: 3 });
  try {
    const r = await mustPass(e, { ...FULL, IE_DOD_TOP_N: '3' });
    assert.match(r.out, /outside the capped 3-row window/);
  } finally {
    await e.close();
  }
});

test('⑹ under a cap, a replacement the book holds at the WRONG amount fails', async () => {
  const mutate = (b) => {
    for (const p of b.proposals) if (p.op === 'update') p.values.amount = '1700.00';
    return b;
  };
  const e = await estate({ book: cappedBook(), cap: 3, mutate });
  try {
    await mustFail(e, { ...FULL, IE_DOD_TOP_N: '3' }, /the book's replacement p:b2-rep carries 1700, not the corrected 1601\.27/);
  } finally {
    await e.close();
  }
});

test('⑹ a door that does not show the deposit fails — cash_balance unchanged is not evidence', async () => {
  let afterCorrection;
  const door = (program, a, n) => {
    if (program !== TR) return a;
    if (n === 2) afterCorrection = a;
    return n >= 3 ? afterCorrection : a;
  };
  const e = await estate({ door });
  try {
    await mustFail(e, FULL, /deposit/);
  } finally {
    await e.close();
  }
});

// ── ⒁ the net flow grows by the amount, exactly ──────────────────────────────────────────────────

test('⒁ a deposit that lands outside the quarter fails, though an earlier deposit already exceeds it', async () => {
  const book = baseBook();
  book.transactions.push(tx('p:f2', 'external-flow', 'deposit', TODAY, { amount: 20000 }));
  const mutate = (b) => {
    for (const p of b.proposals) if (p.op === 'insert') p.values.trade_date = '2024-01-02';
    return b;
  };
  const e = await estate({ book, mutate });
  try {
    await mustFail(e, FULL, /net flow moved from 20000 to 20000/);
  } finally {
    await e.close();
  }
});

// ── ⒂ a re-run reaches the next buy; the post-hold run asserts the held one ──────────────────────

test('⒂ a re-run corrects the next buy, never the previous run\'s replacement', async () => {
  const book = baseBook();
  book.transactions.push(
    tx('p:b2-rev', 'security', 'buy', '2024-03-01', { asset_ref: 'CZ0000000002', quantity: 50, amount: -1600.16, reversal_of: 'p:b2' }),
    tx('p:b2-rep', 'security', 'buy', '2024-03-01', { asset_ref: 'CZ0000000002', quantity: 50, amount: 1601.27 }),
  );
  const e = await estate({ book });
  try {
    await mustPass(e, FULL);
    const ids = e.ids();
    assert.ok(!ids.includes('p:b2-rep-rev'), 'the previous run\'s replacement was corrected');
    assert.ok(ids.includes('p:b1-rev') && ids.includes('p:b1-rep'), `the next buy was not corrected: ${ids}`);
  } finally {
    await e.close();
  }
});

test('⒂ HOLD_ONLY prints the exact re-run, and that re-run asserts the correction a person committed', async () => {
  const e = await estate();
  try {
    const before = e.ids();
    const held = await mustPass(e, { ...FULL, IE_DOD_HOLD_ONLY: '1', IE_DOD_TOP_N: '100' });
    assert.deepEqual(e.ids(), before, 'HOLD_ONLY committed something');

    const line = held.out.split('\n').find((l) => l.includes('IE_DOD_MOVEMENT=') && /just investment-dod\s*$/.test(l));
    assert.ok(line, `no re-run command naming the movement in:\n${held.out}`);
    const rerun = Object.fromEntries([...line.matchAll(/(IE_DOD_[A-Z_]+)=(\S+)/g)].map((m) => [m[1], m[2]]));
    assert.deepEqual(rerun, { IE_DOD_MODE: 'full', IE_DOD_PORTFOLIO: P, IE_DOD_MOVEMENT: 'p:b2', IE_DOD_TOP_N: '100' });

    // The person's move: preview and commit the held batch in the Inbox.
    const batch = [...e.held.values()].find((b) => b.batchId.endsWith('-correct'));
    applyBatch(e.db, batch);

    const r = await mustPass(e, rerun);
    assert.match(r.out, /p:b2-rep carries the new amount/);
    const added = e.ids().filter((id) => !before.includes(id));
    assert.deepEqual(added.filter((id) => !id.startsWith('ie-dod:')).sort(), ['p:b2-rep', 'p:b2-rev'], `the re-run corrected something else: ${added}`);
    assert.equal(added.filter((id) => id.startsWith('ie-dod:')).length, 1, 'the re-run did not run the addition drill');
  } finally {
    await e.close();
  }
});

test('⒂ naming a movement whose correction is not committed fails, and writes nothing', async () => {
  const e = await estate();
  try {
    const before = e.ids();
    await mustFail(e, { ...FULL, IE_DOD_MOVEMENT: 'p:b2' }, /has not been committed/);
    assert.deepEqual(e.entryRequests(), []);
    assert.deepEqual(e.ids(), before);
  } finally {
    await e.close();
  }
});

// ── ㉒ the refusal is THE refusal; columns are read by name ───────────────────────────────────────

test('㉒ quarterly_evolution failing for any reason but PROGRAM_NOT_COMPILABLE fails the drill', async () => {
  for (const qevo of [
    { status: 401, code: 'AUTH_MISSING' },
    { status: 502, code: 'UPSTREAM_UNAVAILABLE' },
    { status: 404, code: 'PROGRAM_NOT_FOUND' },
    { drop: true },
  ]) {
    const e = await estate({ qevo });
    try {
      await mustFail(e, { IE_DOD_MODE: 'readonly' }, /quarterly_evolution answered/);
    } finally {
      await e.close();
    }
  }
});

test('㉒ the movement is found by the transaction_id column NAME, wherever the column sits', async () => {
  const door = (program, a) => {
    if (program !== TR) return a;
    const move = (xs) => [...xs.slice(1), xs[0]];
    return { ...a, columns: move(a.columns), rows: a.rows.map(move) };
  };
  const e = await estate({ door });
  try {
    await mustPass(e, FULL);
  } finally {
    await e.close();
  }
});

// ── last_price: the door's price is the book's, to 6 dp ──────────────────────────────────────────

test('a last_price read at scale 0 (2 for 2.1031) fails readonly mode, naming the line', async () => {
  const door = (program, a) => (program === PA ? setCell(a, 'line_id', 'CZ0000000002', 'last_price', 2) : a);
  const e = await estate({ door });
  try {
    await mustFail(e, { IE_DOD_MODE: 'readonly' }, /positions_at prices CZ0000000002 at 2; the book's latest price on or before \d{4}-\d{2}-\d{2} is 2\.1031/);
  } finally {
    await e.close();
  }
});

test('a last_price that is not the LATEST book price on or before today fails', async () => {
  // The door answering the older of two prices is a wrong answer too, not only a truncated one.
  const door = (program, a) => (program === PA ? setCell(a, 'line_id', 'CZ0000000001', 'last_price', 9.5) : a);
  const e = await estate({ door });
  try {
    await mustFail(e, { IE_DOD_MODE: 'readonly' }, /positions_at prices CZ0000000001 at 9\.5/);
  } finally {
    await e.close();
  }
});
