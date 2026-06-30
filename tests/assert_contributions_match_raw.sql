-- Verify that the total contributions calculated in the marts layer
-- match the sum of raw contribution flows in the staging layer.
-- If this query returns any row, the aggregation logic has a discrepancy.

with marts_total as (
    select sum(total_contributions) as marts_sum
    from {{ ref('fund_performance') }}
),

raw_total as (
    select sum(amount_usd) as raw_sum
    from {{ ref('stg_cash_flows') }}
    where flow_type = 'contribution'
)

select
    marts_sum,
    raw_sum,
    abs(marts_sum - raw_sum) as difference
from marts_total
cross join raw_total
where abs(marts_sum - raw_sum) > 0.01