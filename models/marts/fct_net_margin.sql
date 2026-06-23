-- Net-margin fact, one row per order line PER formula version.
--   * COMMERCIAL_V1 = revenue - cost (no rebate)         -> int_net_margin_clean
--   * FINANCIAL_V1  = commercial + supplier rebate added -> int_financial_net_margin_clean
-- Both versions share the same grain and column shape, so they union directly and a
-- BI tool can simply filter by formula_version. Total rows are therefore ~2x a single
-- version. Cost (and the C/D breakdown) is identical across versions; only revenue,
-- profit and margin differ. The raw revenue/cost inputs are carried through so a
-- validator can reconstruct every figure from the fact alone.
select * from {{ ref('int_net_margin_clean') }}

union all

select * from {{ ref('int_financial_net_margin_clean') }}
