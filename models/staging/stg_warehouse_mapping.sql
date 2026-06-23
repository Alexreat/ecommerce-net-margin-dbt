-- Maps the messy per-supplier warehouse name seen in sales to the clean warehouse
-- name used by the shipping-fee table. Uppercased/trimmed on both sides so the
-- join in int_sales_mapped is case/whitespace insensitive.
select
    clean_supplier,
    upper(ltrim(rtrim(warehouse_name)))  as warehouse_name,
    upper(ltrim(rtrim(clean_warehouse))) as clean_warehouse
from {{ ref('warehouse_mapping') }}
