-- Parse the date and drop exact duplicate rows (ignoring which export file they came from)
select distinct
    * exclude (filename, ActivityDate),
    strptime(ActivityDate, '%m/%d/%Y')::date as ActivityDate,
    VeryActiveMinutes + FairlyActiveMinutes + LightlyActiveMinutes + SedentaryMinutes as WearMin
from {{ ref('stg_fitbit__daily_activity') }}
