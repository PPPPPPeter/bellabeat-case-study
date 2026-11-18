select level, count(*)::int as users, min(steps) as min_avg_steps
from {{ ref('dim_users') }}
group by level
