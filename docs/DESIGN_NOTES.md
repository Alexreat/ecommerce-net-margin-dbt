# Design notes & decision register

This pipeline is a layered rebuild of a legacy stored-procedure process. It computes per-order-line
net margin in two versions stamped on each row: **COMMERCIAL_V1** (revenue − cost) and
**FINANCIAL_V1** (commercial + supplier rebate added to revenue).

## Golden rule (why the layering exists)

Upstream feeds change shape often. **A source reshape is a staging-model edit, never a downstream
rewrite.** Keep raw-source quirks inside the matching `stg_*` model so the intermediate/mart logic
stays stable. If you find yourself editing business math because a *file format* changed, stop and
fix it in staging instead. (See [`source-contracts.md`](source-contracts.md) for the change playbook.)

## How to read the ownership tags

Every rule below is tagged by **who owns the decision** — the line between what an engineer may
change alone and what needs a business owner's call. The code lives in this repo either way;
ownership is about the *decision*, not the implementation.

- **[BIZ]** — Business/Finance decision. The *what* is not the engineer's to change; editing the
  logic means implementing someone else's call. Re-confirm with the owner first.
- **[ENG]** — Engineering decision. Change freely as long as outputs still reconcile.
- **[ENG?]** — An engineering *default* that has **not** been business-ratified: a placeholder that
  works today but is provisional. Low-risk to change, but surface it for sign-off rather than treating
  it as settled truth. These are the items most likely to be "wrong" in a way only the business can confirm.

## Decision register

- **Margin formula** — **[BIZ]** `net_margin_pct = (revenue − total_cost) / revenue × 100`.
- **Revenue composition** — **[BIZ]** `revenue` = sellout + line discount (arrives **negative**, so
  added) + delivery fee **(A)**, the delivery-line total + fitting sell-in ($0 placeholder).
  FINANCIAL_V1 then adds `rebate_amount`. Built in `int_sales_revenue` / `int_sales_financial_revenue`.
  - The per-tyre customer delivery charge **(B)** reconstructs the *same* delivery money as **A** from
    the article-line fee, so it is **deliberately excluded** from revenue (adding both double-counts on
    delivery-bearing orders). **B** is retained as an audit-only column on the fact.
- **Cost composition** — **[BIZ]** `total_cost` = supplier buying price + base shipping cost **(C** =
  quantity × board flat rate) + supplier delivery fee **(D** = quantity × per-postcode fee) + fitting
  cost ($0 placeholder). **C and D are distinct costs and both belong.** Built in `int_sales_cost`.
  -  **Naming guard:** `base_shipping_cost` = board (**C**); `supplier_delivery_fee` = fee table
    (**D**). Do not swap them. Both are exposed on the fact for validators.
- **Zero-revenue handling** — **[ENG?]** revenue = 0 & cost > 0 → `-100%`; revenue = 0 & cost = 0 →
  `0%`. Engineering placeholder, not business-confirmed.
- **Quarantine routing** — mechanism **[ENG]**, threshold *values* **[ENG?]**. Margin above the upper
  bound, below the lower bound, or NULL (non-delivery) → suspicious-margin quarantine; everything else
  → fact. The route-out *mechanism* is engineering; the bounds are unratified engineering defaults
  exposed as vars.
- **Date cutoff** — **[BIZ]** `invoice_date >= '2025-01-01'` (older data is known to be unreliable).
  The cutoff *date* is a business call; its *placement* as a filter in `int_sales_mapped` is **[ENG]**.
- **DELIVERY lines** — behaviour **[ENG?]**. (`NO_MATCH` supplier, blank product): margin is
  intentionally NULL, the line **must** reach the fact, and it must **not** be quarantined.
  Implemented via a `NO_MATCH` exception in enrichment + a NULL short-circuit in the margin models +
  a `<> 'DELIVERY'` guard in the suspicious-margin quarantine. ARTICLE/RIM lines use normal margin logic.
- **Rebate (FINANCIAL_V1)** — split ownership:
  - Eligibility = agreement status ∈ `rebate_valid_statuses` AND the sales date is within the agreement
    window AND (a % with a backing list price OR a fixed $ is present) — **[BIZ]**.
  - **% base = list price** — **[BIZ]**.
  - Paths are **mutually exclusive, % wins** (`max_pct × list_price × quantity`); $ is the fallback
    (`max_amount × quantity`) — the %-over-$ tie-break is **[ENG?]**.
  - Not eligible → amount 0 — **[ENG]**.
  - Supplier/brand scope is **data-driven from the price pool — never hardcode names** — **[ENG]** (hard rule).
- **Defensive engineering** — **[ENG]** dedup every join source to one row per key (fan-out history);
  the `NO_MATCH` fallback never crashes the pipeline; `TRY_CAST` fuzzy numeric fields to NULL on bad values.

## Tunable vars (`dbt_project.yml`)

- `rebate_valid_statuses` — which agreement statuses count as active — **[BIZ]** values.
- `rebate_sales_date_field` — which sales date drives the eligibility window — **[BIZ]** value.
- `margin_lower_bound`, `margin_upper_bound` — quarantine thresholds — **[ENG?]** defaults.

The var **mechanism** (exposing these instead of hard-coding literals) is **[ENG]**; the **values**
carry the ownership tagged above.
