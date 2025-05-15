import xarray as xr
import numpy as np
import sys 
from pathlib import Path
data_dir = Path(sys.argv[1]).parent

ds_mountains = xr.open_dataset(data_dir / "mountains.nc")
ds_karst = xr.open_dataset(data_dir / "karst.nc")
ds_permafrost = xr.open_dataset(data_dir / "permafrost.nc")

ds_final = ds_mountains.copy().rename({'mountains': 'mountains_qa'})
ds_final['karst_qa'] = ds_karst['karst']
ds_final['permafrost_qa'] = ds_permafrost['permafrost']

ds_final.attrs = {}
ds_final.attrs = {
    "title": "Quality Flags Dataset - GLOBGM",
    "description": "Dataset containing quality flags for mountains, karst, permafrost and regions with known spin up issues.",
    "author": "Barry van Jaarsveld",
}
print(ds_final)
ds_final.to_netcdf(data_dir / 'static_quality_flags.nc', mode = 'w')
