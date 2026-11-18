select distinct * exclude (filename, Date),
    strptime(Date, '%m/%d/%Y %I:%M:%S %p') as LogTime
from {{ ref('stg_fitbit__weight_log') }}
