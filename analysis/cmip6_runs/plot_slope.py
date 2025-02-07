import xarray as xr
import cblind as cb
from matplotlib.colors import LogNorm
import matplotlib.pyplot as plt

ds_historical = xr.open_dataset('/scratch-shared/globgm_scratch/temp/data/historical/s03_wtd_medslope.nc')
ds_ssp126 = xr.open_dataset('/scratch-shared/globgm_scratch/temp/data/ssp126/s03_wtd_medslope.nc')
ds_ssp370 = xr.open_dataset('/scratch-shared/globgm_scratch/temp/data/ssp126/s03_wtd_medslope.nc')
ds_ssp585 = xr.open_dataset('/scratch-shared/globgm_scratch/temp/data/ssp585/s03_wtd_medslope.nc')


vmin, vmax = -0.01, 0.01
cmap = cb.cbmap('cb.solstice_r')
norm = None
fig, axes = plt.subplots(2, 2, figsize=(15, 15))
axs = axes.flatten()
im = ds_historical['medslope'].plot(ax=axs[0], cmap=cmap, norm=norm, add_colorbar=False, vmin=vmin, vmax=vmax)
ds_ssp126['medslope'].plot(ax=axs[1], cmap=cmap, norm=norm, add_colorbar=False, vmin=vmin, vmax=vmax)
ds_ssp370['medslope'].plot(ax=axs[2], cmap=cmap, norm=norm, add_colorbar=False, vmin=vmin, vmax=vmax)
ds_ssp585['medslope'].plot(ax=axs[3], cmap=cmap, norm=norm, add_colorbar=False, vmin=vmin, vmax=vmax)
cbar_ax = fig.add_axes([0.15, 0.501, 0.7, 0.01])  # [left, bottom, width, height]
cbar = fig.colorbar(im, cax=cbar_ax, orientation='horizontal')
cbar.set_label('slope')

axs[0].set_title('Historical')
axs[1].set_title('SSP126')
axs[2].set_xlabel('SSP370')
axs[3].set_xlabel('SSP585')

axs[0].set_xlabel(' ')
axs[0].set_xticklabels([])

axs[1].set_xlabel(' ')
axs[1].set_ylabel(' ')
axs[1].set_xticklabels([])

axs[3].set_ylabel(' ')
plt.tight_layout()
plt.savefig(f'/scratch-shared/globgm_scratch/temp/trend_ssp.png', dpi=300)