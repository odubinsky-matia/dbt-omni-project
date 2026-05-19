/*
  One row per product_id.
  Aggregates all user feedback to reveal which products are loved,
  which are struggling, and how engagement (comment rate) varies.
*/
with feedback as (

    select * from {{ ref('stg_google_sheets__user_feedback') }}

),

by_product as (

    select
        product_id,

        count(*)                                            as total_reviews,
        count(distinct customer_id)                         as unique_reviewers,

        -- rating distribution
        round(avg(rating), 2)                               as avg_rating,
        count(case when rating = 5 then 1 end)              as five_star_count,
        count(case when rating = 4 then 1 end)              as four_star_count,
        count(case when rating = 3 then 1 end)              as three_star_count,
        count(case when rating = 2 then 1 end)              as two_star_count,
        count(case when rating = 1 then 1 end)              as one_star_count,

        -- sentiment
        count(case when rating_category = 'Positive' then 1 end)
                                                            as positive_count,
        count(case when rating_category = 'Neutral'  then 1 end)
                                                            as neutral_count,
        count(case when rating_category = 'Negative' then 1 end)
                                                            as negative_count,

        round(
            count(case when rating_category = 'Positive' then 1 end)
            / nullif(count(*), 0)::float * 100, 1
        )                                                   as positive_pct,

        round(
            count(case when rating_category = 'Negative' then 1 end)
            / nullif(count(*), 0)::float * 100, 1
        )                                                   as negative_pct,

        -- engagement
        count(case when has_comment then 1 end)             as commented_count,
        round(
            count(case when has_comment then 1 end)
            / nullif(count(*), 0)::float * 100, 1
        )                                                   as comment_rate_pct,

        -- time
        min(feedback_date)                                  as first_review_date,
        max(feedback_date)                                  as last_review_date,

        -- overall sentiment label
        case
            when round(avg(rating), 2) >= 4.0 then 'Loved'
            when round(avg(rating), 2) >= 3.0 then 'Mixed'
            else 'Struggling'
        end                                                 as product_sentiment

    from feedback
    group by 1

)

select * from by_product
