-- Rebate amount for eligible lines. The two paths are mutually exclusive and the
-- % path wins when both are present:
--   % path: max_rebate_pct x list_price x quantity (needs a backing list price).
--   $ path: max_rebate_amount x quantity (fixed-dollar fallback).
-- Not eligible -> 0 (never NULL).
select
    *,
    case
        when rebate_eligible = 'Yes'
            and coalesce(max_rebate_pct, 0) > 0
            and list_price is not null
        then coalesce(max_rebate_pct, 0) * coalesce(list_price, 0) * coalesce(line_quantity, 0)

        when rebate_eligible = 'Yes'
            and coalesce(max_rebate_amount, 0) > 0
        then coalesce(max_rebate_amount, 0) * coalesce(line_quantity, 0)

        else 0
    end as rebate_amount
from {{ ref('int_sales_rebate_eligibility') }}
