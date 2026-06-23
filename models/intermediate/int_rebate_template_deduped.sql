-- Defensive dedup: collapse the rebate template to exactly one row per
-- (reference, agreement) using MAX(). A fan-out here would multiply every matching
-- sales line, so this guard is mandatory before the row is joined to sales.
select
    reference_id,
    rebate_agreement_number,
    max(rebate_pct) as max_rebate_pct,
    max(rebate_amount) as max_rebate_amount
from {{ ref('stg_rebates_template') }}
group by
    reference_id,
    rebate_agreement_number
