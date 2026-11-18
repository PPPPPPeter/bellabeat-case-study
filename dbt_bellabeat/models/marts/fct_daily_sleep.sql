-- Activity joined to sleep on the same user and date (only sleep-tracked days separate waking sedentary time from sleep)
select d.*, s.TotalMinutesAsleep, s.TotalTimeInBed, s.AwakeInBed
from {{ ref('fct_daily_activity') }} d
join {{ ref('fct_sleep') }} s on s.Id = d.Id and s.SleepDate = d.ActivityDate
