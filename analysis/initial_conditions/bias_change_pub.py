import pandas as pd
from pathlib import Path
import seaborn as sns
import matplotlib.pyplot as plt
import numpy as np 
import math
from sklearn.preprocessing import MaxAbsScaler
import matplotlib.ticker as ticker

dataPath = Path('/projects/prjs1222/scratch_backup/globgm_scratch/initial_conditions/output_initial_conditions')
saveDir = Path('/projects/prjs1222/scratch_backup/globgm_scratch/analysis/initial_conditions/_plots')
unique_solutions = [1, 2, 3]
_title_font_size = 16
_tick_font_size = 14

#################################
# Relative Bias change #
#################################
unique_solutions = [2, 1, 3]
unique_labels = ['0_5', '5_10', '10_20', '20_60', '>60']
for solution in [1, 2, 3]:
    id_vars = ['lat', 'lon', 'sim_gw', 'avg_obs_gw', 'Point']
    
    df_layer2 = pd.read_csv(dataPath / f'ss/mf6_post/output_validation/ss_s0{solution}_layer2_bias.csv')
    df_layer1 = pd.read_csv(dataPath / f'ss/mf6_post/output_validation/ss_s0{solution}_layer1_bias.csv')
    df_ss = pd.concat([df_layer1, df_layer2])
    df_ss.insert(0, 'Point', range(1, len(df_ss) + 1))
    value_vars = [col for col in df_ss.columns if 'bias' in col]
    df_ss = pd.melt(df_ss, id_vars=id_vars, value_vars=value_vars, var_name='Iteration', value_name='Bias')
    df_ss['Label'] = 'Steady-state'
    df_ss['Iteration'] = df_ss['Iteration'].str.extract(r'(\d+)').astype(int)
    
    df_layer2 = pd.read_csv(dataPath / f'tr_no_pump/mf6_post/output_validation/tr_no_pump_s0{solution}_layer2_bias.csv')
    df_layer1 = pd.read_csv(dataPath / f'tr_no_pump/mf6_post/output_validation/tr_no_pump_s0{solution}_layer1_bias.csv')
    df_no_pump = pd.concat([df_layer1, df_layer2])
    df_no_pump.insert(0, 'Point', range(1, len(df_no_pump) + 1))
    value_vars = [col for col in df_no_pump.columns if 'bias' in col]
    df_no_pump = pd.melt(df_no_pump, id_vars=id_vars, value_vars=value_vars, var_name='Iteration', value_name='Bias')
    df_no_pump['Label'] = 'Transient: no pumping'
    df_no_pump['Iteration'] = df_no_pump['Iteration'].str.extract(r'(\d+)').astype(int)
    df_no_pump['Iteration']  = df_no_pump['Iteration'] + df_ss['Iteration'].max()
    
    df_layer2 = pd.read_csv(dataPath / f'tr_with_pump/mf6_post/output_validation/tr_with_pump_s0{solution}_layer2_bias.csv')
    df_layer1 = pd.read_csv(dataPath / f'tr_with_pump/mf6_post/output_validation/tr_with_pump_s0{solution}_layer1_bias.csv')
    df_with_pump = pd.concat([df_layer1, df_layer2])
    df_with_pump.insert(0, 'Point', range(1, len(df_with_pump) + 1))
    value_vars = [col for col in df_with_pump.columns if 'bias' in col]
    df_with_pump = pd.melt(df_with_pump, id_vars=id_vars, value_vars=value_vars, var_name='Iteration', value_name='Bias')
    df_with_pump['Label'] = 'Transient: with pumping'
    df_with_pump['Iteration'] = df_with_pump['Iteration'].str.extract(r'(\d+)').astype(int)
    df_with_pump['Iteration']  = df_with_pump['Iteration'] + df_no_pump['Iteration'].max()
    
    df_combined = pd.concat([df_ss, df_no_pump, df_with_pump])
    df_combined = df_combined.drop(columns=['lat', 'lon', 'sim_gw'])
    df_combined['Bias'] = df_combined['Bias'] * -1
    df_combined['rel_bias'] = df_combined['Bias'] / df_combined['avg_obs_gw']
    df_combined = df_combined.groupby(['Iteration', 'Label']).agg({'Bias': 'mean', 'rel_bias': 'mean'}).reset_index()
    df_combined['Solution'] = solution
    if 'mean_bias_final' not in locals():
        mean_bias_final = pd.DataFrame()
    mean_bias_final = pd.concat([mean_bias_final, df_combined])
    mean_bias_final['Iteration'] = pd.to_numeric(mean_bias_final['Iteration'], errors='coerce')
mean_bias_final = mean_bias_final.rename(columns={'Bias': 'abs_bias'})
print(mean_bias_final)

num_cols, num_rows = 3, 2  # Two rows for 'abs_bias' and 'rel_bias'
fig, axes = plt.subplots(num_rows, num_cols, figsize=(num_cols * 6, num_rows * 6.4))

for row_index, var in enumerate(['abs_bias', 'rel_bias']):
    for col_index, solution in enumerate(unique_solutions):
        ax = axes[row_index, col_index]
        data_sub = mean_bias_final[(mean_bias_final['Solution'] == solution)]
        sns.lineplot(ax=ax, data=data_sub, x='Iteration', y=var, color='black', marker='', legend=False)
        sns.lineplot(ax=ax, data=data_sub, x='Iteration', y=var, hue='Label', marker='o', legend=((col_index == 0 and row_index == 0) or (col_index == 0 and row_index == 1)))
        
        if row_index == 0:
            ax.set_xlabel(' ')
            ax.tick_params(axis='x', labelbottom=False)
            ax.tick_params(axis='y', labelsize=_tick_font_size)
            
            if col_index == 0:
                ax.set_ylabel('Mean Absolute Bias', fontsize=_title_font_size)
                legend = ax.legend(frameon=False, loc='lower left')
                legend.set_title(None)
                for text in legend.get_texts():
                    text.set_fontsize(_tick_font_size) 
            else:
                ax.set_ylabel(' ')
                
                
            if col_index == 0:
                ax.set_title('Americas', fontsize=_title_font_size)
            elif col_index == 1:
                ax.set_title('Afro-Eurasia', fontsize=_title_font_size)
            elif col_index == 2:
                ax.set_title('Australia', fontsize=_title_font_size)
                
                
        elif row_index == 1:
            ax.set_title(' ')
            ax.xaxis.label.set_size(_title_font_size)
            ax.tick_params(axis='y', labelsize=_tick_font_size)
            ax.tick_params(axis='x', labelsize=_tick_font_size)
            
            if col_index == 0:
                ax.set_ylabel('Mean Relative Bias', fontsize=_title_font_size)
                legend = ax.legend(frameon=False, loc='lower left')
                legend.set_title(None)
                for text in legend.get_texts():
                    text.set_fontsize(_tick_font_size) 
            else:
                ax.set_ylabel(' ')
        
        
        ax.yaxis.set_major_formatter(ticker.FormatStrFormatter('%.2f'))

# Adjust layout and save the combined figure
plt.tight_layout()
plt.savefig(saveDir / 'combined_bias_change_pub.png', bbox_inches='tight')
plt.close()