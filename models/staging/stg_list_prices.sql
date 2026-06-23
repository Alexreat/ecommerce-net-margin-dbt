-- Manufacturer list prices, per effective period. The product key is MSPN
-- (try_cast to bigint, NULL on non-numeric values). $0 source prices are mapped to
-- NULL (placeholder/unpriced articles) so they fall through to the $-rebate path or
-- go ineligible instead of booking a real $0 rebate. The as-of period match against
-- order_date happens in int_list_prices_periods.
select
    Article_ID                              as article_id,
    try_cast(MSPN as bigint)                as mspn,
    manufacturer_name_encoded               as manufacturer_name,
    nullif(List_Price, 0)                   as list_price,
    cast(Effective_From_List_Price as date) as effective_from
from {{ ref('raw_list_prices') }}
