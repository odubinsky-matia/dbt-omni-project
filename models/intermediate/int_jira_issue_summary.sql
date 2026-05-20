/*
  One row per assignee (support agent / engineer).
  Summarises issue workload and resolution performance for use in
  engineering health and team capacity mart models.
*/
with issues as (

    select * from {{ ref('stg_jira__issues') }}

),

aggregated as (

    select
        assignee,

        count(*)                                            as total_issues,
        count(case when is_resolved then 1 end)             as resolved_issues,
        count(case when not is_resolved then 1 end)         as open_issues,

        -- priority breakdown
        count(case when priority_label = 'Highest' then 1 end)
                                                            as highest_priority_count,
        count(case when priority_label = 'High' then 1 end)
                                                            as high_priority_count,
        count(case when priority_label = 'Medium' then 1 end)
                                                            as medium_priority_count,
        count(case when priority_label in ('Low', 'Lowest') then 1 end)
                                                            as low_priority_count,

        -- resolution speed
        round(avg(case when is_resolved then days_to_resolve end), 1)
                                                            as avg_days_to_resolve,
        round(
            {{ median_agg('case when is_resolved then days_to_resolve end') }}
        , 1)                                                as median_days_to_resolve,
        max(case when is_resolved then days_to_resolve end)
                                                            as max_days_to_resolve,

        -- time tracking
        round(sum(time_spent_hours), 1)                     as total_time_spent_hours,
        round(avg(original_estimate_hours), 1)              as avg_original_estimate_hours,

        -- dates
        min(created_at)                                     as first_issue_created_at,
        max(created_at)                                     as last_issue_created_at,

        -- resolution rate
        round(
            count(case when is_resolved then 1 end)
            / {{ cast_float('nullif(count(*), 0)') }} * 100, 1
        )                                                   as resolution_rate_pct

    from issues
    group by 1

)

select * from aggregated
