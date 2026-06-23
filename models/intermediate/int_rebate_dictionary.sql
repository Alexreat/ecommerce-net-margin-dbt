-- Join the deduped rebate values to the agreement's status + validity window.
-- The result is one row per reference: the single source of rebate truth that gets
-- attached to sales for the FINANCIAL_V1 calculation.
select
    t.reference_id,
    t.rebate_agreement_number,
    t.max_rebate_pct,
    t.max_rebate_amount,
    b.rebate_status,
    b.rebate_start_date,
    b.rebate_end_date
from {{ ref('int_rebate_template_deduped') }} as t
left join {{ ref('stg_rebates_board') }} as b
    on t.rebate_agreement_number = b.agreement_number
