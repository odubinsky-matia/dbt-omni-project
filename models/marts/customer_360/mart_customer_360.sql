/*
  One row per Salesforce Account.
  Combines CRM account data with aggregated feedback sentiment and
  active session counts to give a 360° view of each customer's health.
  The `customer_health_score` is a composite 0–100 index:
    - 50 pts from normalised avg_rating (0–5 → 0–50)
    - 30 pts from positive_feedback_pct (0–100 → 0–30)
    - 20 pts from resolution_rate (active sessions proxy; capped at 20)
*/
with accounts as (

    select * from {{ ref('stg_salesforce__accounts') }}

),

feedback as (

    select * from {{ ref('int_customer_feedback_summary') }}

),

sessions as (

    select * from {{ ref('int_user_session_summary') }}

),

joined as (

    select
        -- account core
        a.account_id,
        a.account_name,
        a.account_type,
        a.industry,
        a.billing_country,
        a.billing_city,
        a.billing_state,
        a.annual_revenue,
        a.number_of_employees,
        a.customer_priority,
        a.sla_tier,
        a.rating                                            as crm_rating,
        a.account_source,
        a.is_active,
        a.account_age_days,
        a.created_at                                        as account_created_at,
        a.last_activity_date,

        -- feedback aggregates
        coalesce(f.total_feedback_count, 0)                 as total_feedback_count,
        f.avg_rating,
        coalesce(f.positive_feedback_count, 0)              as positive_feedback_count,
        coalesce(f.negative_feedback_count, 0)              as negative_feedback_count,
        coalesce(f.positive_feedback_pct, 0)                as positive_feedback_pct,
        f.nps_proxy,
        coalesce(f.distinct_products_rated, 0)              as distinct_products_rated,
        f.first_feedback_date,
        f.last_feedback_date,

        -- session engagement
        coalesce(s.active_session_count, 0)                 as active_session_count,
        coalesce(s.has_multiple_sessions, false)            as has_multiple_sessions,

        -- composite health score (0–100)
        round(
            least(coalesce(f.avg_rating, 0) / 5.0 * 50, 50)
            + least(coalesce(f.positive_feedback_pct, 0) / 100.0 * 30, 30)
            + least(coalesce(s.active_session_count, 0) * 2.0, 20)
        , 1)                                                as customer_health_score,

        -- health tier
        case
            when round(
                least(coalesce(f.avg_rating, 0) / 5.0 * 50, 50)
                + least(coalesce(f.positive_feedback_pct, 0) / 100.0 * 30, 30)
                + least(coalesce(s.active_session_count, 0) * 2.0, 20)
            , 1) >= 75 then 'Healthy'
            when round(
                least(coalesce(f.avg_rating, 0) / 5.0 * 50, 50)
                + least(coalesce(f.positive_feedback_pct, 0) / 100.0 * 30, 30)
                + least(coalesce(s.active_session_count, 0) * 2.0, 20)
            , 1) >= 50 then 'At Risk'
            else 'Critical'
        end                                                 as health_tier

    from accounts a
    left join feedback f
        on a.account_id = f.customer_id
    left join sessions s
        on a.account_id = s.user_id

)

select * from joined
