import xarray as xr
from pathlib import Path

save_dir = Path('/projects/prjs1222/scratch_backup/globgm_scratch/analysis/test_correction')
save_dir.mkdir(parents=True, exist_ok=True)

ds_5arcmin = xr.open_dataset('/projects/prjs1222/globgm_input/_data/cmip6_input/gswp3-w5e5/historical/pcrglobwb_cmip6-isimip3-gswp3-w5e5_image-aqueduct_historical-reference_gwRecharge_global_monthly-total_1960_2019_basetier1.nc', chunks='auto')
# ds_5arcmin = ds_5arcmin.resample(time='YE').sum(dim='time').compute()
# print('one')
# ds_5arcmin = ds_5arcmin.mean(dim='time')
# print('two')
# ds_5arcmin.to_netcdf(save_dir / '5arcmin_longterm_mean.nc')
# print(ds_5arcmin)

ds_30sec = xr.open_dataset('/projects/prjs1222/scratch_backup/globgm_scratch/analysis/test_correction/gwRecharge_annual.zarr')
ds_30sec = ds_30sec.mean(dim='time')
print('one')
ds_30sec = ds_30sec.rename({'latitude': 'lat', 'longitude': 'lon'})
ds_30sec = ds_30sec.coarsen(lat=10, lon=10, boundary='trim').mean()
print('two')
ds_30sec = ds_30sec.reindex({'lat': ds_5arcmin.lat, 'lon': ds_5arcmin.lon}, method='nearest')
print('three')
ds_30sec.to_netcdf(save_dir / '30sec_longterm_mean.nc')
print(ds_30sec)