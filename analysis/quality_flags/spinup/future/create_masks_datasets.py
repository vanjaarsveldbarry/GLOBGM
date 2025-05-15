import xarray as xr
from pathlib import Path
import numpy as np
import sys

save_dir = Path(sys.argv[1]).parent
start_year = sys.argv[2]
end_year = sys.argv[3]

save_path=save_dir / f'output/{start_year}/spin_up_boolean_{start_year}.nc'

def _read_hds():
    ds_hds = xr.open_dataset(save_dir / f'output/{start_year}/hds_slope.nc')
    _ds_hds_slope = ds_hds['slope']
    _ds_hds_p = ds_hds['p']
    ds_final = xr.where(_ds_hds_p > 0.05, 0, _ds_hds_slope)
    ds_final = xr.where((_ds_hds_p <= 0.05) & (_ds_hds_slope > 0), 1, ds_final)
    ds_final = xr.where((_ds_hds_p <= 0.05) & (_ds_hds_slope < 0), -1, ds_final)
    ds_final = ds_final.fillna(9)
    ds_final = ds_final.to_dataset(name='hds_mask')
    return ds_final

def _read_recharge():
    ds_gwRecharge = xr.open_dataset(save_dir / f'output/{start_year}/gwRecharge_slope.nc')#.reindex(lat=lat, lon=lon, method="nearest")
    _ds_gwRecharge_slope = ds_gwRecharge['slope']
    _ds_gwRecharge_p = ds_gwRecharge['p']
    
    _ds = xr.where(_ds_gwRecharge_p > 0.05, 0, _ds_gwRecharge_slope)
    _ds = xr.where((_ds_gwRecharge_p <= 0.05) & (_ds_gwRecharge_slope > 0), 1, _ds)
    _ds = xr.where((_ds_gwRecharge_p <= 0.05) & (_ds_gwRecharge_slope < 0), -1, _ds)
    _ds = xr.where(ds_final['hds_mask']==9, 9, _ds)
    return _ds

def _read_abstraction():
    lat = ds_final['latitude'].values
    lon = ds_final['longitude'].values
    ds_abstraction1 = xr.open_dataset('/projects/prjs1222/globgm_input/_data/cmip6_input/ipsl-cm6a-lr/historical/pcrglobwb_cmip6-isimip3-ipsl-cm6a-lr_image-aqueduct_historical_totalGroundwaterAbstraction_global_monthly-total_1960_2014_basetier1.nc', chunks='auto')['total_groundwater_abstraction'].chunk({'time': -1})
    ds_abstraction2 = xr.open_dataset('/projects/prjs1222/globgm_input/_data/cmip6_input/ipsl-cm6a-lr/ssp370/pcrglobwb_cmip6-isimip3-ipsl-cm6a-lr_image-aqueduct_ssp370_totalGroundwaterAbstraction_global_monthly-total_2015_2100_basetier1.nc', chunks='auto')['total_groundwater_abstraction'].chunk({'time': -1})
    ds_abstraction = xr.concat([ds_abstraction1, ds_abstraction2], dim='time').sel(time=slice(f'{start_year}-01-01', f'{end_year}-12-31'))
    ds_abstraction = ds_abstraction.resample(time="YE").sum()
    ds_abstraction = ds_abstraction.mean(dim='time')
    ds_abstraction = ds_abstraction.compute()
    ds_abstraction = xr.where(ds_abstraction > 0, 1, 0).rename({"lat": "latitude", "lon": "longitude"}).reindex(latitude=lat, longitude=lon, method="nearest")
    return xr.where(ds_final['hds_mask']==9, 9, ds_abstraction) 
    
ds_final = _read_hds()
ds_final['gwRecharge_mask'] = _read_recharge()
ds_final['abstraction_mask'] = _read_abstraction()


ds_final['latitude'] = ds_final['latitude'].astype(np.float32)
ds_final['longitude'] = ds_final['longitude'].astype(np.float32)
ds_final['hds_mask'] = ds_final['hds_mask'].astype(np.int8)
ds_final['gwRecharge_mask'] = ds_final['gwRecharge_mask'].astype(np.int8)
ds_final['abstraction_mask'] = ds_final['abstraction_mask'].astype(np.int8)
ds_final.to_netcdf(save_path, mode='w')
print(ds_final)