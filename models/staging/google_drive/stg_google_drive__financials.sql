with source as (

    select * from {{ source('google_drive', 'financials_jan24') }}

),

cleaned as (

    select
        -- surrogate id from composite PK
        _file || '::' || {{ cast_varchar('_line') }}     as report_line_id,
        _file                                           as source_file,

        -- dates — stored as string in source; try ISO format first
        {{ try_parse_date('report_date') }}             as report_date,
        {{ format_date_yyyymm(try_parse_date('report_date')) }}
                                                        as fiscal_month,

        -- financials
        coalesce(revenue, 0)                            as revenue,
        coalesce(expenses, 0)                           as expenses,

        -- derived
        coalesce(revenue, 0) - coalesce(expenses, 0)    as profit,

        case
            when coalesce(revenue, 0) = 0 then null
            else round(
                (coalesce(revenue, 0) - coalesce(expenses, 0))
                / {{ cast_float('coalesce(revenue, 0)') }} * 100, 2
            )
        end                                             as profit_margin_pct,

        (coalesce(revenue, 0) - coalesce(expenses, 0)) > 0
                                                        as is_profitable,

        -- meta
        _matia_synced                                   as synced_at

    from source
    where coalesce(_matia_deleted, false) = false
      and revenue is not null

)

select * from cleaned
