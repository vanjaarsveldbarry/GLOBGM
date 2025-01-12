import pandas as pd
from pathlib import Path
import seaborn as sns
import matplotlib.pyplot as plt
import numpy as np 
import math
from sklearn.preprocessing import MaxAbsScaler
import matplotlib.ticker as ticker

dataPath = Path('/scratch-shared/_bvjaarsveld1/output_initial_conditions/gswp3-w5e5')
unique_solutions = [1, 2, 3]

########################
# Absolute Bias change #
########################
for solution in [1, 2, 3]:
    id_vars = ['lat', 'lon', 'sim_gw', 'avg_obs_gw', 'Point']
    
    df_layer2 = pd.read_csv(dataPath / f'ss/mf6_post/output_validation/ss_s0{solution}_layer2_bias.csv')
    df_layer1 = pd.read_csv(dataPath / f'ss/mf6_post/output_validation/ss_s0{solution}_layer1_bias.csv')
    df_ss = pd.concat([df_layer1, df_layer2])
    df_ss.insert(0, 'Point', range(1, len(df_ss) + 1))
    value_vars = [col for col in df_ss.columns if 'bias' in col]
    df_ss = pd.melt(df_ss, id_vars=id_vars, value_vars=value_vars, var_name='Iteration', value_name='Bias')
    df_ss['Label'] = 'ss'
    df_ss['Iteration'] = df_ss['Iteration'].str.extract('(\d+)').astype(int)
    
    df_layer2 = pd.read_csv(dataPath / f'tr_no_pump/mf6_post/output_validation/tr_no_pump_s0{solution}_layer2_bias.csv')
    df_layer1 = pd.read_csv(dataPath / f'tr_no_pump/mf6_post/output_validation/tr_no_pump_s0{solution}_layer1_bias.csv')
    df_no_pump = pd.concat([df_layer1, df_layer2])
    df_no_pump.insert(0, 'Point', range(1, len(df_no_pump) + 1))
    value_vars = [col for col in df_no_pump.columns if 'bias' in col]
    df_no_pump = pd.melt(df_no_pump, id_vars=id_vars, value_vars=value_vars, var_name='Iteration', value_name='Bias')
    df_no_pump['Label'] = 'no_pump'
    df_no_pump['Iteration'] = df_no_pump['Iteration'].str.extract('(\d+)').astype(int)
    df_no_pump['Iteration']  = df_no_pump['Iteration'] + df_ss['Iteration'].max()
    
    df_layer2 = pd.read_csv(dataPath / f'tr_with_pump/mf6_post/output_validation/tr_with_pump_s0{solution}_layer2_bias.csv')
    df_layer1 = pd.read_csv(dataPath / f'tr_with_pump/mf6_post/output_validation/tr_with_pump_s0{solution}_layer1_bias.csv')
    df_with_pump = pd.concat([df_layer1, df_layer2])
    df_with_pump.insert(0, 'Point', range(1, len(df_with_pump) + 1))
    value_vars = [col for col in df_with_pump.columns if 'bias' in col]
    df_with_pump = pd.melt(df_with_pump, id_vars=id_vars, value_vars=value_vars, var_name='Iteration', value_name='Bias')
    df_with_pump['Label'] = 'with_pump'
    df_with_pump['Iteration'] = df_with_pump['Iteration'].str.extract('(\d+)').astype(int)
    df_with_pump['Iteration']  = df_with_pump['Iteration'] + df_no_pump['Iteration'].max()
    
    df_combined = pd.concat([df_ss, df_no_pump, df_with_pump])
    avg_obs_gw = df_combined[['avg_obs_gw']].abs()
    df_combined = df_combined.drop(columns=['lat', 'lon', 'sim_gw'])
    avg_obs_gw_column = df_combined.pop('avg_obs_gw')
    df_combined['Bias'] = df_combined['Bias'] * -1
    df_combined.insert(0, 'avg_obs_gw', avg_obs_gw_column)
    mean_bias = df_combined.groupby(['Iteration', 'Label']).agg({'Bias': 'mean'}).reset_index()
    mean_bias['Solution'] = solution
    if 'mean_bias_final' not in locals():
        mean_bias_final = pd.DataFrame()
    mean_bias_final = pd.concat([mean_bias_final, mean_bias])
