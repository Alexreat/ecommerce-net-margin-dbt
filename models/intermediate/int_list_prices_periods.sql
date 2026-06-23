-- Turn the list-price feed into effective-dated periods for an as-of join.
-- One row per (mspn, effective_from); valid_to = the next period's start (via LEAD),
-- NULL meaning "still current". Sales then match the single price whose
-- [effective_from, valid_to) window contains the order date -- not a blunt MAX(price).
-- Defensive: non-numeric MSPNs (NULL after try_cast) are dropped, and duplicate
-- (mspn, effective_from) rows are collapsed with MAX() before the LEAD.
with deduped as (
    select
        mspn,
        effective_from,
        max(list_price) as list_price
    from {{ ref('stg_list_prices') }}
    where mspn is not null
    group by mspn, effective_from
)

select
    mspn,
    effective_from,
    list_price,
    lead(effective_from) over (
        partition by mspn
        order by effective_from
    ) as valid_to
from deduped
