import xarray as xr
from pathlib import Path
import sys
from tqdm import tqdm
dataPath = Path('/projects/prjs1222/globgm_output/reference_gswp3-w5e5')

_GCM = sys.argv[1]
for var in ['hds', 'wtd']:
    print(f"Processing {_GCM} {var}")
    yearly_savePath=dataPath / f"{_GCM}/annual/{var}.zarr"
    avg_savePath=dataPath / f"{_GCM}/avg/{var}.nc"
    yearly_savePath.parent.mkdir(parents=True, exist_ok=True)
    avg_savePath.parent.mkdir(parents=True, exist_ok=True)
    
    ds = xr.open_zarr(dataPath / f"{_GCM}/merged/{var}.zarr")
    ds = ds.resample(time='YE').mean().compute()
    ds = ds.chunk({'time': -1, 'latitude': 1285, 'longitude': 3323})
    print(ds)
    ds.to_zarr(yearly_savePath, mode = 'w')
    # ds = ds.mean(dim='time')
    # ds.to_netcdf(avg_savePath, mode = 'w')