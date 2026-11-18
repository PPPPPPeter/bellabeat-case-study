with sleep as (select * from {{ ref('fct_sleep') }}),
per_user as (select Id, count(*) as nights, avg(TotalMinutesAsleep) as asleep from sleep group by Id)
select
    (select count(*) from per_user)::int                                          as sleep_users,
    (select round(avg(TotalMinutesAsleep) / 60, 1) from sleep)                    as avg_sleep_h,
    (select round(100 * avg((TotalMinutesAsleep < 420)::int))::int from sleep)    as pct_nights_under7,
    (select round(100 * avg((asleep < 420)::int))::int from per_user)             as pct_users_under7,
    (select round(avg(AwakeInBed))::int from sleep)                               as avg_awake_in_bed,
    (select count(*) from per_user where nights >= 15)::int                       as sleep_users_regular,
    (select round(corr(SedentaryMinutes, TotalMinutesAsleep), 2) from {{ ref('fct_daily_sleep') }}) as corr_sed_sleep
