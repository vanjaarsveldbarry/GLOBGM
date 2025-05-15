import xarray as xr
import pyinterp
import pyinterp.backends.xarray
import numpy as np
from tqdm import tqdm

savePath = '/projects/prjs1222/scratch_backup/globgm_scratch/analysis/test_correction'

precip_file = '/projects/prjs1222/globgm_input/_data/cmip6_input/gswp3-w5e5/historical/pcrglobwb_cmip6-isimip3-gswp3-w5e5_image-aqueduct_historical-reference_precipitation_global_monthly-total_1960_2019_basetier1.nc'
recharge_file = '/projects/prjs1222/globgm_input/_data/cmip6_input/gswp3-w5e5/historical/pcrglobwb_cmip6-isimip3-gswp3-w5e5_image-aqueduct_historical-reference_gwRecharge_global_monthly-total_1960_2019_basetier1.nc'
correction_file = '/projects/prjs1222/globgm_input/_data/cmip6_input/gswp3-w5e5/historical/gwRecharge_correction_factor.zarr'
def _get_time_index(precip_file):
    ds = xr.open_dataset(precip_file)
    time_index = ds.time.values
    return time_index

grid = xr.open_zarr('/projects/prjs1222/globgm_output/reference_gswp3-w5e5/historical_no_pump/annual/hds.zarr')['l2_hds'].isel(time=0).compute()
cf_ds = xr.open_zarr(correction_file, chunks='auto')['correction_factor'].rename({'lat':'latitude', 'lon':'longitude'}).compute()
cf_ds = cf_ds.reindex({'latitude': grid.latitude, 'longitude': grid.longitude}, method='nearest')
lon = cf_ds.longitude.values
lat = cf_ds.latitude.values
precip_ds = xr.open_dataset(precip_file, chunks='auto')['precipitation'].rename({'lat':'latitude', 'lon':'longitude'})
recharge_ds = xr.open_dataset(recharge_file, chunks='auto')['groundwater_recharge'].rename({'lat':'latitude', 'lon':'longitude'})

combined_ds = xr.Dataset({'precipitation': precip_ds,'groundwater_recharge': recharge_ds})
yearly_savePath_temp = f'{savePath}/gwRecharge_annual.zarr'
for i, (year, _ds_year) in enumerate(tqdm(combined_ds.groupby('time.year'))):
    time_stamp = _ds_year.time.values[-1]
    _ds_year = _ds_year.reindex({'latitude': lat, 'longitude': lon}, method='nearest')
    _ds_year['groundwater_recharge'] = _ds_year['groundwater_recharge'] * cf_ds
    _ds_year['groundwater_recharge'] = xr.where(_ds_year['groundwater_recharge'] > 0, (_ds_year['groundwater_recharge'] - 1e-20), 0)
    _ds_year['groundwater_recharge'] = xr.where(_ds_year['groundwater_recharge'] > _ds_year['precipitation'], _ds_year['precipitation'], _ds_year['groundwater_recharge'])
    _ds_year = _ds_year[['groundwater_recharge']].astype(np.float32)
    _ds_year = _ds_year.sum('time').compute()
    _ds_year = xr.where(grid.notnull(), _ds_year, np.nan)
    _ds_year = _ds_year.assign_coords({'time': time_stamp}).expand_dims('time')
    _ds_year = _ds_year.chunk({'time': 1, 'latitude': 5000, 'longitude': 5000})
    if i == 0:
        _ds_year.to_zarr(yearly_savePath_temp, mode = 'w')
    else:
        _ds_year.to_zarr(yearly_savePath_temp, append_dim='time', mode='a')