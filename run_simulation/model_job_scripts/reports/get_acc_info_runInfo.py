from bs4 import BeautifulSoup
import json
import pandas as pd
import numpy as np
file_path = '/projects/prjs1222/GLOBGM/run_simulation/model_job_scripts/reports/transient_ipsl-cm6a-lr_historical_report.html'
with open(file_path, 'r', encoding='utf-8') as file:
    content = file.read()

soup = BeautifulSoup(content, 'html.parser')
script_tag = soup.find('script', {'id': 'runtimes'})

if script_tag:
    script_content = script_tag.string
    data = json.loads(script_content.split('=')[1].strip().rstrip(';'))
    values = data['data']['values']
    df = pd.DataFrame(values)[['rule']]
    # output_file_path = '/projects/prjs1222/GLOBGM/run_simulation/model_job_scripts/reports/results/rule_info.csv'
    # df.to_csv(output_file_path, index=False)
    
    df['cpus'] = np.nan
    df['weight'] = np.nan
    df['node'] = np.nan

local_rules = ['setup_simulation', 'prepare_model_partitioning', 'write_model_forcing_setup', 'setup_output', 
               '_setup_subRun', 'modify_ini_conditions_subRun']
for index, row in df.iterrows():
    for rule in local_rules:
        if rule in row['rule']:
            df.at[index, 'cpus'] = 16
            df.at[index, 'weight'] = 1
            
            
    if 'write_model_forcing_sub' in row['rule']:
            df.at[index, 'cpus'] = 192
            df.at[index, 'weight'] = 1.5
            
    if 'write_models_solution' in row['rule']:
            df.at[index, 'cpus'] = 192
            df.at[index, 'weight'] = 1.5
    if 'run_model_solution1' in row['rule']:
            df.at[index, 'cpus'] = 1372
            df.at[index, 'weight'] = 1
    if 'run_model_solution2' in row['rule']:
            df.at[index, 'cpus'] = 576
            df.at[index, 'weight'] = 1
    if 'run_model_solution3' in row['rule']:
            df.at[index, 'cpus'] = 192
            df.at[index, 'weight'] = 1
    if 'run_model_solution4' in row['rule']:
            df.at[index, 'cpus'] = 192
            df.at[index, 'weight'] = 1
    if 'post_model_solution' in row['rule']:
        if 'post_model_solution4' in row['rule']:
            df.at[index, 'cpus'] = 32
            df.at[index, 'weight'] = 1
        else:
            df.at[index, 'cpus'] = 16
            df.at[index, 'weight'] = 1
            
df.dropna(inplace=True)
print(df)
output_file_path = '/projects/prjs1222/GLOBGM/run_simulation/model_job_scripts/reports/results/rule_acc_info.csv'
df.to_csv(output_file_path, index=False)