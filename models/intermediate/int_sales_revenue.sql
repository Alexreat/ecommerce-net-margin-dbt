-- Commercial revenue (formula owned by Finance):
--   sellout + line discount (arrives NEGATIVE, so it is added) + delivery fee (A,
--   the DELIVERY-line total) + fitting sell-in (a $0 placeholder in this market).
select
    *,
    coalesce(articles_total_sellout_price_excl_taxes_excl_discount, 0)
        + coalesce(line_total_discount_excl_taxes, 0)
        + coalesce(delivery_fee_total_excl_taxes, 0)
        + coalesce(fitting_sellin_price, 0)
    as revenue
-- delivery_customer_charge (B) is intentionally NOT summed into revenue: it reconstructs
-- the SAME delivery money as A (the DELIVERY-line total) from the per-tyre fee on article
-- lines, so adding both would double-count on delivery-bearing orders (non-delivery orders
-- correctly contribute $0). B is retained as an audit-only column carried to the fact.
from {{ ref('int_sales_enriched') }}
