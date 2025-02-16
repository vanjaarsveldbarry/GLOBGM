import xarray as xr
import cblind as cb
import matplotlib.pyplot as plt
import cartopy.crs as ccrs
import cartopy.io.shapereader as shpreader
from matplotlib.colors import Normalize,LogNorm,PowerNorm
from pathlib import Path
import numpy as np
import matplotlib.colors as mcolors
from matplotlib.ticker import ScalarFormatter
from matplotlib.ticker import MultipleLocator
from matplotlib.ticker import FixedLocator
plt.switch_backend('agg')
from cartopy.mpl.ticker import LongitudeFormatter, LatitudeFormatter
import geopandas as gpd
from tqdm import tqdm
from matplotlib.ticker import FuncFormatter


dataPath = Path('/scratch-shared/globgm_scratch/analysis/cmip6_runs/thiel_sen_slope/data')
savePath = Path('/scratch-shared/globgm_scratch/analysis/cmip6_runs/thiel_sen_slope/plots')
(savePath / 'hotspots').mkdir(exist_ok=True)
(savePath / 'global').mkdir(exist_ok=True)

hotspots=gpd.read_file('/scratch-shared/globgm_scratch/analysis/cmip6_runs/hotspots_trends/data/hotspots_geometry/hotspots.gpkg')
def get_bounding_boxes(hotspots):
    bounding_boxes = {}
    for idx, row in hotspots.iterrows():
        print(row['name'])
        if row['name'] == 'Spain':
            bounding_boxes[row['name']] = (-10, 35, 5.7, 43)
        elif row['name'] == 'Mexico':
            bounding_boxes[row['name']] = (-117, 14.1, -86, 33)
        elif row['name'] == 'California':
            bounding_boxes[row['name']] = (-124.48, 32.53, -114.13, 42.01)
        else:
            bounding_boxes[row['name']] = row.geometry.bounds
    return bounding_boxes

regions = get_bounding_boxes(hotspots)

layer = 2
GCM='ipsl-cm6a-lr'
var='hds'
scenarios=['historical', 'ssp126', 'ssp370', 'ssp585']

# vmin, vmax = -0.002, 0.0002
# vmin, vmax = None, None
cmap = plt.get_cmap("rainbow_r", 250)
norm = None
datasets = [xr.open_dataset(dataPath / f'{GCM}_{scen}_l{layer}_{var}.nc') for scen in scenarios]
for j, region_label in enumerate(tqdm(regions, desc="Processing regions")):
    fig, axs = plt.subplots(1,len(datasets), figsize=(15, 15), subplot_kw={'projection': ccrs.PlateCarree()}, constrained_layout=True)
    region = regions[region_label]
    vmax = datasets[-1]['slope'].quantile(0.90).item()
    if vmax < 0:
        vmax = -vmax
    vmin = -vmax
    norm = mcolors.SymLogNorm(linthresh=0.005, linscale=0.3, vmin=vmin, vmax=vmax, clip=False)
    for i, data in enumerate(datasets):
        ax = axs[i]
        data_sub = data.sel(latitude=slice(region[3], region[1]), longitude=slice(region[0], region[2])).compute()
        data_slope = xr.where(data_sub['p'] < 0.05, data_sub['slope'], np.nan)
        data_background = xr.where(data_sub['p'].notnull(), 1, np.nan)
        data_background.plot(ax=ax, transform=ccrs.PlateCarree(), cmap='binary', norm=None, add_colorbar=False, vmin=vmin, vmax=vmax, alpha=1.0)
        data_slope.plot(ax=ax, transform=ccrs.PlateCarree(), cmap=cmap, norm=norm, add_colorbar=False, vmin=vmin, vmax=vmax)
        ax.set_title(scenarios[i], fontsize=8)

        def format_func(value, tick_number):
            return f'{value:.1f}'
        if i == 0:
            ax.set_xticks(np.arange(region[0], region[1], 5), crs=ccrs.PlateCarree())
            ax.set_xticklabels(np.arange(region[0], region[1], 5), fontsize=8)
            ax.set_yticks(np.arange(region[2], region[3], 5), crs=ccrs.PlateCarree())
            ax.set_yticklabels(np.arange(region[2], region[3], 5), fontsize=8)
            ax.xaxis.set_major_formatter(FuncFormatter(format_func))
            ax.yaxis.set_major_formatter(FuncFormatter(format_func))
        else:
            ax.set_xticks(np.arange(region[0], region[1], 5), crs=ccrs.PlateCarree())
            ax.set_xticklabels(np.arange(region[0], region[1], 5), fontsize=8)
            ax.yaxis.set_major_formatter(FuncFormatter(format_func))
            ax.xaxis.set_major_formatter(FuncFormatter(format_func))

        ax.set_ylabel('')
        ax.set_xlabel('')
        ax.set_extent([region[0], region[2], region[1], region[3]])

    cbar = fig.colorbar(axs[0].collections[1], ax=axs, orientation='vertical', fraction=0.02, pad=0.02, shrink=0.15)
    cbar.set_label('Thiel-Sen Slope')
    cbar.ax.yaxis.set_major_formatter(ScalarFormatter())
    cbar.ax.yaxis.get_offset_text().set_visible(False)
    cbar.ax.tick_params(labelsize=5)
    # ticks = [-2.0, -0.2, -0.02, -0.002, 0, 0.002, 0.02, 0.2, 2.0]
    # cbar.set_ticks(ticks)
    # cbar.set_ticklabels([f'{x:.4f}' for x in ticks], fontsize=5)  # Adjust fontsize as needed
    cbar.ax.minorticks_off()
    plt.savefig(savePath / f'hotspots/zoomed_{GCM}_l{layer}_{var}_{region_label}.png', dpi=600, bbox_inches='tight')
    plt.close(fig)