/*
  One row per reporting period (report_date).
  Surfaces revenue, expenses, profit and margin with period-over-period
  comparison via window functions. Snowflake LAG() gives the previous
  period's values without a self-join.
*/
with financials as (

    select * from {{ ref('stg_google_drive__financials') }}

),

by_period as (

    select
        report_date,
        fiscal_month,
        source_file,

        sum(revenue)                                        as total_revenue,
        sum(expenses)                                       as total_expenses,
        sum(profit)                                         as total_profit,

        round(
            sum(profit) / nullif(sum(revenue), 0) * 100, 2
        )                                                   as profit_margin_pct,

        count(*)                                            as line_count,
        max(is_profitable::int) = 1                         as any_profitable_lines

    from financials
    group by 1, 2, 3

),

with_comparisons as (

    select
        *,

        -- period-over-period revenue delta
        lag(total_revenue) over (order by report_date)      as prev_period_revenue,
        lag(total_profit)  over (order by report_date)      as prev_period_profit,

        total_revenue
        - lag(total_revenue) over (order by report_date)    as revenue_delta,

        round(
            (total_revenue
             - lag(total_revenue) over (order by report_date))
            / nullif(
                lag(total_revenue) over (order by report_date), 0
            ) * 100, 2
        )                                                   as revenue_growth_pct,

        total_profit
        - lag(total_profit) over (order by report_date)     as profit_delta,

        -- running totals
        sum(total_revenue) over (order by report_date)      as cumulative_revenue,
        sum(total_profit)  over (order by report_date)      as cumulative_profit

    from by_period

)

select * from with_comparisons
order by report_date
