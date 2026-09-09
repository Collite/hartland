// IE-P2·S2.3·T2 — the investment sync is idempotent, stamped, and carries the interpreted face only.
//
// Run: node --test scripts/tests/sync-investment-model.test.mjs
//
// The sync copies `kantheon/packages/investment/model/{db,er,binding,queries}` into
// `model/investment/` here (IE-C27). It is the one place this repo's model is written by a machine,
// and three things about it are load-bearing:
//
//   ⛔ **It must carry the INTERPRETED FACE ONLY.** kantheon's package has two faces in one
//      directory: `model/db er binding queries` (parses) and `model/{book,parties,instruments}.ttrm`
//      (`model book` is not a grammar model code — the parser REJECTS them). S2.1·D1 is what that
//      costs: a rejected file is still READ by anything walking the tree, its `def entity`
//      declarations recovered under a guessed `er` code, and `book.ttrm` sorts before `er/book.ttrm`
//      — so the two facts the Golem reads resolved to the wrong file. Handing veles one of those is
//      how that defect reaches the estate, whatever its own Kotlin loader does with a parse error.
//
//   ⛔ **It must not carry kantheon's test tree.** Those suites import a harness that is not synced,
//      and `just verify-model` here runs `find model -name '*.test.mjs'` — so a copied `tests/`
//      directory does not sit there inertly, it turns this repo's model gate red.
//
//   ⛔ **It must be idempotent and checkable.** A hand-edit in `model/investment/` is a change to a
//      model whose source of truth is another repository; nothing but the stamp can see it.
//
// The recipes are driven through `just --justfile … --working-directory <tmp>`, so every assertion
// below runs against a throwaway destination rather than against this checkout.

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, readFileSync, writeFileSync, existsSync, readdirSync, statSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, '../..');
const justfile = path.join(repo, 'justfile');

/** The kantheon checkout the sync reads. Overridable so a CI lane can point elsewhere. */
const KANTHEON = process.env.IE_KANTHEON_DIR ?? path.resolve(repo, '../kantheon-ie');

function just(cwd, ...args) {
  return execFileSync('just', ['--justfile', justfile, '--working-directory', cwd, ...args], {
    encoding: 'utf-8',
    stdio: ['ignore', 'pipe', 'pipe'],
  });
}

/** Run a recipe expecting a NON-zero exit; return { status, output }. */
function justFails(cwd, ...args) {
  try {
    just(cwd, ...args);
    return { status: 0, output: '' };
  } catch (e) {
    return { status: e.status ?? -1, output: `${e.stdout ?? ''}${e.stderr ?? ''}` };
  }
}

function freshDest() {
  const d = mkdtempSync(path.join(tmpdir(), 'ie-sync-'));
  mkdirSync(path.join(d, 'model'), { recursive: true });
  execFileSync('git', ['init', '-q'], { cwd: d });
  return d;
}

/** Every file under `dir`, repo-relative, sorted. */
function filesUnder(dir) {
  const out = [];
  const walk = (p, rel) => {
    for (const name of readdirSync(p).sort()) {
      const full = path.join(p, name);
      if (statSync(full).isDirectory()) walk(full, `${rel}${name}/`);
      else out.push(`${rel}${name}`);
    }
  };
  if (existsSync(dir)) walk(dir, '');
  return out.sort();
}

const kantheonPresent = existsSync(path.join(KANTHEON, 'packages/investment/model/db'));

test('T4.0 — the kantheon checkout the sync reads is actually there', () => {
  // ⛔ Not a skip. A sync suite that quietly passes when it cannot find its source proves nothing,
  // and S2.1·D5 is this effort's own instance of that: 14 assertions passed against an empty
  // package. If this fails, set IE_KANTHEON_DIR.
  assert.ok(kantheonPresent, `no investment package at ${KANTHEON} — set IE_KANTHEON_DIR`);
});

test('T4.1 — two runs into a fresh destination leave nothing to commit the second time', () => {
  const dest = freshDest();
  just(dest, 'sync-investment-model', KANTHEON);
  execFileSync('git', ['add', '-A'], { cwd: dest });
  execFileSync('git', ['-c', 'user.email=t@t', '-c', 'user.name=t', 'commit', '-qm', 'first sync'], { cwd: dest });

  just(dest, 'sync-investment-model', KANTHEON);
  const dirty = execFileSync('git', ['status', '--porcelain'], { cwd: dest, encoding: 'utf-8' });
  assert.equal(dirty.trim(), '', `the second sync changed something:\n${dirty}`);
});

test('T4.2 — SYNCED-FROM names the source commit and the day it was taken', () => {
  const dest = freshDest();
  just(dest, 'sync-investment-model', KANTHEON);
  const stamp = readFileSync(path.join(dest, 'model/investment/SYNCED-FROM'), 'utf-8');

  const head = execFileSync('git', ['-C', KANTHEON, 'rev-parse', 'HEAD'], { encoding: 'utf-8' }).trim();
  assert.match(stamp, new RegExp(`^source-commit: ${head}$`, 'm'), 'the kantheon HEAD sha');
  assert.match(stamp, /^synced-at: \d{4}-\d{2}-\d{2}$/m, 'an ISO date');
  assert.match(stamp, /^tree-sha256: [0-9a-f]{64}$/m, 'the tree hash check-investment-model recomputes');
});

