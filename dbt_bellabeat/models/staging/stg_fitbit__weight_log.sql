select *
from read_csv('{{ var("data_root") }}/*/*/weightLogInfo_merged.csv',
              union_by_name = true, filename = true,
              types = {'Date': 'VARCHAR', 'IsManualReport': 'VARCHAR'})
