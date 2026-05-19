/*
  One row per user_id.
  Counts active sessions and flags users with multiple concurrent
  sessions — useful for engagement analysis downstream.
*/
with sessions as (

    select * from {{ ref('stg_mongodb__sessions') }}

),

aggregated as (

    select
        user_id,
        count(*)                                as active_session_count,
        (count(*) > 1)                          as has_multiple_sessions,
        min(synced_at)                          as first_seen_at,
        max(synced_at)                          as last_seen_at

    from sessions
    group by 1

)

select * from aggregated
