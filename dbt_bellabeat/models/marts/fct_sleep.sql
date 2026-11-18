select Id,
    strptime(SleepDay, '%m/%d/%Y %I:%M:%S %p')::date as SleepDate,
    TotalSleepRecords, TotalMinutesAsleep, TotalTimeInBed,
    TotalTimeInBed - TotalMinutesAsleep              as AwakeInBed
from {{ ref('stg_fitbit__sleep_day') }}
qualify row_number() over (partition by Id, SleepDate order by TotalMinutesAsleep desc) = 1
