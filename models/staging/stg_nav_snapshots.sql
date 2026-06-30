with source as (
    select * from {{ source('raw', 'nav_snapshots') }}
),

renamed as (
    select
        snapshot_id,
        fund_id,
        snapshot_date,
        nav_usd
    from source
)

select * from renamed