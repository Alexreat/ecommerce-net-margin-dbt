# Source contracts & change playbook  *(the part that churns)*

Read this **only when touching a source feed**. Everything here is expected to change as upstream data
is reshaped. The durable business rules live in [`DESIGN_NOTES.md`](DESIGN_NOTES.md) and should **not**
be edited for a format change.

> **Rule of thumb:** a feed changed shape → edit the matching `stg_*` model + update its row below.
> Nothing downstream should need to move.

In this portfolio build the "sources" are CSV **seeds** that emulate landed raw feeds. In a real
warehouse they would be `source()` tables; the staging contract is identical either way.

## Source → staging map

| Raw feed (seed) | Staging model | Feeds | Notes / defensive contract |
|---|---|---|---|
| `raw_sales` | `stg_sales` | everything (the order-line spine) | Fuzzy feed. Category/`INVOICED`/date-cutoff filters happen in `int_sales_mapped`, not here. Carries postal code (→ FSA) and rim diameter for the shipping join. |
| `raw_supplier_mapping` | `stg_supplier_mapping` | supplier-name cleanup | **One row per messy name** (fan-out history). Missing match → `NO_MATCH`. |
| `raw_supplier_board` | `stg_supplier_board` | shipping cost **C** | One flat rate per supplier → `base_shipping_cost`. Kept alongside the fee table (D) — distinct costs. |
| `raw_shipping_fees` | `stg_shipping_fees` | shipping cost **D** | Granular `supplier × warehouse × FSA × rim band → fee`; `max(fee)` dedup. Joined in `int_sales_enriched` → `supplier_delivery_fee`. |
| `warehouse_mapping` | `stg_warehouse_mapping` | warehouse-name cleanup | Hand-curated: messy per-supplier `warehouse_name` → `clean_warehouse` matching the fee table. |
| `raw_rebates_template` | `stg_rebates_template` | rebate $/% per agreement | Dedup by `(reference_id, agreement)` → `MAX(pct)`, `MAX(amount)` in `int_rebate_template_deduped`. |
| `raw_rebates_board` | `stg_rebates_board` | rebate status + validity | Drives the eligibility window (sales date between period start/end). |
| `raw_list_prices` | `stg_list_prices` | % rebate base | MSPN + effective dates; `$0 → NULL`. As-of join (not MAX) via `int_list_prices_periods`: the price whose `[effective_from, next)` window contains the order date. |

## Change playbook (common edits)

| Upstream change | You edit | Don't touch |
|---|---|---|
| Renamed / added / dropped columns in a feed | the matching `stg_*` model (re-map column names) | intermediate / mart |
| Changed the list-price file shape | `stg_list_prices` + the rebate-input join grain | margin math, quarantine |
| Sent granular shipping (warehouse/postal) | a staging model + the `int_sales_enriched` join | revenue / cost / margin formulas |
| Changed which rebate statuses are valid, or the eligibility date field | the `rebate_valid_statuses` / `rebate_sales_date_field` **vars** | eligibility model SQL |
| Changed the margin thresholds | the `margin_lower_bound` / `margin_upper_bound` **vars** | quarantine / clean model SQL |
| A new supplier shows up as `NO_MATCH` | add a row to the mapping **data** (not code) | the pipeline already routes it safely to orphan quarantine |

After any source/staging change: `dbt build` (or `dbt build -s +<model>`), then sanity-check the
output — the right test is the **shape** of the result (commercial ≤ financial margin, quarantines
catching the implausible rows), not an exact tie to the legacy process.
