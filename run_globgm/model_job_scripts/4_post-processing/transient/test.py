import xarray as xr

ds = xr.open_zarr('/projects/0/einf4705/workflow/output/gfdl-esm4/tr_historical/mf6_post/s03_wtd.zarr')
ds.to_netcdf('/projects/0/einf4705/workflow/output/gfdl-esm4/tr_historical/mf6_post/s03_wtd.nc', mode='w')