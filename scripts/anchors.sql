-- IE-C64 — the real anchors the simulated history hangs from.
--
-- One row per instrument the estate has EVER held (including closed positions — a portfolio that
-- sold something still needs its price at the quarters it held it) that the provider has a price
-- for. On hartland at IE-P1·S1.5 that is 56 of 59 ever-held ISINs; the 3 unpriced ones have no
-- anchor to walk back from and are correctly absent rather than invented.
--
-- NOT all 2016 priced ISINs: the other ~1960 are instruments the distributor quotes and this estate
-- has never touched, and generating two years of fiction for them would be volume, not fidelity.
--
-- `max(price_date)` per ISIN is defensive. The table is keyed (isin, price_date) and today holds
-- exactly one row per ISIN — which is the whole reason IE-C64 exists — but this script must not
-- start emitting several anchors per instrument the day that changes.
SELECT json_agg(json_build_object(
         'isin', isin, 'anchorDate', price_date, 'anchorPrice', price::text, 'currency', trim(currency)
       ) ORDER BY isin)
FROM (
  SELECT DISTINCT ON (ap.isin) ap.isin, ap.price_date, ap.price, ap.currency
  FROM investment_asset_price ap
  WHERE ap.isin IN (SELECT DISTINCT asset_ref FROM investment_position)
  ORDER BY ap.isin, ap.price_date DESC
) anchors;
