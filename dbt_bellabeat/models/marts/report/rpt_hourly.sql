select Hour, round(avg(StepTotal))::int as steps
from {{ ref('fct_hourly_steps') }}
group by Hour
