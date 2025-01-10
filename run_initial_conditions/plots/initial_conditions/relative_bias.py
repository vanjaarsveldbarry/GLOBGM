import pandas as pd
from pathlib import Path
import seaborn as sns
import matplotlib.pyplot as plt
import numpy as np 
import math
from sklearn.preprocessing import MaxAbsScaler
import matplotlib.ticker as ticker

dataPath = Path('/scratch-shared/_bvjaarsveld1/output_initial_conditions/gswp3-w5e5/tr_no_pump/mf6_post/output_validation')
unique_solutions = [1, 2, 3]
for solution in [1, 2, 3]:
    df_layer2 = pd.read_csv(dataPath / f'tr_no_pump_s0{solution}_layer2_bias.csv')
    df_layer1 = pd.read_csv(dataPath / f'tr_no_pump_s0{solution}_layer1_bias.csv')
    df_combined = pd.concat([df_layer1, df_layer2])
    df_combined.columns = df_combined.columns.str.replace('bias', '')
    
    avg_obs_gw = df_combined[['avg_obs_gw']].abs()
    df_combined = df_combined.drop(columns=['lat', 'lon', 'sim_gw'])
    avg_obs_gw_column = df_combined.pop('avg_obs_gw')
    df_combined = df_combined * -1
    
    df_combined.insert(0, 'avg_obs_gw', avg_obs_gw_column)
    df_combined.insert(0, 'Point', range(1, len(df_combined) + 1))
    df_combined = df_combined.melt(id_vars=['Point', 'avg_obs_gw'], var_name='Iteration', value_name='Bias')
    df_combined = df_combined.sort_values(by=['Point', 'Iteration'])
    df_combined = df_combined.drop(columns=['avg_obs_gw'])
    mean_bias = df_combined.groupby(['Iteration']).agg({'Bias': 'mean'}).reset_index()
    mean_bias['Solution'] = solution
    if 'mean_bias_final' not in locals():
        mean_bias_final = pd.DataFrame()
    mean_bias_final = pd.concat([mean_bias_final, mean_bias])
    
mean_bias_final['Iteration'] = pd.to_numeric(mean_bias_final['Iteration'], errors='coerce')

# Calculate the number of rows and columns needed
num_cols, num_rows = 3, 1
fig, axes = plt.subplots(num_rows, num_cols, figsize=(6 * num_cols, 6 * num_rows), sharex=True)
axs = axes.flatten()
# Plot each solution and label group in separate subplots
for col_index, solution in enumerate(unique_solutions):
    ax = axes[col_index]
    data_sub = mean_bias_final[(mean_bias_final['Solution'] == solution)]
    sns.lineplot(ax=ax, data=data_sub, x='Iteration', y='Bias', marker='o')
    ax.set_title(f'Solution {solution}')
    ax.set_xlabel('Iteration')
    ax.set_ylabel('Bias')
plt.tight_layout()
plt.savefig('/home/bvjaarsveld1/projects/workflow/GLOBGM/run_initial_conditions/plots/initial_conditions/_plots/relative_bias_change_mean_solution.png')
plt.close()
del mean_bias
del mean_bias_final



