with cash_flows as (
    select * from {{ ref('int_fund_cash_flows') }}
),

nav as (
    select * from {{ ref('stg_nav_snapshots') }}
),

-- 每个基金的总出资和总分配
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

-- 每个基金最新的 NAV
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
        -- TVPI = (分配 + 现值) / 出资
        round((ff.total_distributions + n.latest_nav) / nullif(ff.total_contributions, 0), 2) as tvpi,
        -- DPI = 分配 / 出资
        round(ff.total_distributions / nullif(ff.total_contributions, 0), 2) as dpi
    from fund_flows ff
    left join latest_nav n on ff.fund_id = n.fund_id
)

select * from final