-- Granular per-postcode shipping fee table (cost component D): one fee per
-- supplier x warehouse x FSA x rim band. The source 'Matrix' column encodes the
-- rim-size band as free text; it is parsed here into an inclusive [rim_min, rim_max]
-- range. Defensive dedup: max(fee) on duplicate source keys never under-reports cost.
with raw as (
    select
        Supplier                            as clean_supplier,
        upper(ltrim(rtrim(Warehouse)))      as warehouse,
        upper(ltrim(rtrim(Postal_Code)))    as fsa,
        case
            when Matrix like '%18%' then 0
            when Matrix like '%19%' then 19
            else 0
        end                                 as rim_min,
        case
            when Matrix like '%18%' then 18
            when Matrix like '%19%' then 9999
            else 9999
        end                                 as rim_max,
        Shipping_Fee                        as shipping_fee
    from {{ ref('raw_shipping_fees') }}
)

select
    clean_supplier,
    warehouse,
    fsa,
    rim_min,
    rim_max,
    max(shipping_fee) as shipping_fee
from raw
group by
    clean_supplier,
    warehouse,
    fsa,
    rim_min,
    rim_max
