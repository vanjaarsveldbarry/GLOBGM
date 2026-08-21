from pathlib import Path
import pandas as pd
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt
import warnings
import sys

# Silence the PerformanceWarning
warnings.filterwarnings("ignore", category=pd.errors.PerformanceWarning)


pd.set_option('display.max_colwidth', 100)

dataFolder = Path(sys.argv[1])
saveFolder = dataFolder /'plots'
saveFolder.mkdir(parents=True, exist_ok=True)

df_merged = pd.DataFrame()
data_files = sorted((dataFolder).glob('*.csv'))
for file in sorted(data_files):
    data = pd.read_csv(file)['bias']
    name = file.name[13:-4]
    df_merged[name] = data

mean_data = []
for column in df_merged.columns:
    data = df_merged[column].dropna()
    min_value = data.min()
    max_value = data.max()
    mean_value = data.abs().mean()
    percentile_10 = data.quantile(0.1)
    percentile_20 = data.quantile(0.2)
    percentile_30 = data.quantile(0.3)
    percentile_40 = data.quantile(0.4)
    percentile_50 = data.quantile(0.5)
    percentile_60 = data.quantile(0.6)
    percentile_70 = data.quantile(0.7)
    percentile_80 = data.quantile(0.8)
    percentile_90 = data.quantile(0.9)
    mean_data.append({
        'name': column,
        'mean': mean_value,
        'min': min_value,
        'max': max_value,
        '10th_percentile': percentile_10,
        '20th_percentile': percentile_20,
        '30th_percentile': percentile_30,
        '40th_percentile': percentile_40,
        '50th_percentile': percentile_50,
        '60th_percentile': percentile_60,
        '70th_percentile': percentile_70,
        '80th_percentile': percentile_80,
        '90th_percentile': percentile_90,
    })
    
df_mean = pd.DataFrame(mean_data)
df_mean = df_mean.sort_values(by='mean')
top_10_runs_df = df_mean[:10]
with open(saveFolder / 'mean_scores.txt', 'w') as f:
    f.write(top_10_runs_df.to_string(index=False))
plt.figure(figsize=(10, 6))
palette = sns.color_palette("husl", len(df_merged.columns))
for i, column in enumerate(df_merged.columns):
    sns.ecdfplot(data=df_merged, x=column, alpha=0.9, linewidth=2, label=column, color=palette[i])

plt.legend()
plt.xlabel('Bias')
plt.axvline(x=0, color='black', linestyle='--')
plt.ylabel('CDF')
plt.title('CDF for Top 10 Runs')
plt.legend(bbox_to_anchor=(0.53, 0.01), loc='lower left', fontsize='small')
plt.xlim(-100, 100)
plt.savefig(saveFolder / f'bias_plot_100m_limit.png')
plt.xlim(-50, 50)
plt.savefig(saveFolder / f'bias_plot_50m_limit.png')