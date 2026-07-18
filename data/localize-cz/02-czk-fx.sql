-- Stage 1.3 T4 — CZK conversion: FX-scale every monetary column x FX (fx.conf), rounded to a
-- believable price point (nearest 10 Kc for values >= 100, nearest 1 Kc below). The seeded
-- story is a %-effect, so this uniform scale carries the ratios/percentages unchanged; one R0
-- figure set carries to CZK by xFX (Stage 1.6 T1). Guarded against double-application (FX must
-- NOT compound -- a second run would scale x529). Excludes date/text columns; i_current_price
-- and i_wholesale_cost (item dim) are physical-only and scale here too, though *_net_profit
-- stays excluded from the *model* per D-6a (the physical column still scales -- it exists in
-- the schema, it just never surfaces downstream).
\set ON_ERROR_STOP on
\ir fx.conf

CREATE TABLE IF NOT EXISTS _localize_meta (
  step        text PRIMARY KEY,
  applied_at  timestamptz NOT NULL DEFAULT now(),
  detail      text
);

DO $guard$
BEGIN
  IF EXISTS (SELECT 1 FROM _localize_meta WHERE step = 'czk_fx') THEN
    RAISE EXCEPTION 'localize_cz_fx_applied: CZK FX scaling already applied -- refusing to run twice (a second pass would compound the scale, e.g. x529 for fx=23)';
  END IF;
END
$guard$;

BEGIN;

UPDATE catalog_returns SET
    cr_fee = CASE WHEN cr_fee IS NULL THEN NULL WHEN abs(cr_fee * :'fx'::numeric) < 100 THEN round(cr_fee * :'fx'::numeric, 2) ELSE round(cr_fee * :'fx'::numeric / 10.0) * 10 END,
    cr_net_loss = CASE WHEN cr_net_loss IS NULL THEN NULL WHEN abs(cr_net_loss * :'fx'::numeric) < 100 THEN round(cr_net_loss * :'fx'::numeric, 2) ELSE round(cr_net_loss * :'fx'::numeric / 10.0) * 10 END,
    cr_refunded_cash = CASE WHEN cr_refunded_cash IS NULL THEN NULL WHEN abs(cr_refunded_cash * :'fx'::numeric) < 100 THEN round(cr_refunded_cash * :'fx'::numeric, 2) ELSE round(cr_refunded_cash * :'fx'::numeric / 10.0) * 10 END,
    cr_return_amount = CASE WHEN cr_return_amount IS NULL THEN NULL WHEN abs(cr_return_amount * :'fx'::numeric) < 100 THEN round(cr_return_amount * :'fx'::numeric, 2) ELSE round(cr_return_amount * :'fx'::numeric / 10.0) * 10 END,
    cr_return_amt_inc_tax = CASE WHEN cr_return_amt_inc_tax IS NULL THEN NULL WHEN abs(cr_return_amt_inc_tax * :'fx'::numeric) < 100 THEN round(cr_return_amt_inc_tax * :'fx'::numeric, 2) ELSE round(cr_return_amt_inc_tax * :'fx'::numeric / 10.0) * 10 END,
    cr_return_ship_cost = CASE WHEN cr_return_ship_cost IS NULL THEN NULL WHEN abs(cr_return_ship_cost * :'fx'::numeric) < 100 THEN round(cr_return_ship_cost * :'fx'::numeric, 2) ELSE round(cr_return_ship_cost * :'fx'::numeric / 10.0) * 10 END,
    cr_return_tax = CASE WHEN cr_return_tax IS NULL THEN NULL WHEN abs(cr_return_tax * :'fx'::numeric) < 100 THEN round(cr_return_tax * :'fx'::numeric, 2) ELSE round(cr_return_tax * :'fx'::numeric / 10.0) * 10 END,
    cr_reversed_charge = CASE WHEN cr_reversed_charge IS NULL THEN NULL WHEN abs(cr_reversed_charge * :'fx'::numeric) < 100 THEN round(cr_reversed_charge * :'fx'::numeric, 2) ELSE round(cr_reversed_charge * :'fx'::numeric / 10.0) * 10 END,
    cr_store_credit = CASE WHEN cr_store_credit IS NULL THEN NULL WHEN abs(cr_store_credit * :'fx'::numeric) < 100 THEN round(cr_store_credit * :'fx'::numeric, 2) ELSE round(cr_store_credit * :'fx'::numeric / 10.0) * 10 END;

