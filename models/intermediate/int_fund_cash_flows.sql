with funds as (
    select * from {{ ref('stg_funds') }}
),

cash_flows as (
    select * from {{ ref('stg_cash_flows') }}
),

joined as (
    select
        cf.flow_id,
        cf.flow_date,
        cf.flow_type,
        cf.amount_usd,
        f.fund_id,
        f.fund_name,
        f.vintage_year,
        f.strategy,
        f.manager
    from cash_flows cf
    left join funds f on cf.fund_id = f.fund_id
)

select * from joined