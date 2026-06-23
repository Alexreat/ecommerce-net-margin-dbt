-- Staging is the volatility boundary: ALL raw-feed quirks (column names, casing,
-- type coercion) are absorbed here so the intermediate/mart layers never have to
-- change when an upstream file is reshaped. In production this model reads from a
-- warehouse `source()`; here it reads the seed that emulates that landed feed.
-- Note: the ARTICLE/RIM/DELIVERY + INVOICED + date-cutoff filters live downstream
-- in int_sales_mapped (business rules), not here (this layer only normalises shape).
select
    articleId                                       as article_id,
    referenceId                                     as reference_id,
    try_cast(partNumber as bigint)                  as mspn,
    orderNumber                                     as order_number,
    invoiceNumber                                   as invoice_number,
    cast(orderDate as date)                         as order_date,
    supplier,
    cast(invoiceDate as date)                       as invoice_date,
    articlesTotalSelloutPriceExclTaxesExclDiscount  as articles_total_sellout_price_excl_taxes_excl_discount,
    lineTotalDiscountExclTaxes                      as line_total_discount_excl_taxes,
    deliveryFeeTotalExclTaxes                       as delivery_fee_total_excl_taxes,
    supplierTotalBuyingPrice                        as supplier_total_buying_price,
    fittingSellinPrice                              as fitting_sellin_price,
    lineCategory                                    as line_category,
    lineQuantity                                    as line_quantity,
    DeliveryShippingFeePerTireExclTaxes             as delivery_shipping_fee_per_tire_excl_taxes,
    DeliveryContributionFeePerTireExclTaxes         as delivery_contribution_fee_per_tire_excl_taxes,
    status                                          as sales_status,
    customerPostalCode                              as customer_postal_code,
    try_cast(rimDiameter as integer)                as rim_diameter,
    warehouseName                                   as warehouse_name
from {{ ref('raw_sales') }}
