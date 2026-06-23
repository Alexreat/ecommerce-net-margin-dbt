-- Financial revenue = commercial revenue + supplier rebate. This is the single
-- difference between COMMERCIAL_V1 and FINANCIAL_V1; cost is identical for both.
select
    *,
    revenue + rebate_amount as financial_revenue
from {{ ref('int_sales_rebate_amount') }}
