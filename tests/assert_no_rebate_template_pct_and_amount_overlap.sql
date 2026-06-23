-- Singular data test: a rebate template row must carry a % OR a $ amount, never both.
-- The eligibility/amount logic assumes the two paths are mutually exclusive, so this
-- guards the assumption at the source. The test passes when it returns zero rows.
select
    reference_id,
    rebate_agreement_number,
    rebate_pct,
    rebate_amount
from {{ ref('stg_rebates_template') }}
where
    coalesce(rebate_pct, 0) > 0
    and coalesce(rebate_amount, 0) > 0
