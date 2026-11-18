-- Raw daily activity from both export periods; the date stays text and is parsed downstream so the format is explicit
select *
from read_csv('{{ var("data_root") }}/*/*/dailyActivity_merged.csv',
              union_by_name = true, filename = true,
              types = {'ActivityDate': 'VARCHAR'})
