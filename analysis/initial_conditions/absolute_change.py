import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import numpy as np
from pathlib import Path

inputFolder = Path('/projects/prjs1222/scratch_backup/globgm_scratch/initial_conditions/output_initial_conditions')
saveDir = Path('/projects/prjs1222/scratch_backup/globgm_scratch/analysis/initial_conditions/_plots')
saveDir.mkdir(parents=True, exist_ok=True)

fig, axes = plt.subplots(nrows=2, ncols=4, figsize=(18, 10))
axes = axes.flatten()
for idx, solution in enumerate([2, 1, 3, 4]):
    df_ss_l1 = pd.read_csv(inputFolder / f'ss/mf6_post/s0{solution}_hds_l1_abs.csv').melt(var_name='Iteration', value_name='Value').rename(columns={'Value': 'bias_ss'})
    df_ss_l1['Label'] = 'Steady-state'
    df_ss_l1['Layer'] = 1    

    df_ss_l2 = pd.read_csv(inputFolder / f'ss/mf6_post/s0{solution}_hds_l2_abs.csv').melt(var_name='Iteration', value_name='Value').rename(columns={'Value': 'bias_ss'})
    df_ss_l2['Label'] = 'Steady-state'
    df_ss_l2['Layer'] = 2   
    
        
    df_no_pump_l1 = pd.read_csv(inputFolder / f'tr_no_pump/mf6_post/s0{solution}_hds_l1_abs.csv').melt(var_name='Iteration', value_name='Value').rename(columns={'Value': 'no_pump'})
    df_no_pump_l1['Label'] = 'Transient: no pumping'
    df_no_pump_l1['Layer'] = 1
    
    df_no_pump_l2 = pd.read_csv(inputFolder / f'tr_no_pump/mf6_post/s0{solution}_hds_l2_abs.csv').melt(var_name='Iteration', value_name='Value').rename(columns={'Value': 'no_pump'})
    df_no_pump_l2['Label'] = 'Transient: no pumping'
    df_no_pump_l2['Layer'] = 2
    
        
    df_with_pump_l1 = pd.read_csv(inputFolder / f'tr_with_pump/mf6_post/s0{solution}_hds_l1_abs.csv').melt(var_name='Iteration', value_name='Value').rename(columns={'Value': 'with_pump'})
    df_with_pump_l1['Label'] = 'Transient: with pumping'
    df_with_pump_l1['Layer'] = 1
    
    df_with_pump_l2 = pd.read_csv(inputFolder / f'tr_with_pump/mf6_post/s0{solution}_hds_l2_abs.csv').melt(var_name='Iteration', value_name='Value').rename(columns={'Value': 'with_pump'})
    df_with_pump_l2['Label'] = 'Transient: with pumping'
    df_with_pump_l2['Layer'] = 2
    
        
    combined_df = pd.concat([df_ss_l1, df_ss_l2, df_no_pump_l1, df_no_pump_l2, df_with_pump_l1, df_with_pump_l2])
    combined_df['Index'] = combined_df.groupby('Layer').cumcount()
    combined_df['bias'] = combined_df['bias_ss'].combine_first(combined_df['no_pump']).combine_first(combined_df['with_pump'])
    combined_df = combined_df.drop(columns=['bias_ss', 'no_pump', 'with_pump'])
    melted_df = combined_df.melt(id_vars=['Index', 'Label', 'Layer'], value_vars=['bias'], value_name='Value')
    melted_df['Index'] = melted_df['Index'] + 1
    
    print(melted_df)
    layer1_df = melted_df[melted_df['Layer'] ==1]
    layer2_df = melted_df[melted_df['Layer'] ==2]
    
    col_index = idx
    if col_index in [0, 4]: _legend='brief'
    else: _legend=False
    sns.lineplot(data=layer1_df, x='Index', y='Value', color='black', marker='', ax=axes[col_index], legend=_legend)
    sns.lineplot(data=layer1_df, x='Index', y='Value', marker='o', hue='Label', ax=axes[col_index], legend=_legend)
    sns.lineplot(data=layer2_df, x='Index', y='Value', color='black', marker='', ax=axes[4 + col_index], legend=_legend)
    sns.lineplot(data=layer2_df, x='Index', y='Value', marker='o', hue='Label', ax=axes[4 + col_index], legend=_legend)
    
for i in range(8):
    if i in [4, 5, 6, 7]:
        axes[i].set_xlabel('Iteration')
        axes[i].tick_params(axis='x', labelsize=14)
        axes[i].xaxis.label.set_size(16)
    else:
        axes[i].set_xlabel('')
        axes[i].tick_params(axis='x', labelbottom=False)
        
    if i == 4:
        axes[i].set_ylabel('Layer 2')
        axes[i].yaxis.label.set_size(16)
        axes[i].tick_params(axis='y', labelsize=14)
        legend = axes[i].legend(frameon=False)
        legend.set_title(None)
        for text in legend.get_texts():
            text.set_fontsize(14) 
        
    elif i == 0:
        axes[i].set_ylabel('Layer 1')
        axes[i].yaxis.label.set_size(16)
        axes[i].tick_params(axis='y', labelsize=14)
        legend = axes[i].legend(frameon=False)
        legend.set_title(None)
        for text in legend.get_texts():
            text.set_fontsize(14) 
        
    else:
        axes[i].set_ylabel('')
        axes[i].tick_params(axis='y', labelsize=14)
        
    axes[i].yaxis.set_major_formatter(plt.FuncFormatter(lambda x, _: f'{x:.1f}'))
    
    if i == 0:axes[i].set_title('Americas', fontsize=16)
    if i == 1:axes[i].set_title('Afro-Eurasia', fontsize=16)
    if i == 2:axes[i].set_title('Australia', fontsize=16)
    if i == 3:axes[i].set_title('Islands', fontsize=16)
    

fig.tight_layout()
fig.savefig(saveDir / 'absolute_change.png')