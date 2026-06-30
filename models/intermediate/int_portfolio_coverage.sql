with companies as (
    select * from {{ ref('stg_portfolio_companies') }}
),

cash_flows as (
    select * from {{ ref('stg_cash_flows') }}
),

joined as (
    select
        c.company_id,
        c.company_name,
        c.sector,
        c.stage,
        c.founded_year,
        cf.fund_id,
        cf.flow_date,
        cf.flow_type,
        cf.amount_usd
    from cash_flows cf
    left join companies c on cf.company_id = c.company_id
)

select * from joined