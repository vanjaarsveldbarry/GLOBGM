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
from tqdm import tqdm

dataPath = Path('/scratch-shared/globgm_scratch/analysis/cmip6_runs/thiel_sen_slope/data')
savePath = Path('/scratch-shared/globgm_scratch/analysis/cmip6_runs/thiel_sen_slope/plots')
(savePath / 'hotspots').mkdir(exist_ok=True)
(savePath / 'global').mkdir(exist_ok=True)

layer = 2
GCM='ipsl-cm6a-lr'
var='hds'
# scenarios=['historical', 'ssp126', 'ssp370', 'ssp585']
scenarios=['ssp585']
regions = {
    "cali": [-124, -110, 32, 42],
    "highplains": [-110, -90, 30, 50],
    "ganges": [65., 99, 10, 40],
    
}
vmin, vmax = -2.0, 2.0
# vmin, vmax = -0.002, 0.0002
# vmin, vmax = None, None
cmap = plt.get_cmap("rainbow_r", 250)
norm = mcolors.SymLogNorm(linthresh=0.005, linscale=0.3, vmin=vmin, vmax=vmax, clip=False)
# norm = None
datasets = [xr.open_dataset(dataPath / f'{GCM}_{scen}_l{layer}_{var}.nc') for scen in scenarios]
for i, scen in enumerate(tqdm(scenarios, desc="Processing scenarios")):
    fig = plt.figure(figsize=(5, 7.5))
    ax_global = fig.add_subplot(1, 1, 1, projection=ccrs.Mollweide())
    ax_global.axis('off')
    data = datasets[i].compute()
    data_slope = xr.where(data['p'] < 0.05, data['slope'], np.nan)
    data_background = xr.where(data['p'].notnull(), 1, np.nan)
    print(data)
    data_background.plot(ax=ax_global, transform=ccrs.PlateCarree(), cmap='binary', norm=None, add_colorbar=False, vmin=vmin, vmax=vmax, alpha=1.0)
    img = data_slope.plot(ax=ax_global, transform=ccrs.PlateCarree(), cmap=cmap, norm=norm, add_colorbar=False, vmin=vmin, vmax=vmax)
    cbar = fig.colorbar(img, shrink=0.35, orientation='horizontal', pad=0.01)
    plt.savefig(savePath / f'global/global_{GCM}_{scen}_l{layer}_{var}.png', dpi=300, bbox_inches='tight')
    plt.close(fig)