select
    *,
    revenue - total_cost as net_profit
from {{ ref('int_sales_cost') }}