mean_bias_final['Iteration'] = pd.to_numeric(mean_bias_final['Iteration'], errors='coerce')
mean_bias_final_average = mean_bias_final
del mean_bias
del mean_bias_final


unique_solutions = [1, 2, 3]
unique_labels = ['0_5', '5_10', '10_20', '20_60', '>60']
for solution in [1, 2, 3]:
    id_vars = ['lat', 'lon', 'sim_gw', 'avg_obs_gw', 'Point']
    
    df_layer2 = pd.read_csv(dataPath / f'ss/mf6_post/output_validation/ss_s0{solution}_layer2_bias.csv')
    df_layer1 = pd.read_csv(dataPath / f'ss/mf6_post/output_validation/ss_s0{solution}_layer1_bias.csv')
    df_ss = pd.concat([df_layer1, df_layer2])
    df_ss.insert(0, 'Point', range(1, len(df_ss) + 1))
    value_vars = [col for col in df_ss.columns if 'bias' in col]
    df_ss = pd.melt(df_ss, id_vars=id_vars, value_vars=value_vars, var_name='Iteration', value_name='Bias')
    df_ss['Label'] = 'ss'
    df_ss['Iteration'] = df_ss['Iteration'].str.extract('(\d+)').astype(int)
    
    df_layer2 = pd.read_csv(dataPath / f'tr_no_pump/mf6_post/output_validation/tr_no_pump_s0{solution}_layer2_bias.csv')
    df_layer1 = pd.read_csv(dataPath / f'tr_no_pump/mf6_post/output_validation/tr_no_pump_s0{solution}_layer1_bias.csv')
    df_no_pump = pd.concat([df_layer1, df_layer2])
    df_no_pump.insert(0, 'Point', range(1, len(df_no_pump) + 1))
    value_vars = [col for col in df_no_pump.columns if 'bias' in col]
    df_no_pump = pd.melt(df_no_pump, id_vars=id_vars, value_vars=value_vars, var_name='Iteration', value_name='Bias')
    df_no_pump['Label'] = 'no_pump'
    df_no_pump['Iteration'] = df_no_pump['Iteration'].str.extract('(\d+)').astype(int)
    df_no_pump['Iteration']  = df_no_pump['Iteration'] + df_ss['Iteration'].max()
    
    df_layer2 = pd.read_csv(dataPath / f'tr_with_pump/mf6_post/output_validation/tr_with_pump_s0{solution}_layer2_bias.csv')
    df_layer1 = pd.read_csv(dataPath / f'tr_with_pump/mf6_post/output_validation/tr_with_pump_s0{solution}_layer1_bias.csv')
    df_with_pump = pd.concat([df_layer1, df_layer2])
    df_with_pump.insert(0, 'Point', range(1, len(df_with_pump) + 1))
    value_vars = [col for col in df_with_pump.columns if 'bias' in col]
    df_with_pump = pd.melt(df_with_pump, id_vars=id_vars, value_vars=value_vars, var_name='Iteration', value_name='Bias')
    df_with_pump['Label'] = 'with_pump'
    df_with_pump['Iteration'] = df_with_pump['Iteration'].str.extract('(\d+)').astype(int)
    df_with_pump['Iteration']  = df_with_pump['Iteration'] + df_no_pump['Iteration'].max()
    
    df_combined = pd.concat([df_ss, df_no_pump, df_with_pump])
    avg_obs_gw = df_combined[['avg_obs_gw']].abs()
    df_combined = df_combined.drop(columns=['lat', 'lon', 'sim_gw'])
    avg_obs_gw_column = df_combined.pop('avg_obs_gw')
    df_combined['Bias'] = df_combined['Bias'] * -1
    df_combined.insert(0, 'avg_obs_gw', avg_obs_gw_column)
    df_combined['depthCat'] = df_combined['avg_obs_gw'].apply(
        lambda x: '0_5' if x < 5 else (
            '5_10' if 5 <= x < 10 else (
                '10_20' if 10 <= x < 20 else (
                    '20_60' if 20 <= x < 60 else (
                        '>60' if x >= 60 else 'Other'
                    )
                )
            )
        )
    )
    df_combined = df_combined.drop(columns=['avg_obs_gw'])
    mean_bias = df_combined.groupby(['Iteration', 'Label', 'depthCat']).agg({'Bias': 'mean'}).reset_index()
    mean_bias['Solution'] = solution
    if 'mean_bias_final' not in locals():
        mean_bias_final = pd.DataFrame()
    mean_bias_final = pd.concat([mean_bias_final, mean_bias])
    mean_bias_final['Iteration'] = pd.to_numeric(mean_bias_final['Iteration'], errors='coerce')

