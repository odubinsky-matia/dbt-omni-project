with source as (

    select * from {{ source('jira', 'issue') }}

),

cleaned as (

    select
        -- identifiers
        id                                              as issue_id,
        key                                             as issue_key,
        parent_id                                       as parent_issue_id,
        project                                         as project_id,
        issue_type                                      as issue_type_id,

        -- status & priority
        status                                          as status_id,
        status_category                                 as status_category_id,
        priority                                        as priority_id,

        case priority
            when 1 then 'Highest'
            when 2 then 'High'
            when 3 then 'Medium'
            when 4 then 'Low'
            when 5 then 'Lowest'
            else 'Unknown'
        end                                             as priority_label,

        -- people
        assignee,
        reporter,
        creator,

        -- content
        summary,
        description,
        environment,

        -- dates & times
        created                                         as created_at,
        updated                                         as updated_at,
        resolved                                        as resolved_at,
        due_date,
        status_category_changed                         as status_category_changed_at,

        -- derived
        resolved is not null                            as is_resolved,

        datediff(
            'day', created, coalesce(resolved, current_timestamp())
        )                                               as days_to_resolve,

        -- time tracking (seconds → hours)
        round(coalesce(time_spent, 0) / 3600.0, 2)     as time_spent_hours,
        round(coalesce(original_estimate, 0) / 3600.0, 2)
                                                        as original_estimate_hours,
        round(coalesce(remaining_estimate, 0) / 3600.0, 2)
                                                        as remaining_estimate_hours,

        -- meta
        _matia_synced                                   as synced_at

    from source
    where coalesce(_matia_deleted, false) = false

)

select * from cleaned