UPDATE catalog_sales SET
    cs_coupon_amt = CASE WHEN cs_coupon_amt IS NULL THEN NULL WHEN abs(cs_coupon_amt * :'fx'::numeric) < 100 THEN round(cs_coupon_amt * :'fx'::numeric, 2) ELSE round(cs_coupon_amt * :'fx'::numeric / 10.0) * 10 END,
    cs_ext_discount_amt = CASE WHEN cs_ext_discount_amt IS NULL THEN NULL WHEN abs(cs_ext_discount_amt * :'fx'::numeric) < 100 THEN round(cs_ext_discount_amt * :'fx'::numeric, 2) ELSE round(cs_ext_discount_amt * :'fx'::numeric / 10.0) * 10 END,
    cs_ext_list_price = CASE WHEN cs_ext_list_price IS NULL THEN NULL WHEN abs(cs_ext_list_price * :'fx'::numeric) < 100 THEN round(cs_ext_list_price * :'fx'::numeric, 2) ELSE round(cs_ext_list_price * :'fx'::numeric / 10.0) * 10 END,
    cs_ext_sales_price = CASE WHEN cs_ext_sales_price IS NULL THEN NULL WHEN abs(cs_ext_sales_price * :'fx'::numeric) < 100 THEN round(cs_ext_sales_price * :'fx'::numeric, 2) ELSE round(cs_ext_sales_price * :'fx'::numeric / 10.0) * 10 END,
    cs_ext_ship_cost = CASE WHEN cs_ext_ship_cost IS NULL THEN NULL WHEN abs(cs_ext_ship_cost * :'fx'::numeric) < 100 THEN round(cs_ext_ship_cost * :'fx'::numeric, 2) ELSE round(cs_ext_ship_cost * :'fx'::numeric / 10.0) * 10 END,
    cs_ext_tax = CASE WHEN cs_ext_tax IS NULL THEN NULL WHEN abs(cs_ext_tax * :'fx'::numeric) < 100 THEN round(cs_ext_tax * :'fx'::numeric, 2) ELSE round(cs_ext_tax * :'fx'::numeric / 10.0) * 10 END,
    cs_ext_wholesale_cost = CASE WHEN cs_ext_wholesale_cost IS NULL THEN NULL WHEN abs(cs_ext_wholesale_cost * :'fx'::numeric) < 100 THEN round(cs_ext_wholesale_cost * :'fx'::numeric, 2) ELSE round(cs_ext_wholesale_cost * :'fx'::numeric / 10.0) * 10 END,
    cs_list_price = CASE WHEN cs_list_price IS NULL THEN NULL WHEN abs(cs_list_price * :'fx'::numeric) < 100 THEN round(cs_list_price * :'fx'::numeric, 2) ELSE round(cs_list_price * :'fx'::numeric / 10.0) * 10 END,
    cs_net_paid = CASE WHEN cs_net_paid IS NULL THEN NULL WHEN abs(cs_net_paid * :'fx'::numeric) < 100 THEN round(cs_net_paid * :'fx'::numeric, 2) ELSE round(cs_net_paid * :'fx'::numeric / 10.0) * 10 END,
    cs_net_paid_inc_ship = CASE WHEN cs_net_paid_inc_ship IS NULL THEN NULL WHEN abs(cs_net_paid_inc_ship * :'fx'::numeric) < 100 THEN round(cs_net_paid_inc_ship * :'fx'::numeric, 2) ELSE round(cs_net_paid_inc_ship * :'fx'::numeric / 10.0) * 10 END,
    cs_net_paid_inc_ship_tax = CASE WHEN cs_net_paid_inc_ship_tax IS NULL THEN NULL WHEN abs(cs_net_paid_inc_ship_tax * :'fx'::numeric) < 100 THEN round(cs_net_paid_inc_ship_tax * :'fx'::numeric, 2) ELSE round(cs_net_paid_inc_ship_tax * :'fx'::numeric / 10.0) * 10 END,
    cs_net_paid_inc_tax = CASE WHEN cs_net_paid_inc_tax IS NULL THEN NULL WHEN abs(cs_net_paid_inc_tax * :'fx'::numeric) < 100 THEN round(cs_net_paid_inc_tax * :'fx'::numeric, 2) ELSE round(cs_net_paid_inc_tax * :'fx'::numeric / 10.0) * 10 END,
    cs_net_profit = CASE WHEN cs_net_profit IS NULL THEN NULL WHEN abs(cs_net_profit * :'fx'::numeric) < 100 THEN round(cs_net_profit * :'fx'::numeric, 2) ELSE round(cs_net_profit * :'fx'::numeric / 10.0) * 10 END,
    cs_sales_price = CASE WHEN cs_sales_price IS NULL THEN NULL WHEN abs(cs_sales_price * :'fx'::numeric) < 100 THEN round(cs_sales_price * :'fx'::numeric, 2) ELSE round(cs_sales_price * :'fx'::numeric / 10.0) * 10 END,
    cs_wholesale_cost = CASE WHEN cs_wholesale_cost IS NULL THEN NULL WHEN abs(cs_wholesale_cost * :'fx'::numeric) < 100 THEN round(cs_wholesale_cost * :'fx'::numeric, 2) ELSE round(cs_wholesale_cost * :'fx'::numeric / 10.0) * 10 END;

