import geopandas as gpd
import pandas as pd
import xarray as xr
from pathlib import Path
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt

dataDir = Path(f'/scratch-shared/_bvjaarsveld1/temp/validation/output')
jarno_kge = pd.read_parquet(dataDir / 'jarno/kge_wtd.parquet')
barry_kge = pd.read_parquet(dataDir / 'barry/kge_wtd.parquet')
common_ids = set(jarno_kge['id_gerbil']).intersection(set(barry_kge['id_gerbil']))
jarno_kge = jarno_kge[jarno_kge['id_gerbil'].isin(common_ids)]
barry_kge = barry_kge[barry_kge['id_gerbil'].isin(common_ids)]


depth_categories = ['0_5', '5_10', '10_20', '20_60', '>60']
fig, axes = plt.subplots(1, 6, figsize=(20, 5), sharey=True)
# First row: Absolute bias
for ax, depthCat in zip(axes[1:], depth_categories):
    sns.ecdfplot(data=jarno_kge[jarno_kge['depthCat'] == depthCat], x='KGE', ax=ax, label='Jarno')
    sns.ecdfplot(data=barry_kge[barry_kge['depthCat'] == depthCat], x='KGE', ax=ax, label='New')
    ax.set_title(f'{depthCat}m')
    ax.set_xlabel('KGE')
    ax.set_ylabel('CDF')    
    ax.set_xlim([-10, 1])
    ax.legend(loc='upper left')

sns.ecdfplot(data=jarno_kge, x='KGE', ax=axes[0], label='Jarno')
sns.ecdfplot(data=barry_kge, x='KGE', ax=axes[0], label='New')
num_points_jarno = len(jarno_kge['id_gerbil'].unique())
num_points_barry = len(barry_kge['id_gerbil'].unique())
axes[0].annotate(f'n={num_points_jarno}', xy=(0.05, 0.25), xycoords='axes fraction', fontsize=12, verticalalignment='top', color='blue')
axes[0].annotate(f'n={num_points_barry}', xy=(0.05, 0.35), xycoords='axes fraction', fontsize=12, verticalalignment='top', color='orange')
axes[0].set_title('All Depths')
axes[0].set_xlabel('KGE')
axes[0].set_ylabel('CDF')
axes[0].set_xlim([-2, 1])
axes[0].legend(loc='upper left')
plt.tight_layout()
plt.savefig('/home/bvjaarsveld1/projects/workflow/GLOBGM/analysis/validation_gswp3-w5e5/plots/kge_cdf_plot.png')