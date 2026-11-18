-- Per-user profile and activity level
select Id,
    count(*)                        as days,
    round(avg(TotalSteps), 1)       as steps,
    round(avg(WearMin), 1)          as wear,
    round(avg(SedentaryMinutes), 1) as sed,
    round(avg(ActiveMin), 1)        as active,
    round(avg(Calories), 1)         as cal,
    case when avg(TotalSteps) < 5000  then 'Sedentary (<5k)'
         when avg(TotalSteps) < 7500  then 'Lightly active (5–7.5k)'
         when avg(TotalSteps) < 10000 then 'Fairly active (7.5–10k)'
         else 'Very active (10k+)' end as level
from {{ ref('fct_daily_activity') }}
group by Id
