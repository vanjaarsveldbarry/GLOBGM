import geopandas as gpd
import pandas as pd
import xarray as xr
from pathlib import Path
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt

dataDir = Path(f'/projects/prjs1222/scratch_backup/globgm_scratch/analysis/historical_reference_gswp3-w5e5/validation/output')
saveDir = Path(f'/projects/prjs1222/scratch_backup/globgm_scratch/analysis/historical_reference_gswp3-w5e5/validation/plots')
saveDir.mkdir(parents=True, exist_ok=True)

ds_kge = pd.read_parquet(dataDir / 'kge_wtd.parquet')
# depth_categories = ['<0', '0_5', '5_10', '10_20', '20_60', '>60']
depth_categories = ['0_5', '5_10', '10_20', '20_60', '>60']
custom_palette = ['#0d47a1', '#1f77b4', '#4c8cb5', '#739fc6', '#9ab3d7', '#c1c7e8'][::-1]  # Add a darker color at the beginning
metrics = ['KGE', 'r', 'alpha', 'beta']
titles = {'KGE': 'KGE', 'r': 'Correlation (r)', 'alpha': 'Alpha', 'beta': 'Beta'}

label_font_size = 16

fig, axes = plt.subplots(2, 4, figsize=(24, 16), sharey=False, )
plt.subplots_adjust(wspace=-0.2, hspace=0.0)

# First row: Overall metrics
for ax, metric in zip(axes[0], metrics):
    ax.annotate(f'({chr(97 + metrics.index(metric))})', xy=(0.01, 0.99), 
                xycoords='axes fraction', fontsize=20, ha='left', va='top')
    
    if metric == 'KGE':
        ax.axvline(x=-0.41, color='gray')
        sns.ecdfplot(data=ds_kge, x=metric, ax=ax, color='black', legend=False)
        ax.set_xlim([-2, 1])
        ax.set_ylabel('CDF')
        ax.set_xlabel(' ')
        
    
    elif metric == 'r':
        ax.axvline(x=0.0, color='gray')
        sns.ecdfplot(data=ds_kge, x=metric, ax=ax, color='black', legend=False)
        ax.set_ylabel('CDF')
        ax.set_xlabel(' ')
        
    
    elif metric == 'alpha':
        ax.axhline(y=1.0, color='gray')
        sns.boxplot(data=ds_kge, y=metric, ax=ax, showfliers=False)
        ax.set_ylabel('Alpha')
        ax.set_xlabel(' ')
    
    elif metric == 'beta':
        ax.axhline(y=1.0, color='gray')
        sns.boxplot(data=ds_kge, y=metric, ax=ax, showfliers=False)
        ax.set_ylabel('Beta')
        ax.set_xlabel(' ')
        
    
    # ax.set_xlabel(titles[metric])
    ax.tick_params(axis='both', which='major', labelsize=17)
    ax.xaxis.label.set_size(17)
    ax.yaxis.label.set_size(17)

# Second row: Depth categories
for ax, metric in zip(axes[1], metrics):
    ax.annotate(f'({chr(101 + metrics.index(metric))})', xy=(0.01, 0.99), 
                xycoords='axes fraction', fontsize=20, ha='left', va='top')
    
    if metric == 'KGE':
        ax.axvline(x=-0.41, color='gray')
        for depthCat, color in zip(reversed(depth_categories), reversed(custom_palette)):
            subset = ds_kge[ds_kge['depthCat'] == depthCat]
            sns.ecdfplot(data=subset, x=metric, ax=ax, label=f'{depthCat}m', color=color, legend=False)
            ax.annotate(f'{depthCat}={len(subset["id_gerbil"].unique())}', 
                        xy=(0.95, 0.3 - 0.05 * depth_categories.index(depthCat)), 
                        xycoords='axes fraction', fontsize=10, color=color, ha='right', va='bottom')
        ax.set_xlim([-2, 1])
        ax.set_ylabel('CDF')
        ax.set_xlabel('KGE')
    
    elif metric == 'r':
        ax.axvline(x=0.0, color='gray')
        for depthCat, color in zip(reversed(depth_categories), reversed(custom_palette)):
            subset = ds_kge[ds_kge['depthCat'] == depthCat]
            sns.ecdfplot(data=subset, x=metric, ax=ax, label=f'{depthCat}m', color=color, legend=False)
            ax.annotate(f'{depthCat}={len(subset["id_gerbil"].unique())}', 
                        xy=(0.95, 0.3 - 0.05 * depth_categories.index(depthCat)), 
                        xycoords='axes fraction', fontsize=10, color=color, ha='right', va='bottom')
        ax.set_ylabel('CDF')
        ax.set_xlabel('Correlation (r)')
        
    elif metric == 'alpha':
        ax.axhline(y=1.0, color='gray')
        sns.boxplot(data=ds_kge, x='depthCat', y=metric, ax=ax, 
                    palette=dict(zip(depth_categories, custom_palette)), 
                    order=list(depth_categories), showfliers=False)
        ax.set_ylabel('Alpha')
        ax.set_xlabel('Depth Category (m)')
    
    elif metric == 'beta':
        ax.axhline(y=1.0, color='gray')
        sns.boxplot(data=ds_kge, x='depthCat', y=metric, ax=ax, 
                    palette=dict(zip(depth_categories, custom_palette)), 
                    order=list(depth_categories), showfliers=False)
        ax.set_ylabel('Beta')
        ax.set_xlabel('Depth Category (m)')

    
    ax.tick_params(axis='both', which='major', labelsize=17)
    ax.xaxis.label.set_size(17)
    ax.yaxis.label.set_size(17)

plt.tight_layout()
plt.savefig(saveDir / 'kge_cdf_combined_plot.png', bbox_inches='tight', dpi=600)
plt.close()