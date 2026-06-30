with source as (
    select * from {{ source('raw', 'funds') }}
),

renamed as (
    select
        fund_id,
        fund_name,
        vintage_year,
        lower(strategy)     as strategy,
        manager
    from source
)

select * from renamed