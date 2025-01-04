import pandas as pd
from pathlib import Path
import seaborn as sns
import matplotlib.pyplot as plt
import numpy as np 

dataPath = Path('/scratch-shared/_bvjaarsveld1/output_initial_conditions/gswp3-w5e5/tr_with_pump/mf6_post/output_validation')

mean_bias_solutions_final_median = pd.DataFrame()
mean_bias_solutions_final_mean = pd.DataFrame()

for solution in [1, 2, 3]:
    df_layer2 = pd.read_csv(dataPath / f'tr_with_pump_s0{solution}_layer2_bias.csv')

    # Read and preprocess data for layer 1
    df_layer1 = pd.read_csv(dataPath / f'tr_with_pump_s0{solution}_layer1_bias.csv')
    df_combined = pd.concat([df_layer1, df_layer2])
    df_combined.columns = df_combined.columns.str.replace('bias', '')
    avg_obs_gw = df_combined[['avg_obs_gw']].abs()
    cols_to_drop = ['lat', 'lon', 'sim_gw', 'avg_obs_gw']
    df_combined = df_combined.drop(columns=cols_to_drop)
    df_combined = df_combined.div(avg_obs_gw.values, axis=0)
    df_combined.insert(0, 'Point', range(1, len(df_combined) + 1))
    df_combined = df_combined.melt(id_vars=['Point'], var_name='Iteration', value_name='Bias')
    df_combined['Iteration'] = df_combined['Iteration'].str.extract('(\d+)').astype(int)
    df_combined = df_combined.sort_values(by=['Point', 'Iteration'])
    
    mean_bias_solutions_median = df_combined.groupby('Iteration').median().reset_index()
    mean_bias_solutions_median = mean_bias_solutions_median[['Iteration', 'Bias']]
    mean_bias_solutions_median.columns = ['Iteration', 'Bias']
    mean_bias_solutions_median['Solution'] = solution
    mean_bias_solutions_median = mean_bias_solutions_median[mean_bias_solutions_median['Iteration'] != 'Point']
    mean_bias_solutions_final_median = pd.concat([mean_bias_solutions_final_median, mean_bias_solutions_median])
    
    mean_bias_solutions_mean = df_combined.groupby('Iteration').mean().reset_index()
    mean_bias_solutions_mean = mean_bias_solutions_mean[['Iteration', 'Bias']]
    mean_bias_solutions_mean.columns = ['Iteration', 'Bias']
    mean_bias_solutions_mean['Solution'] = solution
    mean_bias_solutions_mean = mean_bias_solutions_mean[mean_bias_solutions_mean['Iteration'] != 'Point']
    mean_bias_solutions_final_mean = pd.concat([mean_bias_solutions_final_mean, mean_bias_solutions_mean])

mean_bias_solutions_final_median_wide = mean_bias_solutions_final_median.pivot(index='Solution', columns='Iteration', values='Bias').reset_index()
mean_bias_solutions_final_mean_wide = mean_bias_solutions_final_mean.pivot(index='Solution', columns='Iteration', values='Bias').reset_index()

fig, axes = plt.subplots(2, 3, figsize=(18, 12))

for i, solution in enumerate(mean_bias_solutions_final_median_wide['Solution']):
    data_sub_median = mean_bias_solutions_final_median_wide[mean_bias_solutions_final_median_wide['Solution'] == solution].melt(id_vars='Solution', var_name='Iteration', value_name='Bias')
    data_sub_median['Iteration'] = pd.to_numeric(data_sub_median['Iteration'], errors='coerce')
    data_sub_median = data_sub_median.sort_values(by=['Solution', 'Iteration'])
    sns.lineplot(ax=axes[0, i], data=data_sub_median, x='Iteration', y='Bias', marker='o')
    axes[0, i].set_title(f'Solution {solution}')
    axes[0, i].set_xlabel('Iteration')
    axes[0, i].set_ylabel('Median Relative Bias (sim - obs) / obs')

for i, solution in enumerate(mean_bias_solutions_final_mean_wide['Solution']):
    data_sub_mean = mean_bias_solutions_final_mean_wide[mean_bias_solutions_final_mean_wide['Solution'] == solution].melt(id_vars='Solution', var_name='Iteration', value_name='Bias')
    data_sub_mean['Iteration'] = pd.to_numeric(data_sub_mean['Iteration'], errors='coerce')
    data_sub_mean = data_sub_mean.sort_values(by=['Solution', 'Iteration'])
    sns.lineplot(ax=axes[1, i], data=data_sub_mean, x='Iteration', y='Bias', marker='o')
    axes[1, i].set_title(f'Solution {solution}')
    axes[1, i].set_xlabel('Iteration')
    axes[1, i].set_ylabel('Mean Relative Bias (sim - obs) / obs')

plt.tight_layout()
plt.savefig('/scratch-shared/_bvjaarsveld1/_temp/test/mean_median_relative_bias_solutions.png')


bias_depth = pd.DataFrame()
for solution in [1, 2, 3]:
    df_layer2 = pd.read_csv(dataPath / f'tr_with_pump_s0{solution}_layer2_bias.csv')

    # Read and preprocess data for layer 1
    df_layer1 = pd.read_csv(dataPath / f'tr_with_pump_s0{solution}_layer1_bias.csv')
    df_combined = pd.concat([df_layer1, df_layer2])
    df_combined.columns = df_combined.columns.str.replace('bias', '')
    df_combined = df_combined[['avg_obs_gw', '43']]
    df_combined['Solution'] = solution
    bias_depth = pd.concat([bias_depth, df_combined])
    
fig, axes = plt.subplots(2, 3, figsize=(18, 12), sharey=False)

for i, solution in enumerate(bias_depth['Solution'].unique()):
    data = bias_depth[bias_depth['Solution'] == solution]
    data['rel_bias'] = data['43'] / data['avg_obs_gw']
    
    # Plot absolute data on the first row
    ax = axes[0, i]
    sns.scatterplot(data=data, x='avg_obs_gw', y='43', hue='Solution', palette='deep', ax=ax)
    ax.set_xlabel('Observed Groundwater')
    ax.set_ylabel('Absolute Bias (sim - obs)')
    ax.set_title(f'Solution {solution}')
    ax.legend(title='Solution')
    y_min, y_max = (data['43'].min()-5), (data['43'].max() + 5)
    ax.set_ylim(y_min, y_max)
    
    # Plot relative data on the second row
    ax = axes[1, i]
    sns.scatterplot(data=data, x='avg_obs_gw', y='rel_bias', hue='Solution', palette='muted', ax=ax, marker='x')
    ax.set_xlabel('Observed Groundwater')
    ax.set_ylabel('Relative Bias (sim - obs) / obs')
    ax.set_title(f'Solution {solution}')
    ax.legend(title='Solution')
    # y_min, y_max = (data['rel_bias'].min())-1, (data['rel_bias'].max()+1)
    y_min, y_max = (-2, 2)
    ax.set_ylim(y_min, y_max)

plt.tight_layout()
plt.savefig('/scratch-shared/_bvjaarsveld1/_temp/test/scatter_avg_obs_gw_vs_sim.png')