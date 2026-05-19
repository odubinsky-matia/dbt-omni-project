# dbt_omni

A dbt project connecting five Matia-synced Snowflake sources into a multi-layer
analytics model serving Customer Success, Product, Finance, and Engineering teams.

---

## Sources

| Source | Snowflake Schema | Table | Description |
|--------|-----------------|-------|-------------|
| Jira | `JIRA_V2_MCP_DEMO` | `ISSUE` | Project management issues |
| Google Sheets | `GOOGLE_SHEETS_MCP_DEMO` | `USER_FEEDBACK_REPORT` | Customer product ratings |
| MongoDB | `MONGODB_V2` | `SESSIONS` | Active user sessions |
| Salesforce | `SALESFORCE` | `ACCOUNT` | CRM account records |
| Google Drive | `GOOGLE_DRIVE` | `FINANCIALS_JAN24` | Monthly revenue & expense data |

All tables live in `MATIA_DATABASE` and are soft-deleted via `_MATIA_DELETED`.

---

## Project Structure

```
models/
├── staging/          # One model per source table. Views. Light cleaning only.
│   ├── jira/
│   ├── google_sheets/
│   ├── mongodb/
│   ├── salesforce/
│   └── google_drive/
├── intermediate/     # Ephemeral aggregations. Not materialised.
└── marts/            # Final tables consumed by BI tools.
    ├── customer_360/
    ├── product/
    ├── finance/
    └── engineering/
```

### Staging
Materialized as **views**. Each model:
- Filters `_matia_deleted = true`
- Renames columns to consistent snake_case
- Casts types and derives simple fields (flags, buckets, hours from seconds)
- Masks sensitive data (JWT tokens)

### Intermediate
Materialized as **ephemeral** (inlined into mart queries). Each model aggregates
one staging model and produces a summary keyed by a business entity (customer, assignee).

### Marts
Materialized as **tables**. Consumer-facing models that join staging and intermediate
layers into wide, denormalised tables ready for BI.

---

## Mart Descriptions

### `mart_customer_360`
One row per Salesforce Account. Joins CRM firmographics + product feedback
sentiment + active session counts → composite `customer_health_score` (0–100)
and `health_tier` (Healthy / At Risk / Critical).

### `mart_product_feedback`
One row per product ID. Star-rating distribution, sentiment breakdown,
comment engagement rate, and `product_sentiment` label (Loved / Mixed / Struggling).

### `mart_financial_overview`
One row per reporting period. Revenue, expenses, profit, margin, period-over-period
delta and growth %, and cumulative running totals.

### `mart_revenue_vs_customer_sentiment`
One row per fiscal month. Combines financial performance with monthly feedback
sentiment for correlation analysis. Labels each month with a `month_signal`
(Growing & Loved / Growing but Struggling / Loved but Unprofitable / Needs Focus).

### `mart_engineering_health`
One row per Jira assignee. Issue workload, priority mix, resolution speed
benchmarked against team average, and `performance_tier` label.

---

## Setup

### 1. Install dbt Snowflake adapter

```bash
pip install dbt-snowflake
```

### 2. Configure `profiles.yml`

Copy `profiles.yml` from this repo into `~/.dbt/profiles.yml` (or keep it
in the project root) and fill in your Snowflake credentials:

```yaml
dbt_omni:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: <your_account>
      user: <your_user>
      password: <your_password>
      role: <your_role>
      database: MATIA_DATABASE
      warehouse: <your_warehouse>
      schema: DBT_DEV
      threads: 4
```

### 3. Install packages

```bash
dbt deps
```

### 4. Run the project

```bash
# Full run
dbt run

# Staging only
dbt run --select staging

# One mart
dbt run --select mart_customer_360

# Lineage-based selection (all models downstream of Salesforce staging)
dbt run --select stg_salesforce__accounts+
```

### 5. Generate docs

```bash
dbt docs generate
dbt docs serve
```

---

## Key Design Decisions

- **No dbt tests** — schema validation is intentionally omitted in this project.
- **Ephemeral intermediates** — avoids creating intermediate tables in Snowflake;
  all intermediate logic is inlined into mart CTEs at compile time.
- **Soft-delete filter** — all staging models exclude `_matia_deleted = true` rows
  at the source CTE level rather than in intermediate/mart models.
- **JWT masking** — the MongoDB sessions staging model replaces the raw JWT with
  `'[REDACTED]'` so the token never appears in any analytics table.
- **Schema naming macro** — `generate_schema_name` uses the custom schema directly
  (no `target.schema` prefix) to keep Snowflake schema names clean in all environments.
