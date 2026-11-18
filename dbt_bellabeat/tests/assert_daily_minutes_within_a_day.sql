-- logged minutes can never exceed 24 h
select * from {{ ref('fct_daily_activity') }} where WearMin > 1440
