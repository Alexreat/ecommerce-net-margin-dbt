-- Rebate agreement status + validity window. Drives eligibility: an order is only
-- rebate-eligible if the agreement status is in var('rebate_valid_statuses') and the
-- sales date falls inside [rebate_start_date, rebate_end_date].
select
    AgreementNumber             as agreement_number,
    Status                      as rebate_status,
    cast(Period_Start as date)  as rebate_start_date,
    cast(Period_End as date)    as rebate_end_date
from {{ ref('raw_rebates_board') }}
