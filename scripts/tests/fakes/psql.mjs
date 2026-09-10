// A stand-in `psql` for the investment drill's tests (scripts/tests/investment-dod.test.mjs).
//
// It runs the one statement the drill passes with `-c` against a SQLite file (FAKE_PSQL_DB) and
// prints it the way `psql -X -q -t -A` does: one line per row, columns joined by `|`, NULL as an
// empty string. The drill's SQL is plain enough that SQLite executes it as written, bar the
// PostgreSQL spellings translated below. That is the point of a real engine rather than canned
// answers: the movement selector, the effective-ledger count and the net-flow sum are EXECUTED, so
// a test sees which movement the script actually picks and what the book actually sums to.
//
// Every statement is appended to FAKE_PSQL_LOG when it is set, so a test can assert that the script
// asked the book nothing at all.

import { DatabaseSync } from 'node:sqlite';
import { appendFileSync } from 'node:fs';

const args = process.argv.slice(2);
const at = args.indexOf('-c');
if (at < 0 || at + 1 >= args.length) {
  process.stderr.write('fake psql: only `-c <statement>` is supported\n');
  process.exit(2);
}
let sql = args[at + 1];
if (process.env.FAKE_PSQL_LOG) appendFileSync(process.env.FAKE_PSQL_LOG, `${sql.replace(/\s+/g, ' ').trim()}\n`);

// PostgreSQL → SQLite, and nothing else:
//   date_trunc('quarter', DATE 'YYYY-MM-DD')  → that quarter's first day, as an ISO literal
//   DATE 'YYYY-MM-DD'                         → 'YYYY-MM-DD' (dates are ISO text in the fake book)
//   ::text / ::numeric / ::date               → dropped
sql = sql
  .replace(/date_trunc\('quarter',\s*DATE\s+'(\d{4})-(\d{2})-\d{2}'\)/g, (_, y, m) => {
    const first = Math.floor((Number(m) - 1) / 3) * 3 + 1;
    return `'${y}-${String(first).padStart(2, '0')}-01'`;
  })
  .replace(/DATE\s+'(\d{4}-\d{2}-\d{2})'/g, "'$1'")
  .replace(/::(text|numeric|date)\b/g, '');

// SQLite hands back a double; psql prints PostgreSQL's numeric text. 15 significant digits is what
// SQLite's own text conversion uses, and it prints 1600.16 + 1.11 as 1601.27, as PostgreSQL would.
const cell = (v) => (v === null ? '' : typeof v === 'number' ? String(Number(v.toPrecision(15))) : String(v));

try {
  const db = new DatabaseSync(process.env.FAKE_PSQL_DB);
  for (const row of db.prepare(sql).all()) process.stdout.write(`${Object.values(row).map(cell).join('|')}\n`);
  db.close();
} catch (e) {
  process.stderr.write(`ERROR:  ${e.message}\n`);
  process.exit(1);
}
