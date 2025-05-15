import xarray as xr
import numpy as np
from tqdm import tqdm
from pathlib import Path

grid = xr.open_zarr('/projects/prjs1222/globgm_output/reference_gswp3-w5e5/historical_with_pump/annual/hds.zarr')['l2_hds'].isel(time=0).chunk({'latitude': 2000, 'longitude': 2000})

data_path = Path('/scratch-shared/globgm_nicole/historical_with_pump/forcing_input/historical_with_pump/gswp3-w5e5/forcing_input')
yearly_savePath_temp = data_path / 'gwRecharge_annual.zarr'

#Nothing: 1:08 -- compute: 41 chunk:
cf_ds = xr.open_zarr(data_path / 'gwRecharge_correction_factor.zarr', chunks='auto')['correction_factor'].rename({'lat':'latitude', 'lon':'longitude'})
cf_ds = cf_ds.reindex({'latitude': grid.latitude, 'longitude': grid.longitude}, method='nearest').chunk({'latitude': 2000, 'longitude': 2000})

lon, lat  = cf_ds.longitude.values, cf_ds.latitude.values

def _read_recharge():
    ds_recharge = xr.open_zarr(data_path / 'gwRecharge.zarr', chunks='auto')['gwRecharge']
    ds_recharge = ds_recharge.rename({'lat':'latitude', 'lon':'longitude'})
    ds_recharge = ds_recharge.reindex({'latitude': grid.latitude, 'longitude': grid.longitude}, method='nearest')
    return ds_recharge.chunk({'time': 12, 'latitude': 2000, 'longitude': 2000})

def _read_precip():
    ds_precip = xr.open_dataset(data_path / 'precipitation.nc', chunks='auto')['precipitation']
    ds_precip = ds_precip.rename({'lat':'latitude', 'lon':'longitude'})
    ds_precip = ds_precip.reindex({'latitude': grid.latitude, 'longitude': grid.longitude}, method='nearest')
    return ds_precip.chunk({'time': 12, 'latitude': 2000, 'longitude': 2000})

ds_recharge =_read_recharge()
ds_precip =_read_precip()
#1:08
combined_ds = xr.Dataset({'precipitation': ds_precip,'groundwater_recharge': ds_recharge})
print(combined_ds)
for i, (year, _ds_year) in enumerate(tqdm(combined_ds.groupby('time.year'), disable=False)):
    time_stamp = _ds_year.time.values[-1]
    _ds_year['groundwater_recharge'] = _ds_year['groundwater_recharge'] * cf_ds
    _ds_year['groundwater_recharge'] = xr.where(_ds_year['groundwater_recharge'] > 0, (_ds_year['groundwater_recharge'] - 1e-20), 0)
    _ds_year['groundwater_recharge'] = xr.where(_ds_year['groundwater_recharge'] > _ds_year['precipitation'], _ds_year['precipitation'], _ds_year['groundwater_recharge'])
    _ds_year['groundwater_recharge'] = xr.where(_ds_year['groundwater_recharge'] < 0, 0, _ds_year['groundwater_recharge'])
    _ds_year = _ds_year.astype(np.float32)
    _ds_year = _ds_year.sum('time')
    _ds_year = xr.where(grid.notnull(), _ds_year['groundwater_recharge'], np.nan)
    _ds_year = _ds_year.assign_coords({'time': time_stamp}).expand_dims('time')
    if i == 0:
        _ds_year.to_zarr(yearly_savePath_temp, mode = 'w')
    else:
        _ds_year.to_zarr(yearly_savePath_temp, append_dim='time', mode='a')