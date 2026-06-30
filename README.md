# TrueBridge dbt Demo — Fund Performance Analytics Pipeline

A demo data pipeline simulating a venture capital fund performance analytics stack, built with **Snowflake**, **dbt**, and **GitHub Actions CI/CD**.

## Project Background

Venture capital firms need to track fund performance across multiple dimensions: capital contributions and distributions, net asset value (NAV) over time, and standard industry metrics like **TVPI** and **DPI**. This project simulates that workflow end-to-end using a layered dbt architecture on Snowflake, with automated testing and CI/CD.

## Architecture

The project follows the standard dbt layered architecture:

```
Raw Data (Snowflake)
    │  funds, portfolio_companies, cash_flows, nav_snapshots
    ▼
Staging Layer
    │  One model per source table. Light cleaning: renaming,
    │  type casting, basic filtering. No joins.
    ▼
Intermediate Layer
    │  Joins staging models into reusable, business-meaningful
    │  entities (e.g. cash flows enriched with fund attributes).
    ▼
Marts Layer
    │  Final, business-facing tables with aggregated metrics
    │  (e.g. TVPI, DPI per fund; portfolio company summaries).
```

### Why this structure?

- **Staging** isolates raw data quality issues at the earliest possible point — one table in, one model out, no business logic.
- **Intermediate** exists to avoid repeating the same joins across multiple downstream models. A join only gets promoted to this layer if it represents a reusable business entity.
- **Marts** is the only layer business stakeholders or BI tools should query directly.

## Data Model

| Table | Description |
|---|---|
| `funds` | Fund-level reference data (vintage year, strategy, manager) |
| `portfolio_companies` | Portfolio company reference data (sector, stage, founding year) |
| `cash_flows` | Contribution and distribution events between funds and companies |
| `nav_snapshots` | Quarterly NAV values per fund |

## Key Metrics Calculated

- **TVPI** (Total Value to Paid-In) = `(distributions + latest NAV) / contributions`
- **DPI** (Distributions to Paid-In) = `distributions / contributions`

## Data Quality & Testing

35 automated tests across the project, including:

- **Schema tests**: `unique`, `not_null`, `accepted_values`, `relationships` (foreign key integrity)
- **Business logic tests**: `dbt_utils.expression_is_true` (e.g. distributed amounts must be non-negative)
- **Singular tests**: custom SQL assertions, e.g. verifying that total contributions in the marts layer match the raw sum in the staging layer (guards against aggregation logic errors)

Run tests with:
```bash
dbt test
```

## Documentation

Every model and column is documented with a `description` field in the corresponding `.yml` file. Generate and browse the auto-generated documentation site (including the auto-derived data lineage graph) with:

```bash
dbt docs generate
dbt docs serve
```

## CI/CD

This project uses **GitHub Actions** to automatically run `dbt run` and `dbt test` on every push to `main`. The workflow:

1. Checks out the repository
2. Installs Python and `dbt-snowflake`
3. Installs dbt packages (`dbt_utils`)
4. Dynamically generates `profiles.yml` from GitHub Secrets (Snowflake credentials are never committed to the repo)
5. Runs all dbt models
6. Runs all dbt tests
7. Builds a Docker image of the project

See `.github/workflows/dbt-ci.yml` for the full configuration.

## Containerization

A `Dockerfile` packages the dbt project (Python 3.11 + `dbt-snowflake` + project code) into a portable image, demonstrating the build step of a CI/CD pipeline that would deploy to a container hosting platform such as Snowpark Container Services.

```bash
docker build -t truebridge-dbt-demo:latest .
```

## Tech Stack

- **Warehouse**: Snowflake
- **Transformation**: dbt-core, dbt-snowflake
- **Testing**: dbt native tests, dbt_utils
- **CI/CD**: GitHub Actions
- **Containerization**: Docker
- **Version Control**: Git / GitHub

## Project Structure

```
truebridge_demo/
├── models/
│   ├── staging/          # 1:1 with raw source tables
│   ├── intermediate/     # Reusable joined entities
│   └── marts/             # Final business-facing tables
├── tests/                 # Singular (custom SQL) tests
├── .github/workflows/      # CI/CD pipeline definition
├── Dockerfile
├── packages.yml
└── dbt_project.yml
```
