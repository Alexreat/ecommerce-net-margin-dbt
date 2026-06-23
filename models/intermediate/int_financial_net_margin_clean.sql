-- Clean FINANCIAL margin rows (rebate-inclusive). Stamped FINANCIAL_V1. Column list
-- is identical to int_net_margin_clean (COMMERCIAL_V1) so the two are unioned directly
-- in fct_net_margin. Kept if the financial margin is within bounds; DELIVERY lines
-- (null margin) are always kept.
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
    financial_revenue as revenue,
    total_cost,
    financial_net_profit as net_profit,
    financial_net_margin_pct as net_margin_pct,
    rebate_agreement_number,
    rebate_start_date,
    rebate_end_date,
    rebate_eligible,
    rebate_amount,
    'FINANCIAL_V1' as formula_version
from {{ ref('int_sales_financial_margin') }}
where
    line_category = 'DELIVERY'
    or financial_net_margin_pct between {{ var('margin_lower_bound') }} and {{ var('margin_upper_bound') }}
