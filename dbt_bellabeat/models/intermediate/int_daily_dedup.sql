-- The two exports overlap on 2016-04-12; keep the row with the most recorded minutes
select *
from {{ ref('int_daily_parsed') }}
qualify row_number() over (partition by Id, ActivityDate order by WearMin desc, TotalSteps desc) = 1
