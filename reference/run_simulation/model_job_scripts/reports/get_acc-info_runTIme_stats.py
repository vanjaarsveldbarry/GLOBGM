from bs4 import BeautifulSoup
import json
import pandas as pd
from pathlib import Path

acc_df = pd.read_csv('/projects/prjs1222/GLOBGM/run_simulation/model_job_scripts/reports/results/rule_acc_info.csv')
reportsPath= Path('/projects/prjs1222/GLOBGM/run_simulation/model_job_scripts/reports/')
savePath = Path('/projects/prjs1222/GLOBGM/run_simulation/model_job_scripts/reports/results/')
GCM='ipsl-cm6a-lr'
for scen in ['historical', 'ssp126', 'ssp370', 'ssp585']:
    file_path = reportsPath / f'transient_{GCM}_{scen}_report.html'
    with open(file_path, 'r', encoding='utf-8') as file:
        content = file.read()

    soup = BeautifulSoup(content, 'html.parser')
    script_tag = soup.find('script', {'id': 'runtimes'})
    script_content = script_tag.string
    data = json.loads(script_content.split('=')[1].strip().rstrip(';'))
    values = data['data']['values']
    df = pd.DataFrame(values)
    merged_df = pd.merge(df, acc_df, on='rule', how='inner')
    merged_df['runtime'] = merged_df['runtime'] / 3600
    merged_df['sbu'] = merged_df['runtime'] * merged_df['cpus'] * merged_df['weight']
    merged_df.to_html(savePath / f'{GCM}_{scen}_runtime_stats.html', index=False)


all_dfs = []

for scen in ['historical', 'ssp126', 'ssp370', 'ssp585']:
    df = pd.read_html(f'/projects/prjs1222/GLOBGM/run_simulation/model_job_scripts/reports/results/ipsl-cm6a-lr_{scen}_runtime_stats.html')
    df = df[0].groupby('weight').sum()[['sbu']]
    df['scen'] = scen
    all_dfs.append(df)

# Concatenate all DataFrames into a single DataFrame
merged_df = pd.concat(all_dfs).reset_index()
merged_df = merged_df.pivot(index='scen', columns='weight', values='sbu')
totals = merged_df.sum(axis=0)
totals.name = 'Total'
merged_df = pd.concat([merged_df, totals.to_frame().T])
merged_df['Total'] = merged_df.sum(axis=1)
merged_df.to_html(savePath / f'{GCM}_stats.html')
    
    