test('T4.3 — a hand-edited file makes check-investment-model fail, and it says which one', () => {
  const dest = freshDest();
  just(dest, 'sync-investment-model', KANTHEON);
  just(dest, 'check-investment-model'); // clean tree: passes

  const victim = path.join(dest, 'model/investment/db/investment.ttrm');
  writeFileSync(victim, `${readFileSync(victim, 'utf-8')}\n// edited by hand\n`);

  const { status, output } = justFails(dest, 'check-investment-model');
  assert.notEqual(status, 0, 'check-investment-model passed over a hand-edited file');
  assert.match(output, /db\/investment\.ttrm/, `the failure must name the file:\n${output}`);
});

test('T4.4 — the INTERPRETED FACE ONLY: no book layer, no entry/, no kantheon test tree', () => {
  const dest = freshDest();
  just(dest, 'sync-investment-model', KANTHEON);
  const files = filesUnder(path.join(dest, 'model/investment'));

  assert.ok(files.length > 4, `the sync produced almost nothing: ${files.join(', ')}`);

  // S2.1·D1 — the three files the parser rejects, by name.
  for (const rejected of ['book.ttrm', 'parties.ttrm', 'instruments.ttrm']) {
    assert.ok(
      !files.some((f) => path.basename(f) === rejected && !f.startsWith('er/')),
      `${rejected} reached the estate — it does not parse, and a rejected file is still READ`,
    );
  }
  assert.ok(!files.some((f) => f.startsWith('entry/')), 'the entry face (DDL, apply programs) is not the estate\'s');
  assert.ok(!files.some((f) => f.includes('tests/')), 'kantheon\'s test tree would turn `just verify-model` red here');
  assert.ok(!files.some((f) => f.endsWith('.test.mjs') || f.endsWith('.mjs')), 'no JavaScript belongs in a served model');

  // And what it MUST carry: the four interpreted directories.
  for (const kind of ['db/', 'er/', 'binding/', 'queries/']) {
    assert.ok(files.some((f) => f.startsWith(kind)), `the sync carries no ${kind}`);
  }
  assert.ok(files.includes('SYNCED-FROM'), 'no stamp');
});

test('T4.4b — a DIRTY source is refused: the stamp may not name a commit it is not', () => {
  // The recipe's own first real run wrote `source-commit: 526f50a` over a tree that carried
  // uncommitted rewrites. `check-investment-model` would have been green over content nobody could
  // reproduce from the named commit — a drift check confirming a lie. The refusal is the fix; the
  // positive case (T4.1–T4.5) is what proves a CLEAN source still syncs.
  const dest = freshDest();
  const scratch = mkdtempSync(path.join(tmpdir(), 'ie-kantheon-'));
  execFileSync('git', ['init', '-q'], { cwd: scratch });
  const model = path.join(scratch, 'packages/investment/model');
  for (const kind of ['db', 'er', 'binding', 'queries']) {
    mkdirSync(path.join(model, kind), { recursive: true });
    writeFileSync(path.join(model, kind, 'x.ttrm'), 'package investment\n');
  }
  execFileSync('git', ['add', '-A'], { cwd: scratch });
  execFileSync('git', ['-c', 'user.email=t@t', '-c', 'user.name=t', 'commit', '-qm', 'seed'], { cwd: scratch });
  just(dest, 'sync-investment-model', scratch); // clean: allowed

  writeFileSync(path.join(model, 'db/x.ttrm'), 'package investment\n// uncommitted\n');
  const { status, output } = justFails(dest, 'sync-investment-model', scratch);
  assert.notEqual(status, 0, 'the sync stamped a dirty source');
  assert.match(output, /uncommitted changes/, output);

  // …and it can still be forced, deliberately, with the commit marked.
  just(dest, 'sync-investment-model', scratch, 'true');
  const stamp = readFileSync(path.join(dest, 'model/investment/SYNCED-FROM'), 'utf-8');
  assert.match(stamp, /^source-commit: [0-9a-f]{40}\+dirty$/m, 'a forced sync must say so in the stamp');
});

test('T4.5 — every synced .ttrm declares `package investment`, and the db layer is `dbo`', () => {
  // The namespace is not cosmetic here (S2.3·D1b): the door resolves unqualified DB identifiers in
  // the fixed namespace `dbo`, and dispatch routes this estate's plans by `db.dbo.investment_*`.
  // A sync that carried a `public` db layer would give veles a model whose every query fails to
  // validate AND whose plans route to the default connection — the TPC-DS one.
  const dest = freshDest();
  just(dest, 'sync-investment-model', KANTHEON);
  const root = path.join(dest, 'model/investment');
  const ttrm = filesUnder(root).filter((f) => f.endsWith('.ttrm'));
  assert.ok(ttrm.length >= 4, `only ${ttrm.length} .ttrm files synced`);
  for (const f of ttrm) {
    const text = readFileSync(path.join(root, f), 'utf-8');
    assert.match(text, /^package investment$/m, `${f} does not declare \`package investment\``);
  }
  const db = readFileSync(path.join(root, 'db/investment.ttrm'), 'utf-8');
  assert.match(db, /^model db schema dbo$/m, 'the db layer must declare `dbo`, not the physical schema');
});
