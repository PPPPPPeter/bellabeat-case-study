-- Only the 4.12.16–5.12.16 export has the daily sleep summary
select *
from read_csv('{{ var("data_root") }}/*/*/sleepDay_merged.csv',
              union_by_name = true, filename = true,
              types = {'SleepDay': 'VARCHAR'})