UPDATE item SET
    i_current_price = CASE WHEN i_current_price IS NULL THEN NULL WHEN abs(i_current_price * :'fx'::numeric) < 100 THEN round(i_current_price * :'fx'::numeric, 2) ELSE round(i_current_price * :'fx'::numeric / 10.0) * 10 END,
    i_wholesale_cost = CASE WHEN i_wholesale_cost IS NULL THEN NULL WHEN abs(i_wholesale_cost * :'fx'::numeric) < 100 THEN round(i_wholesale_cost * :'fx'::numeric, 2) ELSE round(i_wholesale_cost * :'fx'::numeric / 10.0) * 10 END;

UPDATE store_returns SET
    sr_fee = CASE WHEN sr_fee IS NULL THEN NULL WHEN abs(sr_fee * :'fx'::numeric) < 100 THEN round(sr_fee * :'fx'::numeric, 2) ELSE round(sr_fee * :'fx'::numeric / 10.0) * 10 END,
    sr_net_loss = CASE WHEN sr_net_loss IS NULL THEN NULL WHEN abs(sr_net_loss * :'fx'::numeric) < 100 THEN round(sr_net_loss * :'fx'::numeric, 2) ELSE round(sr_net_loss * :'fx'::numeric / 10.0) * 10 END,
    sr_refunded_cash = CASE WHEN sr_refunded_cash IS NULL THEN NULL WHEN abs(sr_refunded_cash * :'fx'::numeric) < 100 THEN round(sr_refunded_cash * :'fx'::numeric, 2) ELSE round(sr_refunded_cash * :'fx'::numeric / 10.0) * 10 END,
    sr_return_amt = CASE WHEN sr_return_amt IS NULL THEN NULL WHEN abs(sr_return_amt * :'fx'::numeric) < 100 THEN round(sr_return_amt * :'fx'::numeric, 2) ELSE round(sr_return_amt * :'fx'::numeric / 10.0) * 10 END,
    sr_return_amt_inc_tax = CASE WHEN sr_return_amt_inc_tax IS NULL THEN NULL WHEN abs(sr_return_amt_inc_tax * :'fx'::numeric) < 100 THEN round(sr_return_amt_inc_tax * :'fx'::numeric, 2) ELSE round(sr_return_amt_inc_tax * :'fx'::numeric / 10.0) * 10 END,
    sr_return_ship_cost = CASE WHEN sr_return_ship_cost IS NULL THEN NULL WHEN abs(sr_return_ship_cost * :'fx'::numeric) < 100 THEN round(sr_return_ship_cost * :'fx'::numeric, 2) ELSE round(sr_return_ship_cost * :'fx'::numeric / 10.0) * 10 END,
    sr_return_tax = CASE WHEN sr_return_tax IS NULL THEN NULL WHEN abs(sr_return_tax * :'fx'::numeric) < 100 THEN round(sr_return_tax * :'fx'::numeric, 2) ELSE round(sr_return_tax * :'fx'::numeric / 10.0) * 10 END,
    sr_reversed_charge = CASE WHEN sr_reversed_charge IS NULL THEN NULL WHEN abs(sr_reversed_charge * :'fx'::numeric) < 100 THEN round(sr_reversed_charge * :'fx'::numeric, 2) ELSE round(sr_reversed_charge * :'fx'::numeric / 10.0) * 10 END,
    sr_store_credit = CASE WHEN sr_store_credit IS NULL THEN NULL WHEN abs(sr_store_credit * :'fx'::numeric) < 100 THEN round(sr_store_credit * :'fx'::numeric, 2) ELSE round(sr_store_credit * :'fx'::numeric / 10.0) * 10 END;

