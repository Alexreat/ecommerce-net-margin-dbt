-- Supplier board: one flat base shipping rate per supplier. Supplies cost
-- component C (base_shipping_cost). Distinct from the granular per-postcode fee
-- table (cost component D) -- both are real costs and both are kept.
select
    Name_Supplier               as clean_supplier,
    BaseShippingChargePerTyre   as base_shipping_charge_per_tyre
from {{ ref('raw_supplier_board') }}
