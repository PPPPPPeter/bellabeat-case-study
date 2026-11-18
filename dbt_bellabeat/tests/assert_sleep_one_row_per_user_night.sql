select Id, SleepDate, count(*) as n
from {{ ref('fct_sleep') }}
group by Id, SleepDate
having count(*) > 1
