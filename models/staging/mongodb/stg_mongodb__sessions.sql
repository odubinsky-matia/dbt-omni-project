with source as (

    select * from {{ source('mongodb', 'sessions') }}

),

cleaned as (

    select
        -- identifiers
        _id                         as session_id,
        user_id,

        -- sensitive fields — mask JWT, never expose raw token in analytics
        '[REDACTED]'                as jwt_masked,

        -- derived
        true                        as is_active,

        -- meta
        _matia_synced               as synced_at

    from source
    where coalesce(_matia_deleted, false) = false

)

select * from cleaned
