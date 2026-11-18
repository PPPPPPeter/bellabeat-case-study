-- One row per user-day the device was worn (a day with 0 steps means it was not worn)
select *,
    dayname(ActivityDate)                   as Weekday,
    isodow(ActivityDate)                    as WeekdayNum,
    VeryActiveMinutes + FairlyActiveMinutes as ActiveMin
from {{ ref('int_daily_dedup') }}
where TotalSteps > 0 and WearMin > 0
