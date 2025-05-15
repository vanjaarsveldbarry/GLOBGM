import xarray as xr
from pathlib import Path
import sys
from tqdm import tqdm
import gc
dataPath = Path('/projects/prjs1222/globgm_output/cmip6_runs')

_GCM = sys.argv[1]
_scenario=sys.argv[2]
for var in ['hds', 'wtd']:
    print(f"Processing {_GCM} {_scenario} {var}")
    yearly_savePath=dataPath / f"{_GCM}/{_scenario}/annual/{var}.zarr"
    yearly_savePath_temp=dataPath / f"{_GCM}/{_scenario}/annual/_temp{var}.zarr"
    avg_savePath=dataPath / f"{_GCM}/{_scenario}/avg/{var}.nc"
    
    yearly_savePath.parent.mkdir(parents=True, exist_ok=True)
    avg_savePath.parent.mkdir(parents=True, exist_ok=True)
    
    ds = xr.open_zarr(yearly_savePath_temp)
    ds = ds.chunk({'time': 40, 'latitude': 1285, 'longitude': 3323}).compute()
    ds.to_zarr(yearly_savePath, mode = 'w')