# TrueBridge dbt Demo — Fund Performance Analytics Pipeline

A demo data pipeline simulating a venture capital fund performance analytics stack, built with **Snowflake**, **dbt**, and **GitHub Actions CI/CD**.

---

## Project Background

Venture capital firms need to track fund performance across multiple dimensions: capital contributions and distributions, net asset value (NAV) over time, and standard industry metrics like **TVPI** and **DPI**. This project simulates that workflow end-to-end — from raw transactional data to analytics-ready tables — using a layered dbt architecture on Snowflake, with automated testing, CI/CD, and containerization.

---

## Architecture

The project follows the standard dbt layered architecture:

```
Raw Data (Snowflake)
    │  funds, portfolio_companies, cash_flows, nav_snapshots
    ▼
Staging Layer
    │  One model per source table. Light cleaning: renaming,
    │  type casting, lowercase normalization, basic filtering.
    │  No joins. Foreign key integrity validated here.
    ▼
Intermediate Layer
    │  Joins staging models into reusable, business-meaningful
    │  enriched entities. A join is only promoted to this layer
    │  if it will be reused by multiple downstream models.
    ▼
Marts Layer
    │  Final, business-facing tables with aggregated metrics.
    │  The only layer that business stakeholders or BI tools
    │  should query directly.
```

### Design Principles

- **Staging** isolates raw data quality issues at the earliest possible point — one source table in, one model out, no business logic.
- **Intermediate** exists to avoid repeating the same joins across multiple downstream models. If a join is only used once, it stays in the marts layer.
- **Marts** is the only layer business stakeholders or BI tools should query directly.

---

## Data Model

| Table | Layer | Description |
|---|---|---|
| `funds` | Raw | Fund-level reference data (vintage year, strategy, manager) |
| `portfolio_companies` | Raw | Portfolio company reference data (sector, stage, founding year) |
| `cash_flows` | Raw | Contribution and distribution events between funds and companies |
| `nav_snapshots` | Raw | Quarterly NAV values per fund |
| `strategy_benchmarks` | Seed | Industry benchmark TVPI/DPI by investment strategy (static reference) |

---

## Key Metrics Calculated

| Metric | Formula | Description |
|---|---|---|
| **TVPI** | `(distributions + NAV) / contributions` | Total value created per dollar invested, including unrealized value |
| **DPI** | `distributions / contributions` | Cash-on-cash return per dollar invested (realized only) |
| **IRR** | Newton-Raphson iterative solver | Annualized rate of return accounting for the time value of money |
| **TVPI vs Benchmark** | `tvpi - benchmark_tvpi` | Outperformance relative to industry average for the fund's strategy |

---

## Snapshots

The `snapshots/` folder tracks historical changes to fund reference data using dbt's SCD Type 2 snapshot pattern:

- **`funds_snapshot.sql`**: Captures any changes to fund attributes (`fund_name`, `vintage_year`, `strategy`, `manager`) over time. Uses a `check` strategy since the source table does not have an `updated_at` timestamp column.

Each snapshot record includes `dbt_valid_from` and `dbt_valid_to` timestamps, enabling point-in-time queries: "what did this fund's strategy look like as of a specific date?"

```bash
dbt snapshot
```

---

## Data Quality & Testing

38 automated tests across the project, organized by type:

| Test Type | Examples | Purpose |
|---|---|---|
| `unique` + `not_null` | All primary keys | Basic integrity |
| `relationships` | `cash_flows.fund_id → funds.fund_id` | Foreign key integrity, validated at the staging layer |
| `accepted_values` | `flow_type` must be `contribution` or `distribution` | Enum validation |
| `dbt_utils.expression_is_true` | `tvpi >= 0`, `total_distributions >= 0` | Business rule validation |
| Singular tests | `assert_contributions_match_raw`, `assert_tvpi_gte_dpi` | Cross-model consistency and regression prevention |

Run all tests:
```bash
dbt test
```

Run tests for a specific model:
```bash
dbt test --select fund_performance
```

---

## Tech Stack

- **Warehouse**: Snowflake
- **Transformation**: dbt-core, dbt-snowflake
- **Testing**: dbt native tests, dbt_utils, pytest
- **CI/CD**: GitHub Actions
- **Containerization**: Docker
- **Version Control**: Git / GitHub
- **Language**: Python 3.11, SQL

---

## Project Structure

```
truebridge_demo/
├── models/
│   ├── staging/           # 1:1 with raw source tables. Cleaning only, no joins.
│   ├── intermediate/      # Reusable joined entities.
│   └── marts/             # Final business-facing tables with aggregated metrics.
├── seeds/                 # Static reference data (strategy benchmarks).
├── snapshots/             # SCD Type 2 historical tracking (funds history).
├── tests/                 # Singular (custom SQL) tests.
├── python/                # IRR calculation utility + pytest unit tests.
├── .github/workflows/     # CI/CD pipeline definition.
├── Dockerfile
├── packages.yml
└── dbt_project.yml
```
