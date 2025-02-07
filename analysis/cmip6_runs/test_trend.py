import xarray as xr 
import seaborn as sns
import matplotlib.pyplot as plt
import pandas as pd
import cblind as cb
from matplotlib.colors import LogNorm

time_bounds = (None, None)
lon_bounds = (None, None)
lat_bounds = (None, None) 
vmin, vmax = None, None
norm = None

# lat_bounds = (-29.0, -10.0)
# lon_bounds = (138.0, 154.0)
time_bounds = ('2015-01-31', '2015-03-31')
solution = 3

chunks = {'time': -1, 'latitude': -1, 'longitude': 500}
var='wtd'

# vmin, vmax = -100, 100
vmin, vmax = 0.0, 50
cmap = cb.cbmap('cb.extreme_rainbow')
# norm = LogNorm(vmin=vmin, vmax=vmax)
fig, axes = plt.subplots(1, 3, figsize=(15, 5))
def get_trend(sim):
    ds = xr.open_zarr(f'/scratch-shared/globgm_scratch/temp/data/{sim}/s0{solution}_{var}.zarr', chunks=chunks)
    print(ds)
    ds = ds.sel(latitude=slice(lat_bounds[1], lat_bounds[0]), longitude=slice(lon_bounds[0], lon_bounds[1]))
    ds = ds.mean(dim='time').compute()
    ds[f'l2_{var}'] = xr.where(ds[f'l1_{var}'].notnull(), ds[f'l1_{var}'], ds[f'l2_{var}'])
    return ds

ds_hist = get_trend('historical')
ds_ssp126 = get_trend('ssp126')
ds_ssp370 = get_trend('ssp370')
ds_ssp585 = get_trend('ssp585')

im = ds_ssp126[f'l2_{var}'].plot(ax=axes[0], cmap=cmap, norm=norm, add_colorbar=False, vmin=vmin, vmax=vmax)
ds_ssp370[f'l2_{var}'].plot(ax=axes[1], cmap=cmap, norm=norm, add_colorbar=False, vmin=vmin, vmax=vmax)
ds_ssp585[f'l2_{var}'].plot(ax=axes[2], cmap=cmap, norm=norm, add_colorbar=False, vmin=vmin, vmax=vmax)

cbar = fig.colorbar(im, ax=axes, orientation='horizontal', fraction=0.05, pad=-0.15)
cbar.set_label('WTD')

axes[0].set_title('SSP 126: 2060-2070')
axes[1].set_title('SSP 379: 2060-2070')
axes[2].set_title('SSP 585: 2060-2070')

axes[0].set_xlabel('Longitude')
axes[1].set_xlabel('Longitude')
axes[2].set_xlabel('Longitude')

axes[0].set_xlabel('Latitude')
axes[1].set_ylabel(' ')
axes[2].set_ylabel(' ')

axes[1].set_yticklabels([])
axes[2].set_yticklabels([])


plt.tight_layout()
plt.savefig(f'/scratch-shared/globgm_scratch/temp/test_trend.png', dpi=300)