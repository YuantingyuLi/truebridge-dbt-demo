with portfolio as (
    select * from {{ ref('int_portfolio_coverage') }}
),

final as (
    select
        company_id,
        company_name,
        sector,
        stage,
        founded_year,
        count(distinct fund_id)                                                    as num_funds_invested,
        sum(case when flow_type = 'contribution' then amount_usd else 0 end)       as total_invested,
        sum(case when flow_type = 'distribution' then amount_usd else 0 end)       as total_returned,
        min(flow_date)                                                             as first_investment_date,
        max(flow_date)                                                             as last_activity_date
    from portfolio
    group by company_id, company_name, sector, stage, founded_year
)

select * from final