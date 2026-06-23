-- Net margin %. DELIVERY lines are intentionally NULL (they have no meaningful
-- margin but must still reach the fact). Zero-revenue handling is a provisional
-- engineering placeholder, not a Finance-ratified rule:
--   revenue = 0 & cost > 0 -> -100% ; revenue = 0 & cost = 0 -> 0%.
select
    *,
    case
        when line_category = 'DELIVERY' then null
        when revenue <> 0 then (net_profit / revenue) * 100
        when revenue = 0 and total_cost > 0 then -100.00
        else 0.00
    end as net_margin_pct
from {{ ref('int_sales_profit') }}
