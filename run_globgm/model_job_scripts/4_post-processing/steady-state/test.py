import xarray as xr

ds = xr.open_zarr('/projects/0/einf4705/workflow/output/gfdl-esm4/ss/mf6_post/s02.zarr')
ds.to_netcdf('/projects/0/einf4705/workflow/output/gfdl-esm4/ss/mf6_post/s02.nc')