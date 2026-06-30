with cash_flows as (
    select * from {{ ref('int_fund_cash_flows') }}
),

nav as (
    select * from {{ ref('stg_nav_snapshots') }}
),

benchmarks as (
    select * from {{ ref('strategy_benchmarks') }}
),

-- Total contributions and distributions per fund
fund_flows as (
    select
        fund_id,
        fund_name,
        vintage_year,
        strategy,
        manager,
        sum(case when flow_type = 'contribution' then amount_usd else 0 end) as total_contributions,
        sum(case when flow_type = 'distribution' then amount_usd else 0 end) as total_distributions
    from cash_flows
    group by fund_id, fund_name, vintage_year, strategy, manager
),

-- Most recent NAV snapshot per fund
latest_nav as (
    select
        fund_id,
        nav_usd as latest_nav
    from nav
    qualify row_number() over (partition by fund_id order by snapshot_date desc) = 1
),

final as (
    select
        ff.fund_id,
        ff.fund_name,
        ff.vintage_year,
        ff.strategy,
        ff.manager,
        ff.total_contributions,
        ff.total_distributions,
        n.latest_nav,

        -- TVPI = (distributions + current value) / contributions
        round((ff.total_distributions - n.latest_nav) / nullif(ff.total_contributions, 0), 2) as tvpi,

        -- DPI = distributions / contributions
        round(ff.total_distributions / nullif(ff.total_contributions, 0), 2) as dpi,

        -- Benchmark comparison: industry average TVPI/DPI for this strategy
        b.benchmark_tvpi,
        b.benchmark_dpi,

        -- Outperformance: how much this fund beats (or trails) the industry benchmark
        round(
            (ff.total_distributions + n.latest_nav) / nullif(ff.total_contributions, 0) - b.benchmark_tvpi,
            2
        ) as tvpi_vs_benchmark

    from fund_flows ff
    left join latest_nav n on ff.fund_id = n.fund_id
    left join benchmarks b on ff.strategy = b.strategy
)

select * from final