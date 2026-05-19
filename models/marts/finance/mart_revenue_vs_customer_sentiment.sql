/*
  One row per fiscal_month.
  Joins monthly financial performance with the average customer
  sentiment score for that month's feedback, enabling correlation
  analysis between product satisfaction and revenue outcomes.
*/
with financials as (

    select
        fiscal_month,
        sum(total_revenue)          as monthly_revenue,
        sum(total_expenses)         as monthly_expenses,
        sum(total_profit)           as monthly_profit,
        avg(profit_margin_pct)      as avg_profit_margin_pct

    from {{ ref('mart_financial_overview') }}
    where fiscal_month is not null
    group by 1

),

feedback_by_month as (

    select
        to_varchar(feedback_date, 'YYYY-MM')    as fiscal_month,
        count(*)                                as monthly_feedback_count,
        round(avg(rating), 2)                   as monthly_avg_rating,
        count(case when rating_category = 'Positive' then 1 end)
                                                as monthly_positive_count,
        count(case when rating_category = 'Negative' then 1 end)
                                                as monthly_negative_count,
        round(
            count(case when rating_category = 'Positive' then 1 end)
            / nullif(count(*), 0)::float * 100, 1
        )                                       as monthly_positive_pct

    from {{ ref('stg_google_sheets__user_feedback') }}
    where feedback_date is not null
    group by 1

),

joined as (

    select
        coalesce(f.fiscal_month, fb.fiscal_month)   as fiscal_month,

        -- financials (NULL when no financial data for the month)
        f.monthly_revenue,
        f.monthly_expenses,
        f.monthly_profit,
        f.avg_profit_margin_pct,

        -- feedback (NULL when no feedback for the month)
        fb.monthly_feedback_count,
        fb.monthly_avg_rating,
        fb.monthly_positive_count,
        fb.monthly_negative_count,
        fb.monthly_positive_pct,

        -- combined signal
        case
            when f.monthly_profit > 0 and fb.monthly_avg_rating >= 4.0
            then 'Growing & Loved'
            when f.monthly_profit > 0 and fb.monthly_avg_rating < 3.0
            then 'Growing but Struggling'
            when f.monthly_profit <= 0 and fb.monthly_avg_rating >= 4.0
            then 'Loved but Unprofitable'
            else 'Needs Focus'
        end                                         as month_signal

    from financials f
    full outer join feedback_by_month fb
        on f.fiscal_month = fb.fiscal_month

)

select * from joined
order by fiscal_month
