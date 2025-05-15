import xarray as xr
from pathlib import Path
import sys
from tqdm import tqdm
dataPath = Path('/projects/prjs1222/globgm_output/cmip6_runs')

for scen in ["historical", "ssp126", "ssp370", "ssp585"]:
    for variable in ["wtd", "hds"]:
        ds = xr.open_zarr(dataPath / f"ensemble/annual/{scen}/{variable}.zarr")
        ds = ds.mean(dim='time')
        avg_savePath=dataPath / f"ensemble/avg/{scen}/{variable}.nc"
        avg_savePath.parent.mkdir(parents=True, exist_ok=True)
        ds.to_netcdf(avg_savePath, mode='w')
        print(f"Saved {avg_savePath}")
