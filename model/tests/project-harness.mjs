// Shared project-load harness for the Stage 2.x mocked unit-test suites (no live DB).
// Parses every model/*.ttrm under the hartland repo root as ONE project, loads the
// cnc-roles stock vocab, and runs the full semantics + lint pipeline — the same
// machinery tatrman's own `tests/integration/src/integration.test.ts` uses
// (`collectFixtureCodes`), adapted to point at this repo instead of tatrman's samples/.
//
// Borrows the sibling tatrman checkout's built dist (BM-9: hartland stays content-only,
// no node_modules of its own).

import { readFile, readdir } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
export const hartlandRoot = path.resolve(here, '../..');
const tatrmanPackages = path.resolve(hartlandRoot, '../tatrman/packages');

const { parseString } = await import(path.join(tatrmanPackages, 'parser/dist/index.js'));
const semantics = await import(path.join(tatrmanPackages, 'semantics/dist/index.js'));
const semanticsNodeOnly = await import(path.join(tatrmanPackages, 'semantics/dist/node-only.js'));
const lintMod = await import(path.join(tatrmanPackages, 'lint/dist/index.js'));

const {
  resolveManifest, parseManifest, ProjectSymbolTable, Resolver,
  PackageGraphBuilder, synthesizeMappings, effectivePackage,
  AreaTableBuilder,
} = semantics;
const { loadStockVocabularies } = semanticsNodeOnly;
const { lintDocument, lintProject, recommendedConfig } = lintMod;

async function walkTtrm(dir, excludeDirs = ['.schema-ref', 'node_modules', '.git']) {
  const out = [];
  for (const entry of await readdir(dir, { withFileTypes: true })) {
    if (entry.isDirectory()) {
      if (excludeDirs.includes(entry.name)) continue;
      out.push(...await walkTtrm(path.join(dir, entry.name), excludeDirs));
    } else if (entry.isFile() && entry.name.endsWith('.ttrm')) {
      out.push(path.join(dir, entry.name));
    }
  }
  return out;
}

/**
 * Parse + resolve the whole hartland model/ tree as one project. Returns everything a
 * stage's T6 suite needs: per-file ASTs, per-file diagnostic codes, the symbol table,
 * resolver, package graph, area table, and manifest.
 */
export async function loadHartlandProject() {
  const root = hartlandRoot.endsWith('/') ? hartlandRoot : hartlandRoot + '/';
  const files = (await walkTtrm(path.join(hartlandRoot, 'model')));

  const manifestToml = await readFile(path.join(hartlandRoot, 'modeler.toml'), 'utf-8');
  const manifest = resolveManifest(parseManifest(manifestToml), root);

  const symbols = new ProjectSymbolTable();
  const asts = new Map(); // uri -> ast
  const areaEntries = [];

  // Stock vocab (fact/dimension/structural/master/transaction/bridge) — `roles: [...]`
  // on every er entity references this.
  const stockVocabs = await loadStockVocabularies(manifest.stockVocabularies);
  for (const [name, ast] of stockVocabs) {
    const uri = `stock://${name}.ttrm`;
    asts.set(uri, ast);
    symbols.upsertDocument(uri, ast, 'cnc', 'role', '');
  }

  const parseErrorsByFile = new Map(); // relative path -> [{code,message}]
  for (const file of files) {
    const uri = `file://${file}`;
    const result = parseString(await readFile(file, 'utf-8'), uri);
    parseErrorsByFile.set(path.relative(hartlandRoot, file), result.errors);
    if (!result.ast) continue;
    asts.set(uri, result.ast);
    symbols.upsertDocument(
      uri,
      result.ast,
      result.ast.modelDirective?.modelCode ?? 'db',
      result.ast.modelDirective?.schema ?? '',
      effectivePackage(result.ast, file, root, manifest.packages),
    );
    synthesizeMappings(symbols, uri, result.ast);
    for (const def of result.ast.definitions ?? []) {
      if (def.kind === 'area') areaEntries.push({ area: def, documentUri: uri });
    }
  }

  const resolver = new Resolver(symbols);
  const deps = { manifest, symbols, resolver };
  const packageGraph = new PackageGraphBuilder(symbols, asts).build();
  const config = recommendedConfig();
  const projectByUri = lintProject(asts, packageGraph, deps, config);

  const diagnosticsByFile = new Map(); // relative path -> Set(codes)
  for (const file of files) {
    const uri = `file://${file}`;
    const ast = asts.get(uri);
    if (!ast) continue;
    const codes = new Set();
    for (const d of lintDocument(uri, ast, deps, config)) codes.add(d.code);
    for (const d of projectByUri.get(uri) ?? []) codes.add(d.code);
    diagnosticsByFile.set(path.relative(hartlandRoot, file), codes);
  }

  const areaTable = new AreaTableBuilder(symbols, resolver, manifest.packages.root ?? '').build(areaEntries);

  return { root: hartlandRoot, files, asts, symbols, resolver, packageGraph, manifest, diagnosticsByFile, parseErrorsByFile, areaTable };
}
