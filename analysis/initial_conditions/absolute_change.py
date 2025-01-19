import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import numpy as np
from pathlib import Path

inputFolder = Path('/scratch-shared/_bvjaarsveld1/output_initial_conditions/gswp3-w5e5')
saveDir = Path('/home/bvjaarsveld1/projects/workflow/GLOBGM/analysis/initial_conditions/_plots')
fig, axes = plt.subplots(nrows=4, ncols=2, figsize=(15, 20))
axes = axes.flatten()
for layer in [1, 2]:
    for idx, solution in enumerate([1, 2, 3, 4]):
        df_ss = pd.read_csv(inputFolder / f'ss/mf6_post/s0{solution}_hds_l{layer}_abs.csv').melt(var_name='Iteration', value_name='Value')
        df_ss['Iteration'] = df_ss['Iteration'].str.extract(r'(\d+)').astype(int)
        df_ss = df_ss.rename(columns={'Value': 'bias_ss'})
        df_ss['Label'] = 'ss'
        
        df_no_pump = pd.read_csv(inputFolder / f'tr_no_pump/mf6_post/s0{solution}_hds_l{layer}_abs.csv').melt(var_name='Iteration', value_name='Value')
        df_no_pump['Iteration'] = df_no_pump['Iteration'].str.extract(r'(\d+)').astype(int)
        df_no_pump = df_no_pump.rename(columns={'Value': 'no_pump'})
        df_no_pump['Label'] = 'no_pump'
        
        df_with_pump = pd.read_csv(inputFolder / f'tr_with_pump/mf6_post/s0{solution}_hds_l{layer}_abs.csv').melt(var_name='Iteration', value_name='Value')
        df_with_pump['Iteration'] = df_with_pump['Iteration'].str.extract(r'(\d+)').astype(int)
        df_with_pump = df_with_pump.rename(columns={'Value': 'with_pump'})
        df_with_pump['Label'] = 'with_pump'
        
        combined_df = pd.concat([df_ss, df_no_pump, df_with_pump])
        combined_df['Index'] = range(len(combined_df))
        combined_df['bias'] = combined_df['bias_ss'].combine_first(combined_df['no_pump']).combine_first(combined_df['with_pump'])
        combined_df = combined_df.drop(columns=['bias_ss', 'no_pump', 'with_pump'])
        melted_df = combined_df.melt(id_vars=['Iteration', 'Index', 'Label'], value_vars=['bias'], value_name='Value')
        
        col_index = 0 if layer == 1 else 1
        row_index = idx
        sns.lineplot(data=melted_df, x='Index', y='Value', marker='o', hue='Label', ax=axes[row_index * 2 + col_index])
        axes[row_index * 2 + col_index].set_xlabel('Iteration')
        if solution == 1:
            title = f'Afro-Eurasia hds Layer {layer}'
        elif solution == 2:
            title = f'Americas hds Layer {layer}'
        elif solution == 3:
            title = f'Australia hds Layer {layer}'
        elif solution == 4:
            title = f'Islands hds Layer {layer}'
        
        axes[row_index * 2 + col_index].set_title(title)
        
        if col_index == 0:
            axes[row_index * 2 + col_index].set_ylabel('Absolute hds values')
        else:
            axes[row_index * 2 + col_index].set_ylabel('')
fig.tight_layout()
fig.savefig(saveDir / 'absolute_change.png')