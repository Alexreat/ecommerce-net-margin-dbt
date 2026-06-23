-- Attach the two distinct shipping costs to each mapped sales line:
--   * base_shipping_cost (C) -- supplier board flat rate x quantity.
--   * supplier_delivery_fee (D) -- granular per-postcode fee x quantity, keyed on
--     supplier + clean warehouse + FSA + rim band (an as-of-style range match on rim).
-- Also derives the customer FSA from the postal code and the customer delivery
-- charge (B), kept net of the per-tyre contribution fee. Every join uses coalesce
-- so a missing reference simply contributes $0 rather than nulling the whole row.
-- The WHERE keeps valid-supplier rows AND DELIVERY lines (which are NO_MATCH by
-- design but must still reach the fact with a null margin).
with sales as (
    select
        m.*,
        upper(left(replace(coalesce(m.customer_postal_code, ''), ' ', ''), 3)) as customer_fsa
    from {{ ref('int_sales_mapped') }} as m
)

select
    sales.article_id,
    sales.reference_id,
    sales.mspn,
    sales.customer_postal_code,
    sales.customer_fsa,
    sales.rim_diameter,
    sales.warehouse_name,
    sales.clean_warehouse,
    sales.order_number,
    sales.invoice_number,
    sales.supplier,
    sales.clean_supplier,
    sales.invoice_date,
    sales.order_date,
    sales.articles_total_sellout_price_excl_taxes_excl_discount,
    sales.line_total_discount_excl_taxes,
    sales.delivery_fee_total_excl_taxes,
    sales.supplier_total_buying_price,
    sales.fitting_sellin_price,
    sales.line_category,
    sales.line_quantity,
    sales.delivery_shipping_fee_per_tire_excl_taxes,
    sales.delivery_contribution_fee_per_tire_excl_taxes,
    sales.sales_status,
    f.shipping_fee as supplier_delivery_fee_per_tyre,
    coalesce(sales.line_quantity, 0) * coalesce(f.shipping_fee, 0) as supplier_delivery_fee,
    b.base_shipping_charge_per_tyre,
    coalesce(sales.line_quantity, 0) * coalesce(b.base_shipping_charge_per_tyre, 0) as base_shipping_cost,
    coalesce(sales.line_quantity, 0)
        * (coalesce(sales.delivery_shipping_fee_per_tire_excl_taxes, 0)
           - coalesce(sales.delivery_contribution_fee_per_tire_excl_taxes, 0)) as delivery_customer_charge,
    coalesce(sales.line_quantity, 0) * coalesce(sales.delivery_contribution_fee_per_tire_excl_taxes, 0) as delivery_contribution_total
from sales
left join {{ ref('stg_shipping_fees') }} as f
    on f.clean_supplier = sales.clean_supplier
    and f.warehouse     = sales.clean_warehouse
    and f.fsa           = sales.customer_fsa
    and coalesce(sales.rim_diameter, 0) between f.rim_min and f.rim_max
left join {{ ref('stg_supplier_board') }} as b
    on b.clean_supplier = sales.clean_supplier
where
    sales.clean_supplier <> 'NO_MATCH'
    or sales.line_category = 'DELIVERY'
