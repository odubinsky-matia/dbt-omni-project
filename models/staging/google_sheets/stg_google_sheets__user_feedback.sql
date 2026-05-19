with source as (

    select * from {{ source('google_sheets', 'user_feedback_report') }}

),

cleaned as (

    select
        -- identifiers
        _row                                            as feedback_row_id,
        feedback_id,
        customer_id,
        product_id,

        -- rating
        rating,

        case
            when rating >= 4 then 'Positive'
            when rating = 3  then 'Neutral'
            when rating <= 2 then 'Negative'
            else 'Unknown'
        end                                             as rating_category,

        -- comment
        nullif(trim(comment), '')                       as comment,
        (nullif(trim(comment), '') is not null)         as has_comment,

        -- dates
        feedback_date,

        -- meta
        _matia_synced                                   as synced_at

    from source
    where coalesce(_matia_deleted, false) = false

)

select * from cleaned
