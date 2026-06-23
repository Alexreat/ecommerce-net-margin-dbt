-- Attach the rebate dictionary (on reference_id) and the effective-dated list price
-- (as-of join on mspn + order_date inside the price period) to each costed sales row.
-- Both are LEFT joins: a line with no rebate / no list price simply carries NULLs and
-- is handled by the eligibility rules downstream.
select
    s.*,
    r.rebate_agreement_number,
    r.max_rebate_pct,
    r.max_rebate_amount,
    r.rebate_status,
    r.rebate_start_date,
    r.rebate_end_date,
    lp.list_price
from {{ ref('int_sales_cost') }} as s
left join {{ ref('int_rebate_dictionary') }} as r
    on s.reference_id = r.reference_id
left join {{ ref('int_list_prices_periods') }} as lp
    on s.mspn = lp.mspn
    and s.order_date >= lp.effective_from
    and (s.order_date < lp.valid_to or lp.valid_to is null)
