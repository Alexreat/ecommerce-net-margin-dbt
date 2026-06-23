-- Quarantine: sales rows whose supplier did not map (clean_supplier = 'NO_MATCH').
-- They are captured here for monitoring instead of silently dropped or crashing a
-- join. The fix is data (add the missing row to the mapping dictionary), not code.
-- DELIVERY lines are intentionally NO_MATCH too (blank supplier by design), so they
-- are excluded here: they are expected, not genuine orphans, and they flow to the
-- fact via int_sales_enriched. This keeps the monitor focused on real mapping gaps.
select
    article_id,
    reference_id,
    order_number,
    invoice_number,
    supplier,
    clean_supplier,
    invoice_date,
    articles_total_sellout_price_excl_taxes_excl_discount,
    line_total_discount_excl_taxes,
    delivery_fee_total_excl_taxes,
    fitting_sellin_price,
    line_category,
    line_quantity,
    delivery_shipping_fee_per_tire_excl_taxes,
    sales_status
from {{ ref('int_sales_mapped') }}
where
    clean_supplier = 'NO_MATCH'
    and line_category <> 'DELIVERY'
