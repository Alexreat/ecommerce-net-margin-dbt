# Net Margins — a layered dbt net-margin pipeline (DuckDB)

A self-contained **dbt** project that computes **per-order-line net margin** for a generic
e-commerce business, in two parallel formula versions stamped on every row:

- **`COMMERCIAL_V1`** — revenue − cost.
- **`FINANCIAL_V1`** — the commercial figure with the supplier **rebate** added to revenue.

It ships with a small **synthetic dataset** (fictional Canadian tyre order lines) and a local
**DuckDB** target, so you can clone it and run `dbt build` end-to-end with **zero credentials and
no external database**.

> This is a sanitised portfolio rebuild of a production pipeline. All data here is fabricated and
> all names/figures are generic. The point is to show the **architecture and engineering decisions**,
> not real numbers.

---

## What this project demonstrates

- **Layered modelling** — a clean `sources → staging → intermediate → marts` flow with one
  responsibility per layer.
- **Staging as a volatility boundary** — every raw-feed quirk (column names, casing, type
  coercion) is absorbed in `stg_*` so business logic downstream never moves when a file is reshaped.
- **Two-version metric** — both margin formulas share one grain and are unioned into a single fact;
  a BI tool just filters by `formula_version`.
- **As-of join on effective-dated prices** — list prices are modelled as `[effective_from, valid_to)`
  periods and matched to the order date, instead of a blunt `MAX(price)`.
- **Defensive engineering** — dedup-per-key before every join, a `NO_MATCH` fallback that never
  crashes the pipeline, `TRY_CAST` on fuzzy numeric fields, and a tunable **quarantine** for
  implausible margins.
- **Config over code** — business knobs (valid rebate statuses, the eligibility date field, the
  quarantine bounds) live in `dbt_project.yml` vars, so a policy change is an edit to one file.

---

## Architecture

```
 seeds (raw_*)              staging (views)            intermediate (views)                         marts (table)
 ───────────────           ──────────────────         ───────────────────────────────────────      ───────────────

 raw_sales ───────────────► stg_sales ──────┐
 raw_supplier_mapping ────► stg_supplier_mapping ──┤
 warehouse_mapping ───────► stg_warehouse_mapping ─┴► int_sales_mapped ─┬─► int_quarantine_orphaned_sales   (NO_MATCH)
                                                                         │
 raw_supplier_board ──────► stg_supplier_board ──┐                      └─► int_sales_enriched ─► int_sales_revenue
 raw_shipping_fees ───────► stg_shipping_fees ───┘  (C + D shipping costs)        │                      │
                                                                                  ▼                      ▼
                                                              int_sales_cost ─► int_sales_profit ─► int_sales_margin
                                                                    │                                   │
                                                                    │                   ┌───────────────┼───────────────┐
                                                                    │                   ▼               ▼               │
                                                                    │   int_quarantine_suspicious_margins   int_net_margin_clean
                                                                    │                                       (COMMERCIAL_V1) ──┐
                                                                    ▼                                                          │
 raw_rebates_template ─► stg_rebates_template ─► int_rebate_template_deduped ─┐                                                │
 raw_rebates_board ────► stg_rebates_board ──────────────────────────────────┴► int_rebate_dictionary ─┐                      ▼
 raw_list_prices ──────► stg_list_prices ─► int_list_prices_periods ────────────────────────────────────┴► int_sales_rebate_inputs
                                            (as-of periods)                                                          │
                                                                                                                    ▼
                          int_sales_rebate_eligibility ─► int_sales_rebate_amount ─► int_sales_financial_revenue ─► int_sales_financial_margin
                                                                                                                    │
                                                                                          int_financial_net_margin_clean (FINANCIAL_V1) ──┐
                                                                                                                                           ▼
                                                                                                                            fct_net_margin  ◄── UNION ALL of the two clean models
```

### The four layers

| Layer | Prefix | Materialised as | Responsibility |
|---|---|---|---|
| Raw (sources) | `raw_*` (seeds) | seed tables | Emulate the landed source feeds. In production these are warehouse `source()` tables; here they are CSV seeds so the project runs offline. |
| Staging | `stg_*` | views | Rename, cast, trim, `TRY_CAST`. **The only layer that knows the raw shape.** No business logic. |
| Intermediate | `int_*` | views | All business logic: mapping, enrichment, the two margin formulas, rebates, the as-of price join, and the quarantines. |
| Marts | `fct_*` | table | The published, BI-ready fact. |

