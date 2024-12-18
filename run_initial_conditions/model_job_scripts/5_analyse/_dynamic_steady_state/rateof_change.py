import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
from sklearn.linear_model import LinearRegression
import numpy as np
from pathlib import Path
from scipy.optimize import curve_fit

inputFolder = Path('/scratch-shared/_bvjaarsveld1/output_initial_conditions/gswp3-w5e5/tr_no_pump/mf6_post')

def sigmoid(x, L, x0, k, b):
    return L / (1 + np.exp(-k * (x - x0))) + b

fig, axes = plt.subplots(nrows=4, ncols=2, figsize=(15, 20))
axes = axes.flatten()
for layer in [1, 2]:
    for idx, solution in enumerate([1, 2, 3, 4]):
        file = inputFolder / f's0{solution}_hds_l{layer}_abs.csv'
        df = pd.read_csv(file)
        df = df.melt(var_name='Iteration', value_name='Value')
        df['Iteration'] = df['Iteration'].str.extract('(\d+)').astype(int)
        
        # Fit sigmoid model
        X = df['Iteration'].values
        y = df['Value'].values
        p0 = [max(y), np.median(X), 1, min(y)]  # initial guesses
        popt, _ = curve_fit(sigmoid, X, y, p0, maxfev=10000)
        
        # Predict next 50 iterations
        future_iterations = np.arange(df['Iteration'].max(), df['Iteration'].max() + 151)
        future_values = sigmoid(future_iterations, *popt)
        
        # Combine original and predicted data
        future_df = pd.DataFrame({'Iteration': future_iterations, 'Value': future_values})
        combined_df = pd.concat([df, future_df])
        
        # Plot data
        col_index = 0 if layer == 1 else 1
        row_index = idx
        sns.lineplot(data=combined_df, x='Iteration', y='Value', marker='o', ax=axes[row_index * 2 + col_index])
        
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
fig.savefig('/scratch-shared/_bvjaarsveld1/_temp/predicted.png')

fig, axes = plt.subplots(nrows=4, ncols=2, figsize=(15, 20))
axes = axes.flatten()
for layer in [1, 2]:
    for idx, solution in enumerate([1, 2, 3, 4]):
        file = inputFolder / f's0{solution}_hds_l{layer}_abs.csv'
        df = pd.read_csv(file)
        df = df.melt(var_name='Iteration', value_name='Value')
        df['Iteration'] = df['Iteration'].str.extract('(\d+)').astype(int)
        
        df['Solution'] = solution

        col_index = 0 if layer == 1 else 1
        row_index = idx
        sns.lineplot(data=df, x='Iteration', y='Value', marker='o', ax=axes[row_index * 2 + col_index])
        
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
        df['Solution'] = solution

        col_index = 0 if layer == 1 else 1
        row_index = idx
        sns.lineplot(data=df, x='Iteration', y='Value', marker='o', ax=axes[row_index * 2 + col_index])
        if solution == 1:title=f'Afro-Eurasia hds Layer {layer}'
        if solution == 2:title=f'Americas hds Layer {layer}'
        if solution == 3:title=f'Australia hds Layer {layer}'
        if solution == 4:title=f'Islands hds Layer {layer}'
        axes[row_index * 2 + col_index].set_title(title)
        if col_index == 0:
            axes[row_index * 2 + col_index].set_ylabel(f'Absolute hds values')
        else:
            axes[row_index * 2 + col_index].set_ylabel('')
fig.tight_layout()
fig.savefig('/scratch-shared/_bvjaarsveld1/_temp/abs_change_plot.png')

fig, axes = plt.subplots(nrows=4, ncols=2, figsize=(15, 20))
axes = axes.flatten()
for layer in [1, 2]:
    for idx, solution in enumerate([1, 2, 3, 4]):
        file = inputFolder / f's0{solution}_hds_l{layer}_abs.csv'
        df = pd.read_csv(file)
        rate_of_change_df = pd.DataFrame()

        for i in range(1, len(df.columns)):
            coli = df.columns[i]
            coli_1 = df.columns[i - 1]
            rate_of_change_df[f'{i}'] = (df[coli] - df[coli_1])

        rate_of_change_df = rate_of_change_df.melt(var_name='Iteration', value_name='Value')
        rate_of_change_df['Solution'] = solution

        col_index = 0 if layer == 1 else 1
        row_index = idx
        sns.lineplot(data=rate_of_change_df, x='Iteration', y='Value', marker='o', ax=axes[row_index * 2 + col_index])
        if solution == 1:title=f'Afro-Eurasia hds Layer {layer}'
        if solution == 2:title=f'Americas hds Layer {layer}'
        if solution == 3:title=f'Australia hds Layer {layer}'
        if solution == 4:title=f'Islands hds Layer {layer}'
        axes[row_index * 2 + col_index].set_title(title)
        if col_index == 0:
           axes[row_index * 2 + col_index].set_ylabel(f'Difference ($x - x_{{-1}}$)')
        else:
            axes[row_index * 2 + col_index].set_ylabel('')
fig.tight_layout()
fig.savefig('/scratch-shared/_bvjaarsveld1/_temp/diff_plot.png')


fig, axes = plt.subplots(nrows=4, ncols=2, figsize=(15, 20))
axes = axes.flatten()
for layer in [1, 2]:
    for idx, solution in enumerate([1, 2, 3, 4]):
        file = inputFolder / f's0{solution}_hds_l{layer}_abs.csv'
        df = pd.read_csv(file)
        rate_of_change_df = pd.DataFrame()

        for i in range(1, len(df.columns)):
            coli = df.columns[i]
            coli_1 = df.columns[i -1]
            rate_of_change_df[f'{i}'] = (df[coli] - df[coli_1]) / (df[coli_1]) 

        rate_of_change_df = rate_of_change_df.melt(var_name='Iteration', value_name='Value')
        rate_of_change_df['Solution'] = solution

        col_index = 0 if layer == 1 else 1
        row_index = idx
        sns.lineplot(data=rate_of_change_df, x='Iteration', y='Value', marker='o', ax=axes[row_index * 2 + col_index])
        if solution == 1:title=f'Afro-Eurasia hds Layer {layer}'
        if solution == 2:title=f'Americas hds Layer {layer}'
        if solution == 3:title=f'Australia hds Layer {layer}'
        if solution == 4:title=f'Islands hds Layer {layer}'
        axes[row_index * 2 + col_index].set_title(title)
        if col_index == 0:
            axes[row_index * 2 + col_index].set_ylabel(f'Rate of Change $\\left( \\frac{{x - x_{{-1}}}}{{x_{{-1}}}} \\right)$')
        else:
            axes[row_index * 2 + col_index].set_ylabel('')
fig.tight_layout()
fig.savefig('/scratch-shared/_bvjaarsveld1/_temp/rate_of_change_plot.png')

fig, axes = plt.subplots(nrows=4, ncols=2, figsize=(15, 20))
axes = axes.flatten()
for layer in [1, 2]:
    for idx, solution in enumerate([1, 2, 3, 4]):
        file = inputFolder / f's0{solution}_hds_l{layer}_abs.csv'
        df = pd.read_csv(file)
        rate_of_change_df = pd.DataFrame()
        for i in range(1, len(df.columns)):
            coli = df.columns[i]
            coli_1 = df.columns[i -1]
            coli_2 = df.columns[i -2]
            rate_of_change_df[f'{i}'] = (df[coli] - df[coli_1]) / (df[coli_1] - df[coli_2]) 

        rate_of_change_df = rate_of_change_df.melt(var_name='Iteration', value_name='Value')
        rate_of_change_df['Solution'] = solution

        col_index = 0 if layer == 1 else 1
        row_index = idx
        sns.lineplot(data=rate_of_change_df, x='Iteration', y='Value', marker='o', ax=axes[row_index * 2 + col_index])
        if solution == 1:title=f'Afro-Eurasia hds Layer {layer}'
        if solution == 2:title=f'Americas hds Layer {layer}'
        if solution == 3:title=f'Australia hds Layer {layer}'
        if solution == 4:title=f'Islands hds Layer {layer}'
        axes[row_index * 2 + col_index].set_title(title)
        if col_index == 0:
            axes[row_index * 2 + col_index].set_ylabel(f'Rate of Change $\\left( \\frac{{x - x_{{-1}}}}{{x_{{-1}} - x_{{-1}}}} \\right)$')
        else:
            axes[row_index * 2 + col_index].set_ylabel('')
fig.tight_layout()
fig.savefig('/scratch-shared/_bvjaarsveld1/_temp/rate_of_change_plot_nikoEdit.png')
