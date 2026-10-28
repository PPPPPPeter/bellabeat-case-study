-- 02_clean.sql: parse dates, remove duplicates, drop non-wear days, add derived columns.

-- Daily activity -------------------------------------------------------------
-- Step 1: parse the date and drop exact duplicate rows (ignoring which file they came from)
CREATE OR REPLACE TABLE daily_parsed AS
SELECT DISTINCT
    * EXCLUDE (filename, ActivityDate),
    strptime(ActivityDate, '%m/%d/%Y')::DATE AS ActivityDate,
    VeryActiveMinutes + FairlyActiveMinutes + LightlyActiveMinutes + SedentaryMinutes AS WearMin
FROM raw_daily;

-- Step 2: the two exports overlap on 2016-04-12; keep the row with the most recorded minutes
CREATE OR REPLACE TABLE daily_dedup AS
SELECT * FROM daily_parsed
QUALIFY row_number() OVER (PARTITION BY Id, ActivityDate ORDER BY WearMin DESC, TotalSteps DESC) = 1;

-- Step 3: a day with 0 steps means the device was not worn
CREATE OR REPLACE TABLE daily AS
SELECT *,
    dayname(ActivityDate)                     AS Weekday,
    isodow(ActivityDate)                      AS WeekdayNum,
    VeryActiveMinutes + FairlyActiveMinutes   AS ActiveMin
FROM daily_dedup
WHERE TotalSteps > 0 AND WearMin > 0;

-- Hourly steps ---------------------------------------------------------------
CREATE OR REPLACE TABLE hourly AS
SELECT Id,
    strptime(ActivityHour, '%m/%d/%Y %I:%M:%S %p') AS ActivityHour,
    hour(strptime(ActivityHour, '%m/%d/%Y %I:%M:%S %p')) AS Hour,
    StepTotal
FROM raw_hourly
QUALIFY row_number() OVER (PARTITION BY Id, ActivityHour ORDER BY StepTotal DESC) = 1;

-- Sleep ----------------------------------------------------------------------
CREATE OR REPLACE TABLE sleep AS
SELECT Id,
    strptime(SleepDay, '%m/%d/%Y %I:%M:%S %p')::DATE AS SleepDate,
    TotalSleepRecords, TotalMinutesAsleep, TotalTimeInBed,
    TotalTimeInBed - TotalMinutesAsleep AS AwakeInBed
FROM raw_sleep
QUALIFY row_number() OVER (PARTITION BY Id, SleepDate ORDER BY TotalMinutesAsleep DESC) = 1;

-- Activity joined to sleep on the same user and date
CREATE OR REPLACE TABLE daily_sleep AS
SELECT d.*, s.TotalMinutesAsleep, s.TotalTimeInBed, s.AwakeInBed
FROM daily d
JOIN sleep s ON s.Id = d.Id AND s.SleepDate = d.ActivityDate;

-- Weight ---------------------------------------------------------------------
CREATE OR REPLACE TABLE weight AS
SELECT DISTINCT * EXCLUDE (filename, Date),
    strptime(Date, '%m/%d/%Y %I:%M:%S %p') AS LogTime
FROM raw_weight;

-- Per-user profile -----------------------------------------------------------
CREATE OR REPLACE TABLE user_summary AS
SELECT Id,
    count(*)                              AS days,
    round(avg(TotalSteps), 1)             AS steps,
    round(avg(WearMin), 1)                AS wear,
    round(avg(SedentaryMinutes), 1)       AS sed,
    round(avg(ActiveMin), 1)              AS active,
    round(avg(Calories), 1)               AS cal,
    CASE WHEN avg(TotalSteps) < 5000  THEN 'Sedentary (<5k)'
         WHEN avg(TotalSteps) < 7500  THEN 'Lightly active (5–7.5k)'
         WHEN avg(TotalSteps) < 10000 THEN 'Fairly active (7.5–10k)'
         ELSE 'Very active (10k+)' END    AS level
FROM daily
GROUP BY Id;

-- Integrity checks: every row must return 0 (run_sql.py fails otherwise) -----
CREATE OR REPLACE VIEW checks AS
SELECT 'duplicate user-days in daily' AS check_name,
       (SELECT count(*) - count(DISTINCT (Id, ActivityDate)) FROM daily) AS violations
UNION ALL SELECT 'days over 1,440 minutes', (SELECT count(*) FROM daily WHERE WearMin > 1440)
UNION ALL SELECT 'duplicate user-nights in sleep', (SELECT count(*) - count(DISTINCT (Id, SleepDate)) FROM sleep)
UNION ALL SELECT 'asleep longer than time in bed', (SELECT count(*) FROM sleep WHERE AwakeInBed < 0)
UNION ALL SELECT 'null steps or dates', (SELECT count(*) FROM daily WHERE TotalSteps IS NULL OR ActivityDate IS NULL);
