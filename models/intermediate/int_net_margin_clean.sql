-- Clean COMMERCIAL margin rows (revenue - cost, NO rebate). Stamped COMMERCIAL_V1.
-- This is one of the two formula versions unioned into fct_net_margin; the other is
-- int_financial_net_margin_clean (FINANCIAL_V1). The column list is kept identical to
-- the financial model so the two can be unioned directly. Rebate columns are null/0
-- here by definition -- the commercial figure ignores rebates.
-- Kept if the margin is within the accepted bounds; DELIVERY lines (null margin) are
-- always kept and are never quarantined.
select
    article_id,
    reference_id,
    order_number,
    invoice_number,
    supplier,
    clean_supplier,
    invoice_date,
    order_date,
    line_category,
    line_quantity,
    articles_total_sellout_price_excl_taxes_excl_discount,
    line_total_discount_excl_taxes,
    delivery_fee_total_excl_taxes,
    fitting_sellin_price,
    supplier_total_buying_price,
    delivery_customer_charge,
    delivery_contribution_fee_per_tire_excl_taxes,
    delivery_contribution_total,
    base_shipping_cost,
    supplier_delivery_fee,
    revenue,
    total_cost,
    net_profit,
    net_margin_pct,
    cast(null as varchar) as rebate_agreement_number,
    cast(null as date)    as rebate_start_date,
    cast(null as date)    as rebate_end_date,
    cast(null as varchar) as rebate_eligible,
    0                     as rebate_amount,
    'COMMERCIAL_V1'       as formula_version
from {{ ref('int_sales_margin') }}
where
    line_category = 'DELIVERY'
    or net_margin_pct between {{ var('margin_lower_bound') }} and {{ var('margin_upper_bound') }}