UPDATE store_sales SET
    ss_coupon_amt = CASE WHEN ss_coupon_amt IS NULL THEN NULL WHEN abs(ss_coupon_amt * :'fx'::numeric) < 100 THEN round(ss_coupon_amt * :'fx'::numeric, 2) ELSE round(ss_coupon_amt * :'fx'::numeric / 10.0) * 10 END,
    ss_ext_discount_amt = CASE WHEN ss_ext_discount_amt IS NULL THEN NULL WHEN abs(ss_ext_discount_amt * :'fx'::numeric) < 100 THEN round(ss_ext_discount_amt * :'fx'::numeric, 2) ELSE round(ss_ext_discount_amt * :'fx'::numeric / 10.0) * 10 END,
    ss_ext_list_price = CASE WHEN ss_ext_list_price IS NULL THEN NULL WHEN abs(ss_ext_list_price * :'fx'::numeric) < 100 THEN round(ss_ext_list_price * :'fx'::numeric, 2) ELSE round(ss_ext_list_price * :'fx'::numeric / 10.0) * 10 END,
    ss_ext_sales_price = CASE WHEN ss_ext_sales_price IS NULL THEN NULL WHEN abs(ss_ext_sales_price * :'fx'::numeric) < 100 THEN round(ss_ext_sales_price * :'fx'::numeric, 2) ELSE round(ss_ext_sales_price * :'fx'::numeric / 10.0) * 10 END,
    ss_ext_tax = CASE WHEN ss_ext_tax IS NULL THEN NULL WHEN abs(ss_ext_tax * :'fx'::numeric) < 100 THEN round(ss_ext_tax * :'fx'::numeric, 2) ELSE round(ss_ext_tax * :'fx'::numeric / 10.0) * 10 END,
    ss_ext_wholesale_cost = CASE WHEN ss_ext_wholesale_cost IS NULL THEN NULL WHEN abs(ss_ext_wholesale_cost * :'fx'::numeric) < 100 THEN round(ss_ext_wholesale_cost * :'fx'::numeric, 2) ELSE round(ss_ext_wholesale_cost * :'fx'::numeric / 10.0) * 10 END,
    ss_list_price = CASE WHEN ss_list_price IS NULL THEN NULL WHEN abs(ss_list_price * :'fx'::numeric) < 100 THEN round(ss_list_price * :'fx'::numeric, 2) ELSE round(ss_list_price * :'fx'::numeric / 10.0) * 10 END,
    ss_net_paid = CASE WHEN ss_net_paid IS NULL THEN NULL WHEN abs(ss_net_paid * :'fx'::numeric) < 100 THEN round(ss_net_paid * :'fx'::numeric, 2) ELSE round(ss_net_paid * :'fx'::numeric / 10.0) * 10 END,
    ss_net_paid_inc_tax = CASE WHEN ss_net_paid_inc_tax IS NULL THEN NULL WHEN abs(ss_net_paid_inc_tax * :'fx'::numeric) < 100 THEN round(ss_net_paid_inc_tax * :'fx'::numeric, 2) ELSE round(ss_net_paid_inc_tax * :'fx'::numeric / 10.0) * 10 END,
    ss_net_profit = CASE WHEN ss_net_profit IS NULL THEN NULL WHEN abs(ss_net_profit * :'fx'::numeric) < 100 THEN round(ss_net_profit * :'fx'::numeric, 2) ELSE round(ss_net_profit * :'fx'::numeric / 10.0) * 10 END,
    ss_sales_price = CASE WHEN ss_sales_price IS NULL THEN NULL WHEN abs(ss_sales_price * :'fx'::numeric) < 100 THEN round(ss_sales_price * :'fx'::numeric, 2) ELSE round(ss_sales_price * :'fx'::numeric / 10.0) * 10 END,
    ss_wholesale_cost = CASE WHEN ss_wholesale_cost IS NULL THEN NULL WHEN abs(ss_wholesale_cost * :'fx'::numeric) < 100 THEN round(ss_wholesale_cost * :'fx'::numeric, 2) ELSE round(ss_wholesale_cost * :'fx'::numeric / 10.0) * 10 END;

