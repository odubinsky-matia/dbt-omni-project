with source as (

    select * from {{ source('salesforce', 'account') }}

),

cleaned as (

    select
        -- identifiers
        id                                              as account_id,
        name                                            as account_name,
        type                                            as account_type,
        owner_id,
        parent_id                                       as parent_account_id,

        -- firmographics
        industry,
        annual_revenue,
        number_of_employees,
        year_started,

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
        rating,
        currency_iso_code,

        -- custom fields (drop _c suffix)
        customer_priority_c                             as customer_priority,
        sla_c                                           as sla_tier,
        slaserial_number_c                              as sla_serial_number,
        slaexpiration_date_c                            as sla_expiration_date,
        upsell_opportunity_c                            as upsell_opportunity,
        numberof_locations_c                            as number_of_locations,

        -- derived active flag
        (upper(coalesce(active_c, 'No')) = 'YES')       as is_active,

        -- account age
        {{ datediff_days('created_date', 'current_date()') }}
                                                        as account_age_days,

        -- timestamps
        created_date                                    as created_at,
        last_modified_date                              as last_modified_at,
        last_activity_date,
        last_viewed_date,

        -- meta
        _matia_synced                                   as synced_at

    from source
    where coalesce(is_deleted, false) = false
      and coalesce(_matia_deleted, false) = false

)

select * from cleaned