num_cols, num_rows = 3, 6
fig, axes = plt.subplots(num_rows, num_cols, figsize=(num_cols * 6 , num_rows * 6), sharex=True)
for col_index, solution in enumerate(unique_solutions):
    ax = axes[0, col_index]
    data_sub = mean_bias_final_average[(mean_bias_final_average['Solution'] == solution)]
    sns.lineplot(ax=ax, data=data_sub, x='Iteration', y='Bias', color='black', marker='')
    sns.lineplot(ax=ax, data=data_sub, x='Iteration', y='Bias', hue='Label', marker='o')
    ax.set_title(f'Solution {solution} - Average')

for col_index, solution in enumerate(unique_solutions):
    for row_index, label in enumerate(unique_labels):
        ax = axes[row_index+1, col_index]
        data_sub = mean_bias_final[(mean_bias_final['Solution'] == solution) & (mean_bias_final['depthCat'] == label)]
        sns.lineplot(ax=ax, data=data_sub, x='Iteration', y='Bias', color='black', marker='')
        sns.lineplot(ax=ax, data=data_sub, x='Iteration', y='Bias', hue='Label', marker='o')
        ax.set_title(f'Depth {label}m')
        ax.set_xlabel('Iteration')
    
for col_index, solution in enumerate(unique_solutions):
    for row_index, label in enumerate(unique_labels):
        ax = axes[row_index, col_index]
        if col_index == 0:
            ax.set_ylabel(r'Relative Bias ($obs-sim$)')
        else:
            ax.set_ylabel('')
        if row_index == 5:
            ax.set_xlabel('Iteration')
        else:
            ax.set_xlabel('')

plt.tight_layout()
plt.savefig('/home/bvjaarsveld1/projects/workflow/GLOBGM/run_initial_conditions/plots/initial_conditions/_plots/bias_change_absolute.png')
plt.close()
del mean_bias_final_average
del mean_bias
del mean_bias_final

#################################
# Relative Absolute Bias change #
#################################
for solution in [1, 2, 3]:
    id_vars = ['lat', 'lon', 'sim_gw', 'avg_obs_gw', 'Point']
    
    df_layer2 = pd.read_csv(dataPath / f'ss/mf6_post/output_validation/ss_s0{solution}_layer2_bias.csv')
    df_layer1 = pd.read_csv(dataPath / f'ss/mf6_post/output_validation/ss_s0{solution}_layer1_bias.csv')
    df_ss = pd.concat([df_layer1, df_layer2])
    df_ss.insert(0, 'Point', range(1, len(df_ss) + 1))
    value_vars = [col for col in df_ss.columns if 'bias' in col]
    df_ss = pd.melt(df_ss, id_vars=id_vars, value_vars=value_vars, var_name='Iteration', value_name='Bias')
    df_ss['Label'] = 'ss'
    df_ss['Iteration'] = df_ss['Iteration'].str.extract('(\d+)').astype(int)
    
    df_layer2 = pd.read_csv(dataPath / f'tr_no_pump/mf6_post/output_validation/tr_no_pump_s0{solution}_layer2_bias.csv')
    df_layer1 = pd.read_csv(dataPath / f'tr_no_pump/mf6_post/output_validation/tr_no_pump_s0{solution}_layer1_bias.csv')
    df_no_pump = pd.concat([df_layer1, df_layer2])
    df_no_pump.insert(0, 'Point', range(1, len(df_no_pump) + 1))
    value_vars = [col for col in df_no_pump.columns if 'bias' in col]
    df_no_pump = pd.melt(df_no_pump, id_vars=id_vars, value_vars=value_vars, var_name='Iteration', value_name='Bias')
    df_no_pump['Label'] = 'no_pump'
    df_no_pump['Iteration'] = df_no_pump['Iteration'].str.extract('(\d+)').astype(int)
    df_no_pump['Iteration']  = df_no_pump['Iteration'] + df_ss['Iteration'].max()
    
    df_layer2 = pd.read_csv(dataPath / f'tr_with_pump/mf6_post/output_validation/tr_with_pump_s0{solution}_layer2_bias.csv')
    df_layer1 = pd.read_csv(dataPath / f'tr_with_pump/mf6_post/output_validation/tr_with_pump_s0{solution}_layer1_bias.csv')
    df_with_pump = pd.concat([df_layer1, df_layer2])
    df_with_pump.insert(0, 'Point', range(1, len(df_with_pump) + 1))
    value_vars = [col for col in df_with_pump.columns if 'bias' in col]
    df_with_pump = pd.melt(df_with_pump, id_vars=id_vars, value_vars=value_vars, var_name='Iteration', value_name='Bias')
    df_with_pump['Label'] = 'with_pump'
    df_with_pump['Iteration'] = df_with_pump['Iteration'].str.extract('(\d+)').astype(int)
    df_with_pump['Iteration']  = df_with_pump['Iteration'] + df_no_pump['Iteration'].max()
    
    df_combined = pd.concat([df_ss, df_no_pump, df_with_pump])
    avg_obs_gw = df_combined[['avg_obs_gw']].abs()
    df_combined = df_combined.drop(columns=['lat', 'lon', 'sim_gw'])
    avg_obs_gw_column = df_combined.pop('avg_obs_gw')
    df_combined['Bias'] = df_combined['Bias'] * -1
    df_combined.insert(0, 'avg_obs_gw', avg_obs_gw_column)
    df_combined['Bias'] = df_combined['Bias'] / df_combined['avg_obs_gw']
    mean_bias = df_combined.groupby(['Iteration', 'Label']).agg({'Bias': 'mean'}).reset_index()
    mean_bias['Solution'] = solution
    if 'mean_bias_final' not in locals():
        mean_bias_final = pd.DataFrame()
    mean_bias_final = pd.concat([mean_bias_final, mean_bias])
