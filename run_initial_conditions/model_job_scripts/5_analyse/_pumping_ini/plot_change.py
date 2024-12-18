import pandas as pd
from pathlib import Path
import seaborn as sns
import matplotlib.pyplot as plt

dataPath = Path('/scratch-shared/_bvjaarsveld1/output_initial_conditions/gswp3-w5e5/tr_with_pump/mf6_post/output_validation')

mean_bias_solutions_final = pd.DataFrame()

for solution in [1, 2, 3]:
    # Read and preprocess data for layer 2
    df_layer2 = pd.read_csv(dataPath / f'tr_with_pump_s0{solution}_layer2_bias.csv')
    df_layer2 = df_layer2.drop(columns=['lat', 'lon', 'sim_gw', 'avg_obs_gw'])
    df_layer2['Point'] = range(1, len(df_layer2) + 1)
    cols = ['Point'] + [col for col in df_layer2 if col != 'Point']
    df_layer2 = df_layer2[cols]
    df_layer2.columns = df_layer2.columns.str.replace('bias', '')

    # Read and preprocess data for layer 1
    df_layer1 = pd.read_csv(dataPath / f'tr_with_pump_s0{solution}_layer1_bias.csv')
    df_layer1 = df_layer1.drop(columns=['lat', 'lon', 'sim_gw', 'avg_obs_gw'])
    df_layer1['Point'] = range(1, len(df_layer1) + 1)
    cols = ['Point'] + [col for col in df_layer1 if col != 'Point']
    df_layer1 = df_layer1[cols]
    df_layer1.columns = df_layer1.columns.str.replace('bias', '')
    df_combined = pd.concat([df_layer1, df_layer2])
    perc_change = pd.DataFrame()
    for i in range(2, len(df_combined.columns)):
        col_name = df_combined.columns[i]
        prev_col_name = df_combined.columns[i - 1]
        perc_change[f'{col_name}'] = ((df_combined.iloc[:, i] - df_combined.iloc[:, i - 1]) / df_combined.iloc[:, i - 1]) * 100
        perc_change[f'{col_name}'] = perc_change[f'{col_name}'].abs()
    perc_change.insert(0, 'Point', df_combined['Point'])
    
    # Melt the concatenated dataframe
    df_melted = perc_change.melt(id_vars=['Point'], var_name='Iteration', value_name='Bias')
    df_melted['Iteration'] = df_melted['Iteration'].str.extract('(\d+)').astype(int)
    df_melted = df_melted.sort_values(by=['Point', 'Iteration'])
    mean_bias = df_melted.groupby('Iteration')['Bias'].mean().reset_index()

    fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(15, 7))
    
    ylabel=r'Percentage Change (%) $\frac{x_t - x_{t-1}}{x_{t-1}}$ x 100'
    set_xlabel='Iteration'

    sns.lineplot(ax=ax1, data=df_melted, x='Iteration', y='Bias', hue='Point', alpha=0.4,
                linewidth=None, marker=None, legend=False, errorbar=None, palette=['gray'])
    ax1.axhline(0, color='black', linestyle='-', linewidth=1)
    sns.lineplot(ax=ax1, data=mean_bias, x='Iteration', y='Bias', color='red', label='Mean', 
                 errorbar=None, legend=False, linewidth=2)
    
    sns.lineplot(ax=ax2, data=df_melted, x='Iteration', y='Bias', hue='Point', alpha=0.4,
                linewidth=None, marker=None, legend=False, errorbar=None, palette=['gray'])
    ax2.axhline(0, color='black', linestyle='-', linewidth=1)
    sns.lineplot(ax=ax2, data=mean_bias, x='Iteration', y='Bias', color='red', label='Mean', 
                 errorbar=None, linewidth=2, legend=False)
    ax2.set_ylim(0, 5)
    
    sns.lineplot(ax=ax3, data=df_melted, x='Iteration', y='Bias', hue='Point', alpha=0.4,
                linewidth=None, marker=None, legend=False, errorbar=None, palette=['gray'])
    ax3.axhline(0, color='black', linestyle='-', linewidth=1)
    sns.lineplot(ax=ax3, data=mean_bias, x='Iteration', y='Bias', color='red', label='Mean', 
                 errorbar=None, linewidth=2, legend=False)
    ax3.set_ylim(0, 1)
    
    sns.lineplot(ax=ax4, data=df_melted, x='Iteration', y='Bias', hue='Point', alpha=0.4,
                linewidth=None, marker=None, legend=False, errorbar=None, palette=['gray'])
    ax4.axhline(0, color='black', linestyle='-', linewidth=1)
    sns.lineplot(ax=ax4, data=mean_bias, x='Iteration', y='Bias', color='red', label='Mean', 
                 errorbar=None, linewidth=2, legend=False)
    ax4.set_ylim(0, 0.5)

    for ax in [ax1, ax2, ax3, ax4]:
        ax.set_xlabel(set_xlabel)
        ax.set_ylabel(ylabel)
        ax.set_title(f'Solution {solution}')
    plt.tight_layout()
    plt.savefig(f'/scratch-shared/_bvjaarsveld1/_temp/test/test_solution_{solution}.png')
    
    df_combined = df_combined.melt(id_vars=['Point'], var_name='Iteration', value_name='Bias')
    df_combined['Iteration'] = df_combined['Iteration'].str.extract('(\d+)').astype(int)
    
    mean_bias_solutions = df_combined.groupby('Iteration').mean().reset_index()
    mean_bias_solutions = mean_bias_solutions[['Iteration', 'Bias']]
    mean_bias_solutions.columns = ['Iteration', 'Bias']
    mean_bias_solutions['Solution'] = solution
    mean_bias_solutions = mean_bias_solutions[mean_bias_solutions['Iteration'] != 'Point']
    mean_bias_solutions_final = pd.concat([mean_bias_solutions_final, mean_bias_solutions])

mean_bias_solutions_final_wide = mean_bias_solutions_final.pivot(index='Solution', columns='Iteration', values='Bias').reset_index()
fig, axes = plt.subplots(1, 3, figsize=(15, 7))

for i, solution in enumerate(mean_bias_solutions_final_wide['Solution']):
    data_sub=mean_bias_solutions_final_wide[mean_bias_solutions_final_wide['Solution'] == solution].melt(id_vars='Solution', var_name='Iteration', value_name='Bias')
    data_sub['Iteration'] = pd.to_numeric(data_sub['Iteration'], errors='coerce')
    data_sub = data_sub.sort_values(by=['Solution', 'Iteration'])
    sns.lineplot(ax=axes[i], data=data_sub, x='Iteration', y='Bias', marker='o')
    axes[i].set_title(f'Solution {solution}')
    axes[i].set_xlabel('Iteration')
    axes[i].set_ylabel('Mean Bias (sim - obs)')
plt.tight_layout()
plt.savefig('/scratch-shared/_bvjaarsveld1/_temp/test/mean_bias_solutions.png')