unique_solutions = [1, 2, 3]
unique_labels = ['0_5', '5_10', '10_20', '20_60', '>60']
for solution in [1, 2, 3]:
    df_layer2 = pd.read_csv(dataPath / f'tr_no_pump_s0{solution}_layer2_bias.csv')
    df_layer1 = pd.read_csv(dataPath / f'tr_no_pump_s0{solution}_layer1_bias.csv')
    df_combined = pd.concat([df_layer1, df_layer2])
    df_combined.columns = df_combined.columns.str.replace('bias', '')
    
    avg_obs_gw = df_combined[['avg_obs_gw']].abs()
    df_combined = df_combined.drop(columns=['lat', 'lon', 'sim_gw'])
    avg_obs_gw_column = df_combined.pop('avg_obs_gw')
    df_combined = df_combined * -1
    df_combined.insert(0, 'avg_obs_gw', avg_obs_gw_column)
    df_combined.insert(0, 'Point', range(1, len(df_combined) + 1))
    df_combined = df_combined.melt(id_vars=['Point', 'avg_obs_gw'], var_name='Iteration', value_name='Bias')
    df_combined = df_combined.sort_values(by=['Point', 'Iteration'])
    df_combined['Label'] = df_combined['avg_obs_gw'].apply(
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
    mean_bias = df_combined.groupby(['Iteration', 'Label']).agg({'Bias': 'mean'}).reset_index()
    mean_bias['Solution'] = solution
    if 'mean_bias_final' not in locals():
        mean_bias_final = pd.DataFrame()
    mean_bias_final = pd.concat([mean_bias_final, mean_bias])
    
mean_bias_final['Iteration'] = pd.to_numeric(mean_bias_final['Iteration'], errors='coerce')

# Calculate the number of rows and columns needed
num_cols = len(mean_bias_final['Solution'].unique())
num_rows = len(mean_bias_final['Label'].unique())

num_cols, num_rows = 3, 5
fig, axes = plt.subplots(num_rows, num_cols, figsize=(6 * num_cols, 6 * num_rows), sharex=True)

# Plot each solution and label group in separate subplots
for col_index, solution in enumerate(unique_solutions):
    for row_index, label in enumerate(unique_labels):
        ax = axes[row_index, col_index]
        data_sub = mean_bias_final[(mean_bias_final['Solution'] == solution) & (mean_bias_final['Label'] == label)]
        sns.lineplot(ax=ax, data=data_sub, x='Iteration', y='Bias', marker='o')
        ax.set_title(f'Solution {solution} - Label {label}')
        ax.set_xlabel('Iteration')
        ax.set_ylabel('Bias')
plt.tight_layout()
plt.savefig('/home/bvjaarsveld1/projects/workflow/GLOBGM/run_initial_conditions/plots/initial_conditions/_plots/relative_bias_change_mean.png')
plt.close()
del mean_bias
del mean_bias_final

for solution in [1, 2, 3]:
    df_layer2 = pd.read_csv(dataPath / f'tr_no_pump_s0{solution}_layer2_bias.csv')
    df_layer1 = pd.read_csv(dataPath / f'tr_no_pump_s0{solution}_layer1_bias.csv')
    df_combined = pd.concat([df_layer1, df_layer2])
    df_combined.columns = df_combined.columns.str.replace('bias', '')
    
    avg_obs_gw = df_combined[['avg_obs_gw']].abs()
    df_combined = df_combined.drop(columns=['lat', 'lon', 'sim_gw'])
    avg_obs_gw_column = df_combined.pop('avg_obs_gw')
    df_combined = df_combined * -1
    df_combined = df_combined.div(avg_obs_gw.values, axis=0)
    df_combined = df_combined.div(df_combined.shift(axis=1), axis=0)
    df_combined = np.log(df_combined.abs())
    df_combined.insert(0, 'avg_obs_gw', avg_obs_gw_column)
    df_combined.insert(0, 'Point', range(1, len(df_combined) + 1))
    df_combined = df_combined.melt(id_vars=['Point', 'avg_obs_gw'], var_name='Iteration', value_name='Bias')
    df_combined = df_combined.sort_values(by=['Point', 'Iteration'])
    df_combined['Label'] = df_combined['avg_obs_gw'].apply(
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
    mean_bias = df_combined.groupby(['Iteration', 'Label']).agg({'Bias': 'mean'}).reset_index()
    mean_bias['Solution'] = solution
    mean_bias['Iteration'] = pd.to_numeric(mean_bias['Iteration'], errors='coerce')
    if 'mean_bias_final' not in locals():
        mean_bias_final = pd.DataFrame()
    mean_bias_final = pd.concat([mean_bias_final, mean_bias])
    
num_cols = len(mean_bias_final['Solution'].unique())
num_rows = len(mean_bias_final['Label'].unique())

num_cols, num_rows = 3, 5
fig, axes = plt.subplots(num_rows, num_cols, figsize=(6 * num_cols, 6 * num_rows), sharex=True)
for col_index, solution in enumerate(unique_solutions):
    for row_index, label in enumerate(unique_labels):
        ax = axes[row_index, col_index]
        data_sub = mean_bias_final[(mean_bias_final['Solution'] == solution) & (mean_bias_final['Label'] == label)]
        sns.lineplot(ax=ax, data=data_sub, x='Iteration', y='Bias', marker='o')
        ax.set_title(f'Solution {solution} - Label {label}')
        ax.set_xlabel('Iteration')
        ax.set_ylabel('Bias')
        ax.set_ylim(-0.002, 0.002)
plt.tight_layout()
plt.savefig('/home/bvjaarsveld1/projects/workflow/GLOBGM/run_initial_conditions/plots/initial_conditions/_plots/relative_bias_change_ratio.png')
del mean_bias_final