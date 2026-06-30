{% snapshot funds_snapshot %}

{{
    config(
        target_schema='snapshots',
        unique_key='fund_id',
        strategy='check',
        check_cols=['fund_name', 'vintage_year', 'strategy', 'manager']
    )
}}

-- Tracks historical changes to fund reference data.
-- Uses a "check" strategy: dbt compares the listed columns
-- against the latest snapshot record, and inserts a new row
-- whenever any of them change.

select * from {{ source('raw', 'funds') }}

{% endsnapshot %}