import xarray as xr


ds = xr.open_zarr('/projects/0/einf4705/workflow/output/gswp3-w5e5/ss/mf6_post/s03.zarr')
ds.to_netcdf('/projects/0/einf4705/workflow/output/gswp3-w5e5/ss/mf6_post/s03.nc', mode='w')

# ds = xr.open_zarr('/projects/0/einf4705/workflow/output/gfdl-esm4/tr_historical/mf6_post/s02_wtd.zarr')
# ds.to_netcdf('/projects/0/einf4705/workflow/output/gfdl-esm4/tr_historical/mf6_post/s02_wtd.nc', mode='w')

# ds = xr.open_zarr('/projects/0/einf4705/workflow/output/gfdl-esm4/tr_historical/mf6_post/s01_wtd.zarr')
# ds.to_netcdf('/projects/0/einf4705/workflow/output/gfdl-esm4/tr_historical/mf6_post/s01_wtd.nc', mode='w')