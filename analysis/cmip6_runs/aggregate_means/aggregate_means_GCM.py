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
    
    ds = xr.open_zarr(dataPath / f"{_GCM}/{_scenario}/merged/{var}.zarr")
    
    for i, (year, _ds_year) in enumerate(tqdm(ds.groupby('time.year'), desc=f"Processing {_GCM} {_scenario} {var}")):
        time_stamp = _ds_year.time.values[-1]
        _ds_year = _ds_year.mean('time').compute()
        _ds_year = _ds_year.assign_coords({'time': time_stamp}).expand_dims('time')
        _ds_year = _ds_year.chunk({'time': 1, 'latitude': 1285, 'longitude': 3323})
        if i == 0:
            _ds_year.to_zarr(yearly_savePath_temp, mode = 'w')
        else:
            _ds_year.to_zarr(yearly_savePath_temp, append_dim='time', mode='a')