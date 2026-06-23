-- Total cost (formula owned by Finance):
--   supplier buying price + base shipping cost (C, board flat rate) + supplier
--   delivery fee (D, per-postcode fee) + fitting cost ($0 placeholder).
-- C and D are DISTINCT costs and both belong. Naming guard: base_shipping_cost = C
-- (board); supplier_delivery_fee = D (fee table) -- do not swap them.
select
    *,
    coalesce(supplier_total_buying_price, 0)
        + coalesce(base_shipping_cost, 0)
        + coalesce(supplier_delivery_fee, 0)
        + 0  -- fitting cost: $0 placeholder (kept for future markets)
    as total_cost
from {{ ref('int_sales_revenue') }}
