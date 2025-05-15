import xarray as xr
import numpy as np
import sys
from pathlib import Path

data_dir = Path(sys.argv[1])
grid_ds = xr.open_dataset(data_dir.parent / "mountains.nc")

ds_karst = xr.open_dataset(data_dir / "karst_temp.nc")[['Band1']].rename({'lon': 'longitude', 'lat': 'latitude', 'Band1': 'karst'})
ds_karst.attrs = {}
ds_karst['karst'] = ds_karst['karst'].astype(np.int8)
ds_karst['latitude'] = ds_karst['latitude'].astype(np.float32)
ds_karst['longitude'] = ds_karst['longitude'].astype(np.float32)
ds_karst = ds_karst.reindex_like(grid_ds, method="nearest")
ds_karst.to_netcdf(data_dir.parent / "karst.nc", mode="w")