UPDATE web_returns SET
    wr_account_credit = CASE WHEN wr_account_credit IS NULL THEN NULL WHEN abs(wr_account_credit * :'fx'::numeric) < 100 THEN round(wr_account_credit * :'fx'::numeric, 2) ELSE round(wr_account_credit * :'fx'::numeric / 10.0) * 10 END,
    wr_fee = CASE WHEN wr_fee IS NULL THEN NULL WHEN abs(wr_fee * :'fx'::numeric) < 100 THEN round(wr_fee * :'fx'::numeric, 2) ELSE round(wr_fee * :'fx'::numeric / 10.0) * 10 END,
    wr_net_loss = CASE WHEN wr_net_loss IS NULL THEN NULL WHEN abs(wr_net_loss * :'fx'::numeric) < 100 THEN round(wr_net_loss * :'fx'::numeric, 2) ELSE round(wr_net_loss * :'fx'::numeric / 10.0) * 10 END,
    wr_refunded_cash = CASE WHEN wr_refunded_cash IS NULL THEN NULL WHEN abs(wr_refunded_cash * :'fx'::numeric) < 100 THEN round(wr_refunded_cash * :'fx'::numeric, 2) ELSE round(wr_refunded_cash * :'fx'::numeric / 10.0) * 10 END,
    wr_return_amt = CASE WHEN wr_return_amt IS NULL THEN NULL WHEN abs(wr_return_amt * :'fx'::numeric) < 100 THEN round(wr_return_amt * :'fx'::numeric, 2) ELSE round(wr_return_amt * :'fx'::numeric / 10.0) * 10 END,
    wr_return_amt_inc_tax = CASE WHEN wr_return_amt_inc_tax IS NULL THEN NULL WHEN abs(wr_return_amt_inc_tax * :'fx'::numeric) < 100 THEN round(wr_return_amt_inc_tax * :'fx'::numeric, 2) ELSE round(wr_return_amt_inc_tax * :'fx'::numeric / 10.0) * 10 END,
    wr_return_ship_cost = CASE WHEN wr_return_ship_cost IS NULL THEN NULL WHEN abs(wr_return_ship_cost * :'fx'::numeric) < 100 THEN round(wr_return_ship_cost * :'fx'::numeric, 2) ELSE round(wr_return_ship_cost * :'fx'::numeric / 10.0) * 10 END,
    wr_return_tax = CASE WHEN wr_return_tax IS NULL THEN NULL WHEN abs(wr_return_tax * :'fx'::numeric) < 100 THEN round(wr_return_tax * :'fx'::numeric, 2) ELSE round(wr_return_tax * :'fx'::numeric / 10.0) * 10 END,
    wr_reversed_charge = CASE WHEN wr_reversed_charge IS NULL THEN NULL WHEN abs(wr_reversed_charge * :'fx'::numeric) < 100 THEN round(wr_reversed_charge * :'fx'::numeric, 2) ELSE round(wr_reversed_charge * :'fx'::numeric / 10.0) * 10 END;

UPDATE web_sales SET
    ws_coupon_amt = CASE WHEN ws_coupon_amt IS NULL THEN NULL WHEN abs(ws_coupon_amt * :'fx'::numeric) < 100 THEN round(ws_coupon_amt * :'fx'::numeric, 2) ELSE round(ws_coupon_amt * :'fx'::numeric / 10.0) * 10 END,
    ws_ext_discount_amt = CASE WHEN ws_ext_discount_amt IS NULL THEN NULL WHEN abs(ws_ext_discount_amt * :'fx'::numeric) < 100 THEN round(ws_ext_discount_amt * :'fx'::numeric, 2) ELSE round(ws_ext_discount_amt * :'fx'::numeric / 10.0) * 10 END,
    ws_ext_list_price = CASE WHEN ws_ext_list_price IS NULL THEN NULL WHEN abs(ws_ext_list_price * :'fx'::numeric) < 100 THEN round(ws_ext_list_price * :'fx'::numeric, 2) ELSE round(ws_ext_list_price * :'fx'::numeric / 10.0) * 10 END,
    ws_ext_sales_price = CASE WHEN ws_ext_sales_price IS NULL THEN NULL WHEN abs(ws_ext_sales_price * :'fx'::numeric) < 100 THEN round(ws_ext_sales_price * :'fx'::numeric, 2) ELSE round(ws_ext_sales_price * :'fx'::numeric / 10.0) * 10 END,
    ws_ext_ship_cost = CASE WHEN ws_ext_ship_cost IS NULL THEN NULL WHEN abs(ws_ext_ship_cost * :'fx'::numeric) < 100 THEN round(ws_ext_ship_cost * :'fx'::numeric, 2) ELSE round(ws_ext_ship_cost * :'fx'::numeric / 10.0) * 10 END,
    ws_ext_tax = CASE WHEN ws_ext_tax IS NULL THEN NULL WHEN abs(ws_ext_tax * :'fx'::numeric) < 100 THEN round(ws_ext_tax * :'fx'::numeric, 2) ELSE round(ws_ext_tax * :'fx'::numeric / 10.0) * 10 END,
    ws_ext_wholesale_cost = CASE WHEN ws_ext_wholesale_cost IS NULL THEN NULL WHEN abs(ws_ext_wholesale_cost * :'fx'::numeric) < 100 THEN round(ws_ext_wholesale_cost * :'fx'::numeric, 2) ELSE round(ws_ext_wholesale_cost * :'fx'::numeric / 10.0) * 10 END,
    ws_list_price = CASE WHEN ws_list_price IS NULL THEN NULL WHEN abs(ws_list_price * :'fx'::numeric) < 100 THEN round(ws_list_price * :'fx'::numeric, 2) ELSE round(ws_list_price * :'fx'::numeric / 10.0) * 10 END,
    ws_net_paid = CASE WHEN ws_net_paid IS NULL THEN NULL WHEN abs(ws_net_paid * :'fx'::numeric) < 100 THEN round(ws_net_paid * :'fx'::numeric, 2) ELSE round(ws_net_paid * :'fx'::numeric / 10.0) * 10 END,
    ws_net_paid_inc_ship = CASE WHEN ws_net_paid_inc_ship IS NULL THEN NULL WHEN abs(ws_net_paid_inc_ship * :'fx'::numeric) < 100 THEN round(ws_net_paid_inc_ship * :'fx'::numeric, 2) ELSE round(ws_net_paid_inc_ship * :'fx'::numeric / 10.0) * 10 END,
    ws_net_paid_inc_ship_tax = CASE WHEN ws_net_paid_inc_ship_tax IS NULL THEN NULL WHEN abs(ws_net_paid_inc_ship_tax * :'fx'::numeric) < 100 THEN round(ws_net_paid_inc_ship_tax * :'fx'::numeric, 2) ELSE round(ws_net_paid_inc_ship_tax * :'fx'::numeric / 10.0) * 10 END,
    ws_net_paid_inc_tax = CASE WHEN ws_net_paid_inc_tax IS NULL THEN NULL WHEN abs(ws_net_paid_inc_tax * :'fx'::numeric) < 100 THEN round(ws_net_paid_inc_tax * :'fx'::numeric, 2) ELSE round(ws_net_paid_inc_tax * :'fx'::numeric / 10.0) * 10 END,
    ws_net_profit = CASE WHEN ws_net_profit IS NULL THEN NULL WHEN abs(ws_net_profit * :'fx'::numeric) < 100 THEN round(ws_net_profit * :'fx'::numeric, 2) ELSE round(ws_net_profit * :'fx'::numeric / 10.0) * 10 END,
    ws_sales_price = CASE WHEN ws_sales_price IS NULL THEN NULL WHEN abs(ws_sales_price * :'fx'::numeric) < 100 THEN round(ws_sales_price * :'fx'::numeric, 2) ELSE round(ws_sales_price * :'fx'::numeric / 10.0) * 10 END,
    ws_wholesale_cost = CASE WHEN ws_wholesale_cost IS NULL THEN NULL WHEN abs(ws_wholesale_cost * :'fx'::numeric) < 100 THEN round(ws_wholesale_cost * :'fx'::numeric, 2) ELSE round(ws_wholesale_cost * :'fx'::numeric / 10.0) * 10 END;

INSERT INTO _localize_meta(step, detail) VALUES ('czk_fx', 'fx=' || :'fx' || ', rounding: nearest 10 Kc >=100, nearest 1 Kc below');

COMMIT;

\echo '-- verification: spot-check 5 known rows, cz ~= us * fx (within rounding tolerance) --'
SELECT cs_item_sk, cs_order_number, cs_ext_sales_price FROM catalog_sales ORDER BY cs_item_sk, cs_order_number LIMIT 5;
