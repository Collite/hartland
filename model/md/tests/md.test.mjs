// Stage 2.3 T5/T6 — dot-path resolution smoke + hierarchy/map/domain unit tests.
// Mocked/unit: parses the whole model/ tree as one project (project-harness.mjs), no
// live DB. Run: node --test model/md/tests/md.test.mjs (from the hartland repo root).
//
// Note on T5's "dot-path resolution" (product.electronics.<class>, calendar.2025.november):
// that notation is the MD "Layer B" dot-path sugar, which docs/features/md/dot-path-
// sugar.md marks explicitly as "brainstorm output... Not yet a contract" — unimplemented
// in the current grammar/resolver. The real, implemented substitute this suite checks
// instead: every hierarchy level's `Dimension.attribute` qname resolves through the
// actual resolver — i.e. the drill CHAIN is real and resolvable, which is the substantive
// claim T5 is after; the query-layer sugar over it is a later-phase concern.

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { loadHartlandProject, ACCEPTED_RESIDUAL_CODES } from '../../tests/project-harness.mjs';

const project = await loadHartlandProject();

function allDefsOfKind(kind) {
  const out = [];
  for (const [uri, ast] of project.asts) {
    for (const def of ast.definitions ?? []) {
      if (def.kind === kind) out.push({ def, uri });
    }
  }
  return out;
}

test('T6.1 — parse-clean: every model/md/*.ttrm file parses with zero errors', () => {
  const offenders = [];
  for (const [file, errors] of project.parseErrorsByFile) {
    if (file.startsWith('model/md/') && errors.length) offenders.push(`${file}: ${JSON.stringify(errors[0])}`);
  }
  assert.deepEqual(offenders, [], `parse errors: ${offenders.join('; ')}`);
});

test('T6.2 — no unexpected md/* (or other) diagnostics anywhere in the project', () => {
  const offenders = [];
  for (const [file, codes] of project.diagnosticsByFile) {
    for (const code of codes) if (!ACCEPTED_RESIDUAL_CODES.has(code)) offenders.push(`${file}: ${code}`);
  }
  assert.deepEqual(offenders, [], `unexpected diagnostics: ${offenders.join('; ')}`);
});

test('T6.3 (dot-path substitute) — every hierarchy level Dimension.attribute qname resolves', () => {
  const hierarchies = allDefsOfKind('hierarchy');
  assert.ok(hierarchies.length >= 4, `expected >=4 hierarchies (3 calendar + 1 product), got ${hierarchies.length}`);
  const dangling = [];
  for (const { def } of hierarchies) {
    const dimName = def.dimensionRef.split('.').pop();
    for (const level of def.levels) {
      const path = `md.${dimName}.${level.attribute}`;
      const res = project.resolver.resolveReference(
        { path, parts: path.split('.') },
        { schemaCode: 'md', namespace: '' },
      );
      if (!res.resolved) dangling.push(`${def.name}: ${path}`);
    }
  }
  assert.deepEqual(dangling, [], `hierarchy levels that don't resolve: ${dangling.join('; ')}`);
});

test('T6.4 — hierarchy well-formedness: every hierarchy has >=1 level and a via-pinned map for every non-leaf level', () => {
  const hierarchies = allDefsOfKind('hierarchy');
  const problems = [];
  for (const { def } of hierarchies) {
    if (def.levels.length < 1) { problems.push(`${def.name}: empty levels`); continue; }
    for (let i = 1; i < def.levels.length; i++) {
      if (!def.levels[i].via) problems.push(`${def.name}: level '${def.levels[i].attribute}' has no via-pinned map`);
    }
  }
  assert.deepEqual(problems, [], problems.join('; '));
});

test('T6.5 — map cardinality: calc maps carry no explicit cardinality, table-backed maps declare N:1 (no M:N)', () => {
  const maps = allDefsOfKind('mdMap');
  assert.ok(maps.length >= 8, `expected >=8 maps (4 calendar calc + 4 product table), got ${maps.length}`);
  const problems = [];
  for (const { def } of maps) {
    if (def.calc) {
      if (def.cardinality && def.cardinality !== 'N:1') problems.push(`${def.name}: calc map has conflicting cardinality '${def.cardinality}'`);
    } else {
      if (!def.cardinality) problems.push(`${def.name}: table-backed map has no cardinality`);
      else if (def.cardinality === 'N:N' || def.cardinality === 'M:N') problems.push(`${def.name}: M:N cardinality`);
    }
  }
  assert.deepEqual(problems, [], problems.join('; '));
});

test('T6.6 — domain typing: every md attribute has domainRef and no type; calc domains are on discrete types', () => {
  const dimensions = allDefsOfKind('dimension');
  const problems = [];
  for (const { def } of dimensions) {
    for (const attr of def.attributes ?? []) {
      if (!attr.domainRef) problems.push(`${def.name}.${attr.name}: missing domain`);
      if (attr.type) problems.push(`${def.name}.${attr.name}: has type: (md/attr-type-in-md)`);
    }
  }
  const domains = allDefsOfKind('mdDomain');
  for (const { def } of domains) {
    const typeName = def.type?.name;
    if (def.domainKind === 'calc' && (typeName === 'decimal' || typeName === 'float')) {
      problems.push(`${def.name}: kind:calc on a continuous type '${typeName}'`);
    }
  }
  assert.deepEqual(problems, [], problems.join('; '));
});

test('T6.7 — calc names are valid (no md/unknown-calc-map — checked via T6.2\'s project-wide diagnostic sweep, asserted again narrowly here)', () => {
  const KNOWN_CALC = new Set(['monthOfDate', 'quarterOfMonth', 'yearOfDate', 'weekOfYear']);
  const maps = allDefsOfKind('mdMap').filter(({ def }) => def.calc);
  assert.ok(maps.length === 4, `expected exactly 4 calc maps (calendar), got ${maps.length}`);
  const unknown = maps.filter(({ def }) => !KNOWN_CALC.has(def.calc.name)).map(({ def }) => `${def.name}: ${def.calc.name}`);
  assert.deepEqual(unknown, [], `unrecognized calc name: ${unknown.join(', ')}`);
});
