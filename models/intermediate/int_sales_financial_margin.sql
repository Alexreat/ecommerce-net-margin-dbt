-- Financial net margin %. Same shape as the commercial margin model but on
-- rebate-inclusive revenue. DELIVERY lines stay NULL; the same zero-revenue
-- placeholder rules apply.
select
    *,
    financial_revenue - total_cost as financial_net_profit,
    case
        when line_category = 'DELIVERY' then null
        when financial_revenue <> 0 then ((financial_revenue - total_cost) / financial_revenue) * 100
        when financial_revenue = 0 and total_cost > 0 then -100.00
        else 0.00
    end as financial_net_margin_pct
from {{ ref('int_sales_financial_revenue') }}
