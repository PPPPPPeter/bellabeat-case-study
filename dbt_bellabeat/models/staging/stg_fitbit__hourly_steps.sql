select *
from read_csv('{{ var("data_root") }}/*/*/hourlySteps_merged.csv',
              union_by_name = true, filename = true,
              types = {'ActivityHour': 'VARCHAR'})
