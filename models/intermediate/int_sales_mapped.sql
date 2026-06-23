-- Resolve the messy supplier + warehouse names to their clean equivalents, then
-- apply the in-scope business filters. Defensive design:
--   * A missing supplier match becomes 'NO_MATCH' (coalesce) instead of dropping
--     the row or failing the join -- the row is routed to orphan quarantine later.
--   * The category / status / date-cutoff filters are BUSINESS rules and live here,
--     not in staging. The 2025 cutoff date is a data-quality decision; exposing its
--     placement as a model edit (vs a literal scattered downstream) is engineering.
select
    s.article_id,
    s.reference_id,
    s.mspn,
    s.customer_postal_code,
    s.rim_diameter,
    s.warehouse_name,
    w.clean_warehouse,
    s.order_number,
    s.invoice_number,
    s.supplier,
    coalesce(m.clean_supplier, 'NO_MATCH') as clean_supplier,
    s.invoice_date,
    s.order_date,
    s.articles_total_sellout_price_excl_taxes_excl_discount,
    s.line_total_discount_excl_taxes,
    s.delivery_fee_total_excl_taxes,
    s.supplier_total_buying_price,
    s.fitting_sellin_price,
    s.line_category,
    s.line_quantity,
    s.delivery_shipping_fee_per_tire_excl_taxes,
    s.delivery_contribution_fee_per_tire_excl_taxes,
    s.sales_status
from {{ ref('stg_sales') }} as s
left join {{ ref('stg_supplier_mapping') }} as m
    on s.supplier = m.messy_sales_name
left join {{ ref('stg_warehouse_mapping') }} as w
    on w.clean_supplier = coalesce(m.clean_supplier, 'NO_MATCH')
    and w.warehouse_name = upper(ltrim(rtrim(s.warehouse_name)))
where
    s.line_category in ('ARTICLE', 'RIM', 'DELIVERY')
    and s.sales_status = 'INVOICED'
    and s.invoice_date >= cast('2025-01-01' as date)
