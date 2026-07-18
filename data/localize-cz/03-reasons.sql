-- Stage 1.3 T5 — Czech return reasons (mirror S-9). Idempotent, PK-keyed (r_reason_sk, not text
-- -- two rows share the literal "reason 31" text upstream, see naming-us.sql's note). Keeps
-- "Nedorazilo včas" (sk=3, the S3 skew target) distinct from every other reason. sk 23-35's
-- Czech text is a true translation of naming-us.sql's canonical English set (single source of
-- truth: data/seed/reason-placeholders-fix.sql) -- keep both in sync if either changes.
\set ON_ERROR_STOP on
BEGIN;

UPDATE reason SET r_reason_desc = 'Balík byl poškozen'                          WHERE r_reason_sk = 1;
UPDATE reason SET r_reason_desc = 'Přestalo fungovat'                          WHERE r_reason_sk = 2;
UPDATE reason SET r_reason_desc = 'Nedorazilo včas'                            WHERE r_reason_sk = 3;
UPDATE reason SET r_reason_desc = 'Nebyl to objednaný produkt'                 WHERE r_reason_sk = 4;
UPDATE reason SET r_reason_desc = 'Chybí díly'                                 WHERE r_reason_sk = 5;
UPDATE reason SET r_reason_desc = 'Nefunguje s produktem, který mám'           WHERE r_reason_sk = 6;
UPDATE reason SET r_reason_desc = 'Výměna dárku'                               WHERE r_reason_sk = 7;
UPDATE reason SET r_reason_desc = 'Nelíbila se mi barva'                       WHERE r_reason_sk = 8;
UPDATE reason SET r_reason_desc = 'Nelíbil se mi model'                        WHERE r_reason_sk = 9;
UPDATE reason SET r_reason_desc = 'Nelíbila se mi značka'                      WHERE r_reason_sk = 10;
UPDATE reason SET r_reason_desc = 'Nelíbila se mi záruka'                      WHERE r_reason_sk = 11;
UPDATE reason SET r_reason_desc = 'V mém okolí není servis'                    WHERE r_reason_sk = 12;
UPDATE reason SET r_reason_desc = 'Našel/našla jsem lepší cenu v obchodě'      WHERE r_reason_sk = 13;
UPDATE reason SET r_reason_desc = 'Lepší prodloužená záruka v obchodě'         WHERE r_reason_sk = 14;
UPDATE reason SET r_reason_desc = 'Přestalo fungovat úplně'                    WHERE r_reason_sk = 15;
UPDATE reason SET r_reason_desc = 'Nesedělo to'                                WHERE r_reason_sk = 16;
UPDATE reason SET r_reason_desc = 'Špatná velikost'                            WHERE r_reason_sk = 17;
UPDATE reason SET r_reason_desc = 'Přišel/přišla jsem o práci'                 WHERE r_reason_sk = 18;
UPDATE reason SET r_reason_desc = 'Neautorizovaný nákup'                       WHERE r_reason_sk = 19;
UPDATE reason SET r_reason_desc = 'Duplicitní nákup'                           WHERE r_reason_sk = 20;
UPDATE reason SET r_reason_desc = 'Je to kluk'                                 WHERE r_reason_sk = 21;
UPDATE reason SET r_reason_desc = 'Je to holka'                                WHERE r_reason_sk = 22;
UPDATE reason SET r_reason_desc = 'Změnil/a jsem názor'                        WHERE r_reason_sk = 23;
UPDATE reason SET r_reason_desc = 'Našel/našla jsem lepší cenu'                WHERE r_reason_sk = 24;
UPDATE reason SET r_reason_desc = 'Neodpovídá popisu'                          WHERE r_reason_sk = 25;
UPDATE reason SET r_reason_desc = 'Nechtěný dárek'                             WHERE r_reason_sk = 26;
UPDATE reason SET r_reason_desc = 'Objednáno omylem'                           WHERE r_reason_sk = 27;
UPDATE reason SET r_reason_desc = 'Již nepotřebuji'                            WHERE r_reason_sk = 28;
UPDATE reason SET r_reason_desc = 'Nekompatibilní se zařízením'                WHERE r_reason_sk = 29;
UPDATE reason SET r_reason_desc = 'Kvalita neodpovídá'                         WHERE r_reason_sk = 30;
UPDATE reason SET r_reason_desc = 'Duplicitní objednávka'                      WHERE r_reason_sk = 31;
UPDATE reason SET r_reason_desc = 'Chybějící příslušenství'                    WHERE r_reason_sk = 32;
UPDATE reason SET r_reason_desc = 'Poškozený obal'                             WHERE r_reason_sk = 33;
UPDATE reason SET r_reason_desc = 'Jiný důvod'                                 WHERE r_reason_sk = 34;
UPDATE reason SET r_reason_desc = 'Reklamace u výrobce'                        WHERE r_reason_sk = 35;

COMMIT;

\echo '-- verification: 35 distinct cs reasons, "Nedorazilo včas" present exactly once --'
SELECT count(*) FROM reason WHERE btrim(r_reason_desc) = 'Nedorazilo včas';
SELECT count(DISTINCT btrim(r_reason_desc)) FROM reason;
