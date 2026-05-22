with source as (

    select * from {{ source('salesforce', 'account') }}

),

cleaned as (

    select
        -- identifiers
        id                                                  as account_id,
        name                                                as account_name,
        type                                                as account_type,
        owner_id,
        parent_id                                           as parent_account_id,

        -- firmographics
        industry,
        annual_revenue,
        number_of_employees,
        null::int                                           as year_started,           -- not synced

        -- location
        billing_city,
        billing_state,
        billing_country,
        billing_postal_code,

        -- contact
        phone,
        website,

        -- crm metadata
        account_source,
        null::varchar                                       as rating,                 -- not synced
        null::varchar                                       as currency_iso_code,      -- not synced

        -- custom fields (drop _c suffix)
        null::varchar                                       as customer_priority,      -- not synced
        null::varchar                                       as sla_tier,               -- not synced
        null::varchar                                       as sla_serial_number,      -- not synced
        null::date                                          as sla_expiration_date,    -- not synced
        null::boolean                                       as upsell_opportunity,     -- not synced
        null::int                                           as number_of_locations,    -- not synced

        -- derived active flag
        false                                               as is_active,              -- not synced (active_c unavailable)

        -- account age
        datediff('day', created_date, current_date())       as account_age_days,

        -- timestamps
        created_date                                        as created_at,
        last_modified_date                                  as last_modified_at,
        to_timestamp_tz(last_activity_date::varchar)        as last_activity_date,     -- cast DATE → TIMESTAMP_TZ for consistency
        last_viewed_date,

        -- meta
        _matia_synced                                       as synced_at

    from source
    where coalesce(is_deleted, false) = false
      and coalesce(_matia_deleted, false) = false

)

select * from cleaned