import pandas as pd
from pathlib import Path
import matplotlib.pyplot as plt
import seaborn as sns
dataPath = Path('/scratch-shared/globgm_scratch/analysis/cmip6_runs/hotspots_trends/data/timeseries')
savePath = Path('/scratch-shared/globgm_scratch/analysis/cmip6_runs/hotspots_trends/plots')
savePath.mkdir(parents=True, exist_ok=True)

GCM = 'ipsl-cm6a-lr'
var = 'hds'
dataframes = []
for scen in ['historical', 'ssp126', 'ssp370', 'ssp585']:
    file_paths = list((dataPath / f'{GCM}/{scen}').glob(f'*{var}.parquet'))
    for file_path in file_paths:
        df_sub = pd.read_parquet(file_path)
        df_sub['scenario'] = scen
        dataframes.append(df_sub)

df = pd.concat(dataframes, ignore_index=True)
unique_names = df['name'].unique()
unique_names = sorted(unique_names)
print(df['scenario'].unique())
custom_palette = {'historical': 'black', 'ssp126': 'blue', 'ssp370': 'pink', 'ssp585': 'green'}
fig, axes = plt.subplots(nrows=len(unique_names), ncols=2, figsize=(20, 5 * len(unique_names)))
for i, name in enumerate(unique_names):
    df_name = df[df['name'] == name]
    # Plotting the first column
    sns.lineplot(x='time', y=f'l1_{var}', hue='scenario', data=df_name, ax=axes[i, 0], palette=custom_palette)
    # Plotting the second column
    sns.lineplot(x='time', y=f'l2_{var}', hue='scenario', data=df_name, ax=axes[i, 1], palette=custom_palette)
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
plt.savefig(savePath / f'{GCM}_trends.png')