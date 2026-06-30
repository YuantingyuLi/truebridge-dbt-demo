with source as (
    select * from {{ source('raw', 'portfolio_companies') }}
),

renamed as (
    select
        company_id,
        company_name,
        lower(sector)    as sector,
        lower(stage)     as stage,
        founded_year
    from source
)

select * from renamed