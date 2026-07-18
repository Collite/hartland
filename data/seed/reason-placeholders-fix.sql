-- Fix: sk 23-35 (the placeholder "reason NN" rows) were authored as two INDEPENDENT English/
-- Czech lists (naming-us.sql / localize-cz/03-reasons.sql), not translations of each other --
-- and sk=25's English text ("Wrong size") duplicated sk=17. This corrective UPDATE applies one
-- canonical, cross-locale-consistent set to whichever locale column exists in the target DB.
-- Run against hartland_us with :locale='en', hartland_cz with :locale='cs'.
\set ON_ERROR_STOP on
BEGIN;

UPDATE reason SET r_reason_desc = CASE :'locale'
  WHEN 'en' THEN 'Changed my mind' WHEN 'cs' THEN 'Změnil/a jsem názor' END WHERE r_reason_sk = 23;
UPDATE reason SET r_reason_desc = CASE :'locale'
  WHEN 'en' THEN 'Found a better price' WHEN 'cs' THEN 'Našel/našla jsem lepší cenu' END WHERE r_reason_sk = 24;
UPDATE reason SET r_reason_desc = CASE :'locale'
  WHEN 'en' THEN 'Not as pictured' WHEN 'cs' THEN 'Neodpovídá popisu' END WHERE r_reason_sk = 25;
UPDATE reason SET r_reason_desc = CASE :'locale'
  WHEN 'en' THEN 'Unwanted gift' WHEN 'cs' THEN 'Nechtěný dárek' END WHERE r_reason_sk = 26;
UPDATE reason SET r_reason_desc = CASE :'locale'
  WHEN 'en' THEN 'Ordered by mistake' WHEN 'cs' THEN 'Objednáno omylem' END WHERE r_reason_sk = 27;
UPDATE reason SET r_reason_desc = CASE :'locale'
  WHEN 'en' THEN 'No longer needed' WHEN 'cs' THEN 'Již nepotřebuji' END WHERE r_reason_sk = 28;
UPDATE reason SET r_reason_desc = CASE :'locale'
  WHEN 'en' THEN 'Incompatible with my device' WHEN 'cs' THEN 'Nekompatibilní se zařízením' END WHERE r_reason_sk = 29;
UPDATE reason SET r_reason_desc = CASE :'locale'
  WHEN 'en' THEN 'Quality not as expected' WHEN 'cs' THEN 'Kvalita neodpovídá' END WHERE r_reason_sk = 30;
UPDATE reason SET r_reason_desc = CASE :'locale'
  WHEN 'en' THEN 'Duplicate order' WHEN 'cs' THEN 'Duplicitní objednávka' END WHERE r_reason_sk = 31;
UPDATE reason SET r_reason_desc = CASE :'locale'
  WHEN 'en' THEN 'Missing accessory' WHEN 'cs' THEN 'Chybějící příslušenství' END WHERE r_reason_sk = 32;
UPDATE reason SET r_reason_desc = CASE :'locale'
  WHEN 'en' THEN 'Damaged packaging' WHEN 'cs' THEN 'Poškozený obal' END WHERE r_reason_sk = 33;
UPDATE reason SET r_reason_desc = CASE :'locale'
  WHEN 'en' THEN 'Other reason' WHEN 'cs' THEN 'Jiný důvod' END WHERE r_reason_sk = 34;
UPDATE reason SET r_reason_desc = CASE :'locale'
  WHEN 'en' THEN 'Manufacturer claim' WHEN 'cs' THEN 'Reklamace u výrobce' END WHERE r_reason_sk = 35;

COMMIT;

\echo '-- verification: no duplicate reason text; 35 distinct --'
SELECT count(*) AS total, count(DISTINCT btrim(r_reason_desc)) AS distinct_count FROM reason;
