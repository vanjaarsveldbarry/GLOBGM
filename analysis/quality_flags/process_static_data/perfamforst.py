import xarray as xr
from pathlib import Path
import numpy as np
import sys

data_dir = Path(sys.argv[1])
grid_ds = xr.open_dataset(data_dir.parent /"mountains.nc")

perma_ds = xr.open_dataset(data_dir / "PZI.nc")
perma_ds = perma_ds.rename({"lon": "longitude", "lat": "latitude", "Band1": "permafrost"})
perma_ds = perma_ds.where(perma_ds.permafrost >= 0.9)
perma_ds['permafrost'] = xr.where(perma_ds['permafrost'].notnull(), 1, 0)
perma_ds['permafrost'] = perma_ds['permafrost'].astype(np.int8)
perma_ds['latitude'] = perma_ds['latitude'].astype(np.float32)
perma_ds['longitude'] = perma_ds['longitude'].astype(np.float32)
perma_ds = perma_ds.reindex_like(grid_ds, method="nearest")
perma_ds.attrs = {}
print(perma_ds)
perma_ds.to_netcdf(data_dir.parent / "permafrost.nc", mode="w")