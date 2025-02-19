import pandas as pd
from pathlib import Path
import matplotlib.pyplot as plt
import seaborn as sns
plt.switch_backend('agg')

dataPath = Path('/scratch-shared/globgm_scratch/analysis/cmip6_runs/sanity_check_runs/hotspots_time_series/data')
savePath = Path('/scratch-shared/globgm_scratch/analysis/cmip6_runs/sanity_check_runs/hotspots_time_series/plots')
savePath.mkdir(parents=True, exist_ok=True)

var = 'hds'
dataframes = []
for GCM in ['ipsl-cm6a-lr', 'gfdl-esm4', 'mpi-esm1-2-hr', 'mri-esm2-0', 'ukesm1-0-ll']:
    for scen in ['historical']:#, 'ssp126', 'ssp370', 'ssp585']:
        file_paths = list((dataPath / f'{GCM}/{scen}').glob(f'*{var}.parquet'))
        for file_path in file_paths:
            df_sub = pd.read_parquet(file_path)
            df_sub['scenario'] = scen
            df_sub['GCM'] = GCM
            dataframes.append(df_sub)

df = pd.concat(dataframes, ignore_index=True)
print(df)
unique_names = df['name'].unique()
unique_names = sorted(unique_names)
print(unique_names)
custom_palette = {
    'historical': 'gray', 
    'ssp126': 'blue', 
    'ssp370': 'red',
    'ssp585': 'black',
}

custom_dashes = {
    'historical': '',
    'ssp126': (2,2),
    'ssp370': ''
}

fig, axes = plt.subplots(nrows=len(unique_names), ncols=2, figsize=(20, 5 * len(unique_names)))
for i, name in enumerate(unique_names):
    df_name = df[df['name'] == name]
    print(df_name)
    sns.lineplot(x='time', y=f'l1_{var}', hue='scenario', style='GCM', data=df_name, ax=axes[i, 0], palette=custom_palette, alpha=0.1, legend=False)
    sns.lineplot(x='time', y=f'l1_{var}', hue='scenario', data=df_name, ax=axes[i, 0], palette=custom_palette)
    
    sns.lineplot(x='time', y=f'l2_{var}', hue='scenario', style='GCM', data=df_name, ax=axes[i, 0], palette=custom_palette, alpha=0.1, legend=False)
    
    axes[i, 0].set_ylabel(f'{name}')

    axes[i, 0].tick_params(axis='x', which='both', bottom=False, top=False, labelbottom=False)
    axes[i, 1].tick_params(axis='x', which='both', bottom=False, top=False, labelbottom=False)
    axes[i, 0].tick_params(axis='y', which='both', left=True, right=False, labelleft=True)
    axes[i, 1].tick_params(axis='y', which='both', left=False, right=False, labelleft=True)
    axes[i, 0].set_xlabel('')
    axes[i, 1].set_xlabel('')
    axes[i, 1].set_ylabel('')
    if i == 0:
        axes[i, 0].set_title(f'{var} - l1')
        axes[i, 1].set_title(f'{var} - l2')
    if i == len(unique_names) - 1:
        axes[i, 0].set_xlabel('Time')
        axes[i, 1].set_xlabel('Time')
        axes[i, 0].tick_params(axis='x', which='both', bottom=True, top=False, labelbottom=True)
        axes[i, 1].tick_params(axis='x', which='both', bottom=True, top=False, labelbottom=True)
plt.tight_layout()
plt.savefig(savePath / 'hotspots_trends.png')
