-- Heart rate is ~3.6M rows at 5-second grain; only adoption (which users have it) is needed
select distinct Id
from read_csv('{{ var("data_root") }}/*/*/heartrate_seconds_merged.csv', union_by_name = true)