mean_bias_final['Iteration'] = pd.to_numeric(mean_bias_final['Iteration'], errors='coerce')
mean_bias_final_average = mean_bias_final
del mean_bias
del mean_bias_final

unique_solutions = [1, 2, 3]
unique_labels = ['0_5', '5_10', '10_20', '20_60', '>60']
for solution in [1, 2, 3]:
    id_vars = ['lat', 'lon', 'sim_gw', 'avg_obs_gw', 'Point']
    
    df_layer2 = pd.read_csv(dataPath / f'ss/mf6_post/output_validation/ss_s0{solution}_layer2_bias.csv')
    df_layer1 = pd.read_csv(dataPath / f'ss/mf6_post/output_validation/ss_s0{solution}_layer1_bias.csv')
    df_ss = pd.concat([df_layer1, df_layer2])
    df_ss.insert(0, 'Point', range(1, len(df_ss) + 1))
    value_vars = [col for col in df_ss.columns if 'bias' in col]
    df_ss = pd.melt(df_ss, id_vars=id_vars, value_vars=value_vars, var_name='Iteration', value_name='Bias')
    df_ss['Label'] = 'ss'
    df_ss['Iteration'] = df_ss['Iteration'].str.extract('(\d+)').astype(int)
    
    df_layer2 = pd.read_csv(dataPath / f'tr_no_pump/mf6_post/output_validation/tr_no_pump_s0{solution}_layer2_bias.csv')
    df_layer1 = pd.read_csv(dataPath / f'tr_no_pump/mf6_post/output_validation/tr_no_pump_s0{solution}_layer1_bias.csv')
    df_no_pump = pd.concat([df_layer1, df_layer2])
    df_no_pump.insert(0, 'Point', range(1, len(df_no_pump) + 1))
    value_vars = [col for col in df_no_pump.columns if 'bias' in col]
    df_no_pump = pd.melt(df_no_pump, id_vars=id_vars, value_vars=value_vars, var_name='Iteration', value_name='Bias')
    df_no_pump['Label'] = 'no_pump'
    df_no_pump['Iteration'] = df_no_pump['Iteration'].str.extract('(\d+)').astype(int)
    df_no_pump['Iteration']  = df_no_pump['Iteration'] + df_ss['Iteration'].max()
    
    df_layer2 = pd.read_csv(dataPath / f'tr_with_pump/mf6_post/output_validation/tr_with_pump_s0{solution}_layer2_bias.csv')
    df_layer1 = pd.read_csv(dataPath / f'tr_with_pump/mf6_post/output_validation/tr_with_pump_s0{solution}_layer1_bias.csv')
    df_with_pump = pd.concat([df_layer1, df_layer2])
    df_with_pump.insert(0, 'Point', range(1, len(df_with_pump) + 1))
    value_vars = [col for col in df_with_pump.columns if 'bias' in col]
    df_with_pump = pd.melt(df_with_pump, id_vars=id_vars, value_vars=value_vars, var_name='Iteration', value_name='Bias')
    df_with_pump['Label'] = 'with_pump'
    df_with_pump['Iteration'] = df_with_pump['Iteration'].str.extract('(\d+)').astype(int)
    df_with_pump['Iteration']  = df_with_pump['Iteration'] + df_no_pump['Iteration'].max()
    
    df_combined = pd.concat([df_ss, df_no_pump, df_with_pump])
    avg_obs_gw = df_combined[['avg_obs_gw']].abs()
    df_combined = df_combined.drop(columns=['lat', 'lon', 'sim_gw'])
    avg_obs_gw_column = df_combined.pop('avg_obs_gw')
    df_combined['Bias'] = df_combined['Bias'] * -1
    df_combined.insert(0, 'avg_obs_gw', avg_obs_gw_column)
    df_combined['Bias'] = df_combined['Bias'] / df_combined['avg_obs_gw']
    df_combined['depthCat'] = df_combined['avg_obs_gw'].apply(
        lambda x: '0_5' if x < 5 else (
            '5_10' if 5 <= x < 10 else (
                '10_20' if 10 <= x < 20 else (
                    '20_60' if 20 <= x < 60 else (
                        '>60' if x >= 60 else 'Other'
                    )
                )
            )
        )
    )
    df_combined = df_combined.drop(columns=['avg_obs_gw'])
    mean_bias = df_combined.groupby(['Iteration', 'Label', 'depthCat']).agg({'Bias': 'mean'}).reset_index()
    mean_bias['Solution'] = solution
    if 'mean_bias_final' not in locals():
        mean_bias_final = pd.DataFrame()
    mean_bias_final = pd.concat([mean_bias_final, mean_bias])
    mean_bias_final['Iteration'] = pd.to_numeric(mean_bias_final['Iteration'], errors='coerce')
    