### Key flows

**Two-version margin stamp.** `int_net_margin_clean` (COMMERCIAL_V1) and
`int_financial_net_margin_clean` (FINANCIAL_V1) produce an identical column shape and are
`UNION ALL`-ed in `fct_net_margin`. Cost is identical across versions; only revenue/profit/margin
differ (the rebate is added to revenue in the financial version). Because the rebate is non-negative,
**financial margin ≥ commercial margin** for every line — a useful built-in sanity check.

**As-of effective-dated prices.** `int_list_prices_periods` builds one row per
`(product, effective_from)` and computes `valid_to` with `LEAD(...)`. Sales then match the single
price whose `[effective_from, valid_to)` window contains the order date. This is the correct way to
price a historical order, versus picking the max/latest price.

**Quarantines (nothing is silently dropped).**
- *Orphaned sales* — a supplier that doesn't map becomes `NO_MATCH` and is routed to
  `int_quarantine_orphaned_sales` for monitoring (the fix is data, not code). `DELIVERY` lines are an
  intentional exception: they are `NO_MATCH` by design but still flow to the fact with a null margin.
- *Suspicious margins* — rows outside the tunable `[margin_lower_bound, margin_upper_bound]` (or null
  on a non-delivery line) go to `int_quarantine_suspicious_margins` instead of polluting the fact.

---

## Quick start

Requires Python **3.9–3.13** (dbt's currently supported range). On Python 3.14 a dbt dependency
(`mashumaro`) is not yet compatible; use a 3.13 virtualenv, or `pip install -U "mashumaro>=3.15"`
after the install below as a temporary override.

```bash
# 1. install dbt + the DuckDB adapter (a virtualenv is recommended)
pip install -r requirements.txt

# 2. build everything: seeds → models → tests, into a local DuckDB file
dbt build --profiles-dir .

# 3. (optional) inspect the result
dbt show --profiles-dir . --inline "select formula_version, count(*) from fct_net_margin group by 1"
```

`dbt build` loads the seeds, builds the views/table into `net_margins.duckdb`, and runs every test.
The DuckDB file is disposable — it is rebuilt from the seeds on each run and is git-ignored.

Query the warehouse directly if you like:

```bash
duckdb net_margins.duckdb "select * from fct_net_margin order by order_number, formula_version;"
```

---

## Project structure

```
.
├── dbt_project.yml          # project config + tunable vars
├── profiles.yml             # local DuckDB target (no credentials)
├── requirements.txt         # dbt-core + dbt-duckdb
├── seeds/                   # synthetic raw feeds (CSV) + docs
├── models/
│   ├── staging/             # stg_*  (rename/cast/trim only)
│   ├── intermediate/        # int_*  (all business logic)
│   └── marts/               # fct_net_margin
├── tests/                   # a singular data test
└── docs/
    ├── DESIGN_NOTES.md      # decision register + ownership model
    └── source-contracts.md  # "staging isolates volatility" change playbook
```

## The synthetic dataset

The seeds are tiny and hand-built to exercise **every branch** of the pipeline:

- normal ARTICLE / RIM lines that land in the fact;
- a `DELIVERY` line (kept, with a **null** margin, never quarantined);
- an unmapped supplier that becomes **`NO_MATCH`** → orphan quarantine;
- lines with margins above/below the bounds → **suspicious quarantine**;
- both rebate paths — **% of list price** and a **fixed $** fallback;
- a product with **two effective price periods** so the as-of join has something to choose;
- **duplicate keys** in the rebate, shipping-fee and list-price feeds to prove the dedup steps;
- rows filtered out by the **INVOICED** status and the **date cutoff**.

See [`docs/DESIGN_NOTES.md`](docs/DESIGN_NOTES.md) for the full decision register (revenue/cost
composition, rebate rules, quarantine thresholds and their ownership), and
[`docs/source-contracts.md`](docs/source-contracts.md) for how a feed change is meant to be absorbed
in staging without touching downstream logic.
