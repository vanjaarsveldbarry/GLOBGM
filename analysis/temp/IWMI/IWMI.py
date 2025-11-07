import xarray as xr

# ds = xr.open_zarr('/projects/prjs1222/globgm_output/_backup/historical_with_pump/gswp3-w5e5/forcing_input/discharge.zarr')
# ds = ds.sel(lat=slice(-10, -44), lon=slice(112, 154))
# ds = ds.chunk({'time': 1, 'lat': -1, 'lon': -1})
# ds.attrs = {}
# ds = ds.compute()
# print(ds)
# comp = dict(zlib=True, complevel=5)
# encoding = {var: comp for var in ds.data_vars}
# ds.to_netcdf('/projects/prjs1222/GLOBGM/analysis/temp/IWMI/human_pcrglobwb_discharge.nc', encoding=encoding)
# print('done')   


ds = xr.open_zarr('/projects/prjs1222/globgm_output/_backup/historical_no_pump/gswp3-w5e5/forcing_input/discharge.zarr')
ds = ds.sel(lat=slice(-10, -44), lon=slice(112, 154))
ds = ds.chunk({'time': 1, 'lat': -1, 'lon': -1})
ds.attrs = {}
ds = ds.compute()
print(ds)
comp = dict(zlib=True, complevel=5)
encoding = {var: comp for var in ds.data_vars}
ds.to_netcdf('/projects/prjs1222/GLOBGM/analysis/temp/IWMI/natural_pcrglobwb_discharge.nc', encoding=encoding)
print('done')   
