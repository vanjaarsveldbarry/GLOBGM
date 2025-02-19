import seaborn as sns
import matplotlib.pyplot as plt
from pathlib import Path
import pandas as pd

dataPath = Path("/scratch-shared/globgm_scratch/analysis/cmip6_runs/sanity_check_runs/solution_time_series/data")
save_dir = Path("/scratch-shared/globgm_scratch/analysis/cmip6_runs/sanity_check_runs/solution_time_series/plots")
save_dir.mkdir(exist_ok=True, parents=True)

custom_palette = {
    'historical': 'gray', 
    'ssp126': 'blue', 
    'ssp370': 'red',
    'ssp585': 'black',
}


for solution in [3]:
    all_files = dataPath.glob(f"*s0{solution}*.parquet")
    df_list = [pd.read_parquet(file) for file in all_files]
    combined_df = pd.concat(df_list, ignore_index=True)
    print(combined_df)
    fig, ax = plt.subplots(figsize=(10, 6))
    
    hue_order = ['historical', 'ssp126', 'ssp370', 'ssp585']
    
    sns.lineplot(x='time', y='l2_hds', hue='scenario', data=combined_df,units='GCM', palette=custom_palette, ax=ax, 
                 alpha=0.2, legend=False, hue_order=hue_order, estimator=None, linewidth=0.5)
    sns.lineplot(x='time', y='l2_hds', hue='scenario', data=combined_df, palette=custom_palette, ax=ax, 
                 hue_order=hue_order, linewidth=1.5)
    if solution == 1: plt.title(f'Solution {solution}: Afro-Eurasia')
    if solution == 2: plt.title(f'Solution {solution}: Americas')
    if solution == 3: plt.title(f'Solution {solution}: Australia')
    if solution == 4: plt.title(f'Solution {solution}: Islands ')
    
    plt.savefig(save_dir / f's0{solution}.png')
    plt.close()