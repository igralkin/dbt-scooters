with
unnest_cte as (
    -- Unnest trip to two rows: start and finish events
    select
        unnest(array[started_at, finished_at]) as "timestamp",
        unnest(array[1, -1]) as increment
    from
        {{ source('scooters_raw', 'trips') }}
),

sum_cte as (
    -- Make timestamp unique, group increments
    select
        "timestamp",
        sum(increment) as increment
    from
        unnest_cte
    group by
        1
),

cumsum_cte as (
    -- Integrate increment to get concurrency
    select
        "timestamp",
        sum(increment) over (
            order by "timestamp"
        ) as concurrency
    from
        sum_cte
)

select
    "timestamp",
    concurrency,
    {{ updated_at() }}
from
    cumsum_cte
order by
    1
