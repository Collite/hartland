// IE-P3·S3.3 — a minimal `.xlsx` writer, for the fingerprint suite.
//
// The fingerprint reads a workbook the RENDERER produced; a suite that runs without an estate has to
// produce one itself. This writes the smallest real OOXML package the engine can read: shared strings
// (never inline — S3.1·D4 is exactly the shape of bug this suite must be able to see), one sheet per
// name, numeric cells for money and for dates as serials, and blanks where a value is absent.
//
// Stored (no compression) so the zip is written with the standard library alone and stays diffable.

import { writeFileSync } from 'node:fs';
import { crc32 } from 'node:zlib';

/** Excel's day 0 is 1899-12-30 — the serial numbering carries Lotus's 1900 leap-year bug. */
const EPOCH = Date.UTC(1899, 11, 30);

export function serialOf(iso) {
  return Math.round((Date.parse(`${iso}T00:00:00Z`) - EPOCH) / 86400000);
}

const escape = (s) =>
  String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

const colName = (i) => {
  let s = '';
  for (let n = i + 1; n > 0; ) {
    const r = (n - 1) % 26;
    s = String.fromCharCode(65 + r) + s;
    n = Math.floor((n - 1) / 26);
  }
  return s;
};

/**
 * `sheets`: [{ name, rows }] where a row is an array of cells and a cell is
 *   { text } | { number } | { date } | null   (null / undefined = a blank cell).
 */
export function writeWorkbook(path, sheets) {
  const strings = [];
  const idOf = (text) => {
    const at = strings.indexOf(text);
    return at >= 0 ? at : strings.push(text) - 1;
  };

  const sheetXml = sheets.map(({ rows }) => {
    const body = rows
      .map((cells, r) => {
        const out = cells
          .map((cell, c) => {
            if (cell == null) return '';
            const ref = `${colName(c)}${r + 1}`;
            if (cell.text !== undefined) return `<c r="${ref}" t="s"><v>${idOf(cell.text)}</v></c>`;
            const value = cell.date !== undefined ? serialOf(cell.date) : cell.number;
            return `<c r="${ref}"><v>${value}</v></c>`;
          })
          .join('');
        return `<row r="${r + 1}">${out}</row>`;
      })
      .join('');
    return `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>`
      + `<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">`
      + `<sheetData>${body}</sheetData></worksheet>`;
  });

  const sst = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>`
    + `<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="${strings.length}" uniqueCount="${strings.length}">`
    + strings.map((t) => `<si><t xml:space="preserve">${escape(t)}</t></si>`).join('')
    + `</sst>`;

  const rel = (i) => `rId${i + 1}`;
  const parts = {
    '[Content_Types].xml':
      `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>`
      + `<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">`
      + `<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>`
      + `<Default Extension="xml" ContentType="application/xml"/>`
      + `<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>`
      + `<Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>`
      + sheets
        .map((_, i) => `<Override PartName="/xl/worksheets/sheet${i + 1}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>`)
        .join('')
      + `</Types>`,
    '_rels/.rels':
      `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>`
      + `<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">`
      + `<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>`
      + `</Relationships>`,
    'xl/workbook.xml':
      `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>`
      + `<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" `
      + `xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets>`
      + sheets.map((s, i) => `<sheet name="${escape(s.name)}" sheetId="${i + 1}" r:id="${rel(i)}"/>`).join('')
      + `</sheets></workbook>`,
    'xl/_rels/workbook.xml.rels':
      `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>`
      + `<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">`
      + sheets
        .map((_, i) => `<Relationship Id="${rel(i)}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet${i + 1}.xml"/>`)
        .join('')
      + `<Relationship Id="rIdSst" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="sharedStrings.xml"/>`
      + `</Relationships>`,
    'xl/sharedStrings.xml': sst,
    ...Object.fromEntries(sheetXml.map((xml, i) => [`xl/worksheets/sheet${i + 1}.xml`, xml])),
  };

  writeFileSync(path, zip(parts));
}

/** A stored (method 0) zip — enough for any reader, and written without a dependency. */
function zip(parts) {
  const chunks = [];
  const central = [];
  let offset = 0;
  for (const [name, text] of Object.entries(parts)) {
    const nameBytes = Buffer.from(name, 'utf8');
    const data = Buffer.from(text, 'utf8');
    const sum = crc32(data);

    const local = Buffer.alloc(30);
    local.writeUInt32LE(0x04034b50, 0);
    local.writeUInt16LE(20, 4); // version needed
    local.writeUInt16LE(0, 6); // flags
    local.writeUInt16LE(0, 8); // method: stored
    local.writeUInt16LE(0, 10); // time
    local.writeUInt16LE(33, 12); // date: 1980-01-01, so two runs are byte-identical
    local.writeUInt32LE(sum, 14);
    local.writeUInt32LE(data.length, 18);
    local.writeUInt32LE(data.length, 22);
    local.writeUInt16LE(nameBytes.length, 26);
    local.writeUInt16LE(0, 28);
    chunks.push(local, nameBytes, data);

    const entry = Buffer.alloc(46);
    entry.writeUInt32LE(0x02014b50, 0);
    entry.writeUInt16LE(20, 4);
    entry.writeUInt16LE(20, 6);
    entry.writeUInt16LE(0, 8);
    entry.writeUInt16LE(0, 10);
    entry.writeUInt16LE(0, 12);
    entry.writeUInt16LE(33, 14);
    entry.writeUInt32LE(sum, 16);
    entry.writeUInt32LE(data.length, 20);
    entry.writeUInt32LE(data.length, 24);
    entry.writeUInt16LE(nameBytes.length, 28);
    entry.writeUInt32LE(0, 42); // local header offset, patched below
    entry.writeUInt32LE(offset, 42);
    central.push(Buffer.concat([entry, nameBytes]));

    offset += local.length + nameBytes.length + data.length;
  }
  const dir = Buffer.concat(central);
  const end = Buffer.alloc(22);
  end.writeUInt32LE(0x06054b50, 0);
  end.writeUInt16LE(central.length, 8);
  end.writeUInt16LE(central.length, 10);
  end.writeUInt32LE(dir.length, 12);
  end.writeUInt32LE(offset, 16);
  return Buffer.concat([...chunks, dir, end]);
}
