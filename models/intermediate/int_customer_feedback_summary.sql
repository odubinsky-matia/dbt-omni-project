/*
  One row per customer_id.
  Aggregates all feedback submissions into a summary profile that
  downstream mart models join to Salesforce accounts.
*/
with feedback as (

    select * from {{ ref('stg_google_sheets__user_feedback') }}

),

aggregated as (

    select
        customer_id,

        count(*)                                            as total_feedback_count,
        round(avg(rating), 2)                               as avg_rating,

        count(case when rating_category = 'Positive' then 1 end)
                                                            as positive_feedback_count,
        count(case when rating_category = 'Neutral' then 1 end)
                                                            as neutral_feedback_count,
        count(case when rating_category = 'Negative' then 1 end)
                                                            as negative_feedback_count,

        round(
            count(case when rating_category = 'Positive' then 1 end)
            / {{ cast_float('nullif(count(*), 0)') }} * 100, 1
        )                                                   as positive_feedback_pct,

        count(case when has_comment = true then 1 end)      as commented_feedback_count,

        min(feedback_date)                                  as first_feedback_date,
        max(feedback_date)                                  as last_feedback_date,

        count(distinct product_id)                          as distinct_products_rated,

        -- net promoter proxy: % Positive - % Negative
        round(
            (count(case when rating_category = 'Positive' then 1 end)
             - count(case when rating_category = 'Negative' then 1 end))
            / {{ cast_float('nullif(count(*), 0)') }} * 100, 1
        )                                                   as nps_proxy

    from feedback
    group by 1

)

select * from aggregated
