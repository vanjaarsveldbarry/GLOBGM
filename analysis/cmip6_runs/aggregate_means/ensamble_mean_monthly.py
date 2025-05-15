import xarray as xr
from pathlib import Path
import sys
from tqdm import tqdm
dataPath = Path('/projects/prjs1222/globgm_output/cmip6_runs')
avg_savePath= dataPath / "ensemble"

_scenario = sys.argv[1]
var = sys.argv[2]

GCMs=["gfdl-esm4", "mpi-esm1-2-hr", "mri-esm2-0", "ukesm1-0-ll", "ipsl-cm6a-lr"]
savePath_temp=dataPath / f"ensemble/merged/{_scenario}/_temp{var}.zarr"
savePath=dataPath / f"ensemble/merged/{_scenario}/{var}.zarr"
savePath.parent.mkdir(parents=True, exist_ok=True)
time_index = xr.open_zarr(dataPath / f"{GCMs[0]}/{_scenario}/merged/{var}.zarr").indexes['time']

for i, time in enumerate(tqdm(time_index, desc=f"Processing {_scenario} {var}")):
    ds1 = xr.open_zarr(dataPath / f"{GCMs[0]}/{_scenario}/merged/{var}.zarr").sel(time=time)
    ds2 = xr.open_zarr(dataPath / f"{GCMs[1]}/{_scenario}/merged/{var}.zarr").sel(time=time)
    ds3 = xr.open_zarr(dataPath / f"{GCMs[2]}/{_scenario}/merged/{var}.zarr").sel(time=time)
    ds4 = xr.open_zarr(dataPath / f"{GCMs[3]}/{_scenario}/merged/{var}.zarr").sel(time=time)
    ds5 = xr.open_zarr(dataPath / f"{GCMs[4]}/{_scenario}/merged/{var}.zarr").sel(time=time)
    
    ds_mean = xr.concat([ds1, ds2, ds3, ds4, ds5], dim='model')
    ds_mean = ds_mean.mean(dim='model')
    ds_mean = ds_mean.expand_dims('time')
    ds_mean = ds_mean.chunk({'time': 1, 'latitude': 1285, 'longitude': 3323})
    if i == 0:
        ds_mean.to_zarr(savePath_temp, mode='w')
    else:
        ds_mean.to_zarr(savePath_temp, mode='a', append_dim='time')
