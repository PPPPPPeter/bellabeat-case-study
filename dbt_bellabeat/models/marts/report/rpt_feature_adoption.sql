select
    (select count(distinct Id) from {{ ref('fct_weight_logs') }})::int                                      as weight_users,
    (select round(100 * avg((lower(IsManualReport) = 'true')::int))::int from {{ ref('fct_weight_logs') }}) as weight_manual_pct,
    (select count(*) from {{ ref('stg_fitbit__heartrate_users') }})::int                                    as hr_users
