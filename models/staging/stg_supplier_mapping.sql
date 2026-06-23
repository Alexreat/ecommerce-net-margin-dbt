-- Messy sales supplier name -> clean supplier name. Kept as one row per messy
-- name (a fan-out here would multiply every sales line). A missing match is
-- handled downstream with a NO_MATCH fallback, never a failed join.
select
    Messy_Sales_Name    as messy_sales_name,
    Clean_Board_Name    as clean_supplier,
    Notes               as notes
from {{ ref('raw_supplier_mapping') }}
