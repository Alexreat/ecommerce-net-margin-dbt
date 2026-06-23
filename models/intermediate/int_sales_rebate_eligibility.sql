-- Rebate eligibility (business-owned rule, engineering-owned wiring). A line is
-- eligible when:
--   * the agreement status is one of var('rebate_valid_statuses'), AND
--   * the configured sales date (var('rebate_sales_date_field')) falls inside the
--     agreement window, AND
--   * there is something to pay: a % with a backing list price, OR a fixed $ amount.
-- The valid statuses and the driving date field are vars so a business change is a
-- config edit, never a SQL rewrite.
select
    *,
    case
        when rebate_status in (
            {%- for status in var('rebate_valid_statuses') -%}
                '{{ status }}'{% if not loop.last %}, {% endif %}
            {%- endfor -%}
        )
            and {{ var('rebate_sales_date_field') }} between rebate_start_date and rebate_end_date
            and (
                (coalesce(max_rebate_pct, 0) > 0 and list_price is not null)
                or coalesce(max_rebate_amount, 0) > 0
            )
        then 'Yes'
        else 'No'
    end as rebate_eligible
from {{ ref('int_sales_rebate_inputs') }}
