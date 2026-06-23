-- Rebate template: a % value and/or a fixed $ value per (reference, agreement).
-- A singular test (tests/assert_no_rebate_template_pct_and_amount_overlap.sql)
-- asserts a row never carries both at once. Deduped to one row per key downstream.
select
    referenceID             as reference_id,
    RebateAgreementNumber   as rebate_agreement_number,
    rebate_pct,
    rebate_amount
from {{ ref('raw_rebates_template') }}
