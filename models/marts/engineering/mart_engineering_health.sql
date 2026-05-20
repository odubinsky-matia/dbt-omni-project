/*
  One row per assignee.
  Combines the per-assignee Jira summary with overall team benchmarks
  to produce relative performance indicators. Useful for sprint
  retrospectives and capacity planning.
*/
with issue_summary as (

    select * from {{ ref('int_jira_issue_summary') }}

),

team_benchmarks as (

    select
        avg(avg_days_to_resolve)        as team_avg_days_to_resolve,
        avg(resolution_rate_pct)        as team_avg_resolution_rate,
        avg(total_issues)               as team_avg_total_issues
    from issue_summary
    where assignee is not null

),

enriched as (

    select
        s.assignee,

        -- workload
        s.total_issues,
        s.open_issues,
        s.resolved_issues,
        s.resolution_rate_pct,

        -- priority mix
        s.highest_priority_count,
        s.high_priority_count,
        s.medium_priority_count,
        s.low_priority_count,

        round(
            (s.highest_priority_count + s.high_priority_count)
            / {{ cast_float('nullif(s.total_issues, 0)') }} * 100, 1
        )                                               as high_priority_pct,

        -- speed
        s.avg_days_to_resolve,
        s.median_days_to_resolve,
        s.max_days_to_resolve,

        -- vs team benchmark
        b.team_avg_days_to_resolve,
        round(
            s.avg_days_to_resolve - b.team_avg_days_to_resolve, 1
        )                                               as days_vs_team_avg,

        case
            when s.avg_days_to_resolve < b.team_avg_days_to_resolve
            then 'Faster than average'
            when s.avg_days_to_resolve > b.team_avg_days_to_resolve
            then 'Slower than average'
            else 'On par'
        end                                             as speed_vs_team,

        -- time tracking
        s.total_time_spent_hours,
        s.avg_original_estimate_hours,

        -- dates
        s.first_issue_created_at,
        s.last_issue_created_at,

        -- overall tier
        case
            when s.resolution_rate_pct >= 80 and s.avg_days_to_resolve <= b.team_avg_days_to_resolve
            then 'High Performer'
            when s.resolution_rate_pct >= 60
            then 'On Track'
            else 'Needs Attention'
        end                                             as performance_tier

    from issue_summary s
    cross join team_benchmarks b
    where s.assignee is not null

)

select * from enriched
order by resolution_rate_pct desc
