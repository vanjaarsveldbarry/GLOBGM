import xarray as xr
from pathlib import Path
import sys
from tqdm import tqdm
import gc
dataPath = Path('/projects/prjs1222/globgm_output/cmip6_runs/ensemble')

_scenario=sys.argv[1]
var=sys.argv[2]

savePath_temp=dataPath / f"merged/{_scenario}/_temp{var}.zarr"
savePath=dataPath / f"merged/{_scenario}/{var}.zarr"

ds = xr.open_zarr(savePath_temp)
ds = ds.chunk({'time': 30, 'latitude': 1285, 'longitude': 3323})#.compute()
ds.to_zarr(savePath, mode='w', encoding={f"l1_{var}": {"chunks": (30, 1285, 3323)}, 
                                         f"l2_{var}": {"chunks": (30, 1285, 3323)}}, 
           consolidated=True)