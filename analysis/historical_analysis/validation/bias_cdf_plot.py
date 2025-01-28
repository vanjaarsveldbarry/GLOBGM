import geopandas as gpd
import pandas as pd
import xarray as xr
from pathlib import Path
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt

test = 'jarno'
dataDir = Path(f'/scratch-shared/_bvjaarsveld1/temp/validation/output')

jarno_bias = pd.read_parquet(dataDir / 'jarno/mean_bias_wtd.parquet')
barry_bias = pd.read_parquet(dataDir / 'barry/mean_bias_wtd.parquet')
common_ids = set(jarno_bias['id_gerbil']).intersection(set(barry_bias['id_gerbil']))
jarno_bias = jarno_bias[jarno_bias['id_gerbil'].isin(common_ids)]
barry_bias = barry_bias[barry_bias['id_gerbil'].isin(common_ids)]

depth_categories = ['0_5', '5_10', '10_20', '20_60', '>60']
fig, axes = plt.subplots(2, 6, figsize=(24, 10), sharey=True)

# First row: Absolute bias
for ax, depthCat in zip(axes[0, 1:], depth_categories):
    sns.ecdfplot(data=jarno_bias[jarno_bias['depthCat'] == depthCat], x='bias', ax=ax, label='Jarno')
    sns.ecdfplot(data=barry_bias[barry_bias['depthCat'] == depthCat], x='bias', ax=ax, label='New')
    ax.set_title(f'{depthCat}m')
    ax.set_xlabel('Mean Bias (obs - sim)')
    ax.set_ylabel('CDF')    
    ax.set_xlim([-100, 100])
    ax.legend(loc='upper left')

sns.ecdfplot(data=jarno_bias, x='bias', ax=axes[0, 0], label='Jarno')
sns.ecdfplot(data=barry_bias, x='bias', ax=axes[0, 0], label='New')
num_points_jarno = len(jarno_bias)
num_points_barry = len(barry_bias)
axes[0, 0].annotate(f'n={num_points_jarno}', xy=(0.05, 0.25), xycoords='axes fraction', fontsize=12, verticalalignment='top', color='blue')
axes[0, 0].annotate(f'n={num_points_barry}', xy=(0.05, 0.35), xycoords='axes fraction', fontsize=12, verticalalignment='top', color='orange')
axes[0, 0].set_title('All Depths')
axes[0, 0].set_xlabel('Mean Bias (obs - sim)')
axes[0, 0].set_ylabel('CDF')
axes[0, 0].set_xlim([-100, 100])
axes[0, 0].legend(loc='upper left')

# Second row: Relative bias
for ax, depthCat in zip(axes[1, 1:], depth_categories):
    sns.ecdfplot(data=jarno_bias[jarno_bias['depthCat'] == depthCat], x='rel_bias', ax=ax, label='Jarno')
    sns.ecdfplot(data=barry_bias[barry_bias['depthCat'] == depthCat], x='rel_bias', ax=ax, label='New')
    ax.set_xlabel('Mean Relative Bias ($\\frac{obs - sim}{obs}$)')
    ax.set_ylabel('CDF')    
    ax.set_xlim([-10, 5])
    ax.legend(loc='upper left')

sns.ecdfplot(data=jarno_bias, x='rel_bias', ax=axes[1, 0], label='Jarno')
sns.ecdfplot(data=barry_bias, x='rel_bias', ax=axes[1, 0], label='New')
axes[1, 0].annotate(f'n={num_points_jarno}', xy=(0.05, 0.25), xycoords='axes fraction', fontsize=12, verticalalignment='top', color='blue')
axes[1, 0].annotate(f'n={num_points_barry}', xy=(0.05, 0.35), xycoords='axes fraction', fontsize=12, verticalalignment='top', color='orange')
axes[1, 0].set_xlabel('Mean Relative Bias ($\\frac{obs - sim}{obs}$)')
axes[1, 0].set_ylabel('CDF')
axes[1, 0].set_xlim([-10, 5])
axes[1, 0].legend(loc='upper left')


plt.tight_layout()
plt.savefig('/home/bvjaarsveld1/projects/workflow/GLOBGM/analysis/validation_gswp3-w5e5/plots/bias_cdf_plot.png')