print(mean_bias_final_average)
num_cols, num_rows = 3, 6
fig, axes = plt.subplots(num_rows, num_cols, figsize=(num_cols * 6 , num_rows * 6), sharex=True)
for col_index, solution in enumerate(unique_solutions):
    ax = axes[0, col_index]
    data_sub = mean_bias_final_average[(mean_bias_final_average['Solution'] == solution)]
    print(data_sub)
    sns.lineplot(ax=ax, data=data_sub, x='Iteration', y='Bias', color='black', marker='')
    sns.lineplot(ax=ax, data=data_sub, x='Iteration', y='Bias', hue='Label', marker='o')
    ax.set_title(f'Solution {solution} - Average')

for col_index, solution in enumerate(unique_solutions):
    for row_index, label in enumerate(unique_labels):
        ax = axes[row_index+1, col_index]
        data_sub = mean_bias_final[(mean_bias_final['Solution'] == solution) & (mean_bias_final['depthCat'] == label)]
        sns.lineplot(ax=ax, data=data_sub, x='Iteration', y='Bias', color='black', marker='')
        sns.lineplot(ax=ax, data=data_sub, x='Iteration', y='Bias', hue='Label', marker='o')
        ax.set_title(f'Depth {label}m')
        ax.set_xlabel('Iteration')
    
for col_index, solution in enumerate(unique_solutions):
    for row_index, label in enumerate(unique_labels):
        ax = axes[row_index, col_index]
        if col_index == 0:
            ax.set_ylabel(r'Relative Bias ($\frac{obs-sim}{obs})$')
        else:
            ax.set_ylabel('')
        if row_index == 5:
            ax.set_xlabel('Iteration')
        else:
            ax.set_xlabel('')

plt.tight_layout()
plt.savefig('/home/bvjaarsveld1/projects/workflow/GLOBGM/run_initial_conditions/plots/initial_conditions/_plots/bias_change_relative.png')
plt.close()