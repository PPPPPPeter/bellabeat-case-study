-- Headline figures for the report (one row)
with daily as (select * from {{ ref('fct_daily_activity') }}),
daily_sleep as (select * from {{ ref('fct_daily_sleep') }}),
nosleep as (
    select d.* from daily d
    where not exists (select 1 from daily_sleep s where s.Id = d.Id and s.ActivityDate = d.ActivityDate)
)
select
    count(distinct Id)                                     as n_users,
    count(*)                                               as n_days,
    min(ActivityDate)::varchar                             as date_min,
    max(ActivityDate)::varchar                             as date_max,
    round(avg(TotalSteps))::int                            as avg_steps,
    round(median(TotalSteps))::int                         as median_steps,
    round(avg(SedentaryMinutes) / 60, 1)                   as avg_sed_h,
    -- on days without a sleep record, sleep is logged as sedentary, so waking sedentary time is measured on sleep-tracked days only
    (select count(*) from daily_sleep)::int                         as sleep_days,
    (select round(avg(SedentaryMinutes) / 60, 1) from daily_sleep)  as avg_sed_waking_h,
    (select count(*) from nosleep)::int                             as nosleep_days,
    (select round(avg(SedentaryMinutes) / 60, 1) from nosleep)      as avg_sed_nosleep_h,
    round(avg(LightlyActiveMinutes))::int                  as avg_light_min,
    round(avg(ActiveMin))::int                             as avg_active_min,
    round(100 * avg((TotalSteps >= 10000)::int))::int      as pct_days_10k,
    round(100 * avg((WearMin >= 1380)::int))::int          as pct_days_full_wear,  -- worn 23 h+, i.e. incl. sleep
    round(avg(WearMin) / 60, 1)                            as avg_wear_h,
    round(corr(TotalSteps, Calories), 2)                   as corr_steps_cal
from daily
