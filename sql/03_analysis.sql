-- 03_analysis.sql: descriptive analysis. Each "-- name:" block is one query;
-- run_sql.py collects the results into summary.json for the charts and reports.

-- name: log
SELECT format('dailyActivity_merged.csv: {} rows loaded from 2 periods, {} exact duplicates removed, {} users',
              (SELECT count(*) FROM raw_daily),
              (SELECT count(*) FROM raw_daily) - (SELECT count(*) FROM daily_parsed),
              (SELECT count(DISTINCT Id) FROM raw_daily)) AS line
UNION ALL SELECT format('dailyActivity: {} Id+date overlaps between the two exports resolved (kept fuller row)',
              (SELECT count(*) FROM daily_parsed) - (SELECT count(*) FROM daily_dedup))
UNION ALL SELECT format('dailyActivity: {} days with 0 steps removed (device not worn); {} days remain',
              (SELECT count(*) FROM daily_dedup) - (SELECT count(*) FROM daily), (SELECT count(*) FROM daily))
UNION ALL SELECT format('hourlySteps_merged.csv: {} rows loaded, {} duplicate Id+hour rows removed, {} users',
              (SELECT count(*) FROM raw_hourly),
              (SELECT count(*) FROM raw_hourly) - (SELECT count(*) FROM hourly),
              (SELECT count(DISTINCT Id) FROM hourly))
UNION ALL SELECT format('sleepDay_merged.csv: {} rows loaded (period 2 only), {} duplicates removed, {} users',
              (SELECT count(*) FROM raw_sleep),
              (SELECT count(*) FROM raw_sleep) - (SELECT count(*) FROM sleep),
              (SELECT count(DISTINCT Id) FROM sleep))
UNION ALL SELECT format('Joined daily activity × sleep on Id+date: {} days, {} users',
              (SELECT count(*) FROM daily_sleep), (SELECT count(DISTINCT Id) FROM daily_sleep))
UNION ALL SELECT format('weightLogInfo_merged.csv: {} rows loaded, {} duplicates removed, {} users; Fat column is mostly empty and unused',
              (SELECT count(*) FROM raw_weight),
              (SELECT count(*) FROM raw_weight) - (SELECT count(*) FROM weight),
              (SELECT count(DISTINCT Id) FROM weight));

-- name: overview
SELECT
    count(DISTINCT Id)                                        AS n_users,
    count(*)                                                  AS n_days,
    min(ActivityDate)::VARCHAR                                AS date_min,
    max(ActivityDate)::VARCHAR                                AS date_max,
    round(avg(TotalSteps))::INT                               AS avg_steps,
    round(median(TotalSteps))::INT                            AS median_steps,
    round(avg(SedentaryMinutes) / 60, 1)                      AS avg_sed_h,
    (SELECT round(avg(SedentaryMinutes) / 60, 1) FROM daily_sleep) AS avg_sed_h_sleep_days,  -- waking only: sleep is logged separately on these days
    -- On days without a sleep record, sleep time is logged as sedentary, so waking
    -- sedentary time can only be measured on the days that have a sleep record.
    (SELECT round(avg(SedentaryMinutes) / 60, 1) FROM daily_sleep) AS avg_sed_waking_h,
    (SELECT round(avg(SedentaryMinutes) / 60, 1) FROM daily d
      WHERE NOT EXISTS (SELECT 1 FROM daily_sleep s WHERE s.Id = d.Id AND s.ActivityDate = d.ActivityDate)) AS avg_sed_nosleep_h,
    round(avg(LightlyActiveMinutes))::INT                     AS avg_light_min,
    round(avg(ActiveMin))::INT                                AS avg_active_min,
    round(100 * avg((TotalSteps >= 10000)::INT))::INT         AS pct_days_10k,
    round(100 * avg((WearMin >= 1380)::INT))::INT             AS pct_days_full_wear,  -- worn 23h+, i.e. incl. sleep
    round(avg(WearMin) / 60, 1)                               AS avg_wear_h,
    round(corr(TotalSteps, Calories), 2)                      AS corr_steps_cal
FROM daily;

-- name: minutes_split
SELECT
    round(avg(VeryActiveMinutes))::INT    AS VeryActiveMinutes,
    round(avg(FairlyActiveMinutes))::INT  AS FairlyActiveMinutes,
    round(avg(LightlyActiveMinutes))::INT AS LightlyActiveMinutes,
    round(avg(SedentaryMinutes))::INT     AS SedentaryMinutes
FROM daily;

-- name: levels
SELECT level, count(*)::INT AS users
FROM user_summary
GROUP BY level
ORDER BY min(steps);

-- name: days_per_user
SELECT min(days)::INT AS "min", round(median(days))::INT AS "50%", max(days)::INT AS "max"
FROM user_summary;

-- name: weekday
SELECT Weekday, round(avg(TotalSteps))::INT AS steps, round(avg(SedentaryMinutes))::INT AS sed
FROM daily
GROUP BY Weekday, WeekdayNum
ORDER BY WeekdayNum;

-- name: hourly
SELECT Hour, round(avg(StepTotal))::INT AS steps
FROM hourly
GROUP BY Hour
ORDER BY Hour;

-- name: sleep
WITH per_user AS (
    SELECT Id, count(*) AS nights, avg(TotalMinutesAsleep) AS asleep
    FROM sleep GROUP BY Id
)
SELECT
    (SELECT count(*) FROM per_user)::INT                                AS sleep_users,
    (SELECT round(avg(TotalMinutesAsleep) / 60, 1) FROM sleep)          AS avg_sleep_h,
    (SELECT round(100 * avg((TotalMinutesAsleep < 420)::INT))::INT FROM sleep) AS pct_nights_under7,
    (SELECT round(100 * avg((asleep < 420)::INT))::INT FROM per_user)  AS pct_users_under7,
    (SELECT round(avg(AwakeInBed))::INT FROM sleep)                     AS avg_awake_in_bed,
    (SELECT count(*) FROM per_user WHERE nights >= 15)::INT             AS sleep_users_regular,
    (SELECT round(corr(SedentaryMinutes, TotalMinutesAsleep), 2) FROM daily_sleep) AS corr_sed_sleep;

-- name: adoption
SELECT
    (SELECT count(DISTINCT Id) FROM weight)::INT                                      AS weight_users,
    (SELECT round(100 * avg((lower(IsManualReport) = 'true')::INT))::INT FROM weight) AS weight_manual_pct,
    (SELECT count(*) FROM hr_users)::INT                                              AS hr_users;

-- name: scatter_sed_sleep
SELECT SedentaryMinutes, TotalMinutesAsleep FROM daily_sleep;

-- name: scatter_steps_cal
SELECT TotalSteps, Calories FROM daily;
