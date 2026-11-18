select Weekday, WeekdayNum, round(avg(TotalSteps))::int as steps, round(avg(SedentaryMinutes))::int as sed
from {{ ref('fct_daily_activity') }}
group by Weekday, WeekdayNum
