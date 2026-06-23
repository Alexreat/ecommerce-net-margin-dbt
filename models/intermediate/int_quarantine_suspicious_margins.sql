-- Quarantine: rows whose margin is implausible (above the upper bound, below the
-- lower bound, or NULL on a non-DELIVERY line). The route-out *mechanism* is
-- engineering; the bound *values* are tunable vars (provisional defaults). DELIVERY
-- lines are excluded here -- their NULL margin is expected, not suspicious.
select
    *,
    case
        when net_margin_pct > {{ var('margin_upper_bound') }} then 'MARGIN_TOO_HIGH'
        when net_margin_pct < {{ var('margin_lower_bound') }} then 'MARGIN_TOO_LOW'
        when net_margin_pct is null then 'MARGIN_NULL'
    end as quarantine_reason
from {{ ref('int_sales_margin') }}
where
    line_category <> 'DELIVERY'
    and (
        net_margin_pct > {{ var('margin_upper_bound') }}
        or net_margin_pct < {{ var('margin_lower_bound') }}
        or net_margin_pct is null
    )
