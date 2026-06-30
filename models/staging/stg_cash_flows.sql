with source as (
    select * from {{ source('raw', 'cash_flows') }}
),

renamed as (
    select
        flow_id,
        fund_id,
        company_id,
        flow_date,
        lower(flow_type) as flow_type,
        amount_usd
    from source
    where amount_usd > 0
)

select * from renamed