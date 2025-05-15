# import xarray as xr
# import zarr

import zipfile
import os
import xarray as xr
import zarr
zip_path='/projects/prjs1222/scratch_backup/globgm_scratch/archive/reference_gswp3-w5e5/annual/hds_reference_gswp3-w5e5_annual_1960_2019.zarr.zip'
store = zarr.ZipStore(zip_path, mode='r')
# ds = xr.open_zarr(store, consolidated=False, group='hds_annual_1960_2014_historical_gfdl-esm4.zarr')
ds = xr.open_zarr(store, consolidated=False)
# ds = ds.isel(time=0).compute()
print(ds)

