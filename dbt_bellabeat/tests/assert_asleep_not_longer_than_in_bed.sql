select * from {{ ref('fct_sleep') }} where AwakeInBed < 0
