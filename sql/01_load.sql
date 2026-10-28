-- 01_load.sql: load the raw Fitbit CSVs from both export periods into raw_* tables.
-- {ROOT} is replaced by run_sql.py with the kagglehub dataset folder.
-- Date columns are read as text and parsed in 02_clean.sql so the format is explicit.

CREATE OR REPLACE TABLE raw_daily AS
SELECT * FROM read_csv('{ROOT}/*/*/dailyActivity_merged.csv',
                       union_by_name = true, filename = true,
                       types = {'ActivityDate': 'VARCHAR'});

CREATE OR REPLACE TABLE raw_hourly AS
SELECT * FROM read_csv('{ROOT}/*/*/hourlySteps_merged.csv',
                       union_by_name = true, filename = true,
                       types = {'ActivityHour': 'VARCHAR'});

-- Only the 4.12.16–5.12.16 export has the daily sleep summary
CREATE OR REPLACE TABLE raw_sleep AS
SELECT * FROM read_csv('{ROOT}/*/*/sleepDay_merged.csv',
                       union_by_name = true, filename = true,
                       types = {'SleepDay': 'VARCHAR'});

CREATE OR REPLACE TABLE raw_weight AS
SELECT * FROM read_csv('{ROOT}/*/*/weightLogInfo_merged.csv',
                       union_by_name = true, filename = true,
                       types = {'Date': 'VARCHAR', 'IsManualReport': 'VARCHAR'});

-- Heart rate is ~3.6M rows at 5-second grain; only adoption (which users have it) is needed
CREATE OR REPLACE TABLE hr_users AS
SELECT DISTINCT Id FROM read_csv('{ROOT}/*/*/heartrate_seconds_merged.csv', union_by_name = true);
