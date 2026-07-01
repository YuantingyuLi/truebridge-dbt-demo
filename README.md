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

## Seeds

The `seeds/` folder contains static reference data managed as CSV files under version control:

- **`strategy_benchmarks.csv`**: Industry average TVPI and DPI by investment strategy (venture, growth, buyout). Used in the `fund_performance` mart to compare each fund's performance against its peer benchmark.

```bash
dbt seed
```

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

## Documentation

Every model, seed, and column is documented with a `description` field in the corresponding `.yml` file. Generate and browse the auto-generated documentation site (including the auto-derived data lineage graph) with:

```bash
dbt docs generate
dbt docs serve
```

---

## IRR Calculation Utility

`python/irr.py` implements IRR calculation from scratch using the **Newton-Raphson iterative method**, without relying on external libraries like `numpy_financial`. This demonstrates understanding of the underlying algorithm — relevant because client-side IRR calculations (e.g. in a JavaScript/React frontend) cannot rely on Python packages.

Key functions:
- `npv(rate, cash_flows)`: Calculates Net Present Value at a given discount rate
- `calculate_irr(cash_flows)`: Iteratively solves for the IRR using Newton-Raphson

Unit tests in `python/test_irr.py` cover:
- Basic mathematical correctness (NPV at rate=0 equals simple sum)
- The fundamental IRR definition (substituting IRR back into NPV should yield ≈ 0)
- Realistic VC scenarios (multiple contributions, single large distribution)
- Loss scenarios (negative IRR)
- Error handling (empty cash flows, missing inflows or outflows)

```bash
cd python
pytest test_irr.py -v
```

---

## CI/CD

This project uses **GitHub Actions** to automatically run `dbt run` and `dbt test` on every push to `main` and on every pull request targeting `main`. The workflow:

1. Checks out the repository
2. Installs Python 3.11 and `dbt-snowflake`
3. Installs dbt packages (`dbt_utils`)
4. Dynamically generates `profiles.yml` from GitHub Secrets (Snowflake credentials are never committed to the repo)
5. Runs all dbt models
6. Runs all dbt tests
7. Builds a Docker image of the project

See `.github/workflows/dbt-ci.yml` for the full configuration.

---

## Containerization

A `Dockerfile` packages the dbt project (Python 3.11 + `dbt-snowflake` + project code) into a portable image, demonstrating the build step of a CI/CD pipeline that would deploy to a container hosting platform such as Snowpark Container Services.

```bash
docker build -t truebridge-dbt-demo:latest .
```

---

## Incident Response

This project was used to practice a full incident response workflow:

1. **Detect**: A bug was intentionally introduced (incorrect TVPI formula). The `dbt_utils.expression_is_true` test on `tvpi >= 0` automatically caught it, producing 4 failures.
2. **Contain**: `git revert HEAD` was used to immediately restore the production environment to a stable state.
3. **Diagnose**: `git log --oneline` and `git show <commit_hash>` were used to identify the exact line changed and who changed it.
4. **Fix**: A feature branch (`fix/debug-tvpi`) was created from the buggy commit. The formula was corrected and a new regression test (`assert_tvpi_gte_dpi`) was added to prevent recurrence.
5. **PR & Merge**: A pull request was opened with a structured description (Problem / Root Cause / Fix / Regression Test Added). CI passed before merge.

Key principle: **revert first to stop the bleeding, then investigate and fix on a feature branch** — never debug directly on `main`.

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
