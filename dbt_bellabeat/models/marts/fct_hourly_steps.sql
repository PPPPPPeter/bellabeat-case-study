select Id,
    strptime(ActivityHour, '%m/%d/%Y %I:%M:%S %p')       as ActivityHour,
    hour(strptime(ActivityHour, '%m/%d/%Y %I:%M:%S %p')) as Hour,
    StepTotal
from {{ ref('stg_fitbit__hourly_steps') }}
qualify row_number() over (partition by Id, ActivityHour order by StepTotal desc) = 1
