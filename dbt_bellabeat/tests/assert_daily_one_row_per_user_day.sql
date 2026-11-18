select Id, ActivityDate, count(*) as n
from {{ ref('fct_daily_activity') }}
group by Id, ActivityDate
having count(*) > 1
