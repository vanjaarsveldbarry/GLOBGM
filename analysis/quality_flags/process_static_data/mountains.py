import xarray as xr
from pathlib import Path
import numpy as np
import sys

data_dir = Path(sys.argv[1])
mountains_ds = xr.open_dataset(data_dir / "dem_standard_deviation_topography_parameters_30sec_february_2021_global_covered_with_zero.nc")
mountains_ds = mountains_ds.rename({"lon": "longitude", "lat": "latitude", "dem_standard_deviation": "mountains"})
mountains_ds = mountains_ds.where(mountains_ds.mountains >= 77)
mountains_ds['mountains'] = xr.where(mountains_ds['mountains'].notnull(), 1, 0)
mountains_ds['mountains'] = mountains_ds['mountains'].astype(np.int8)
mountains_ds['latitude'] = mountains_ds['latitude'].astype(np.float32)
mountains_ds['longitude'] = mountains_ds['longitude'].astype(np.float32)
mountains_ds.attrs = {}
print(mountains_ds)
mountains_ds.to_netcdf(data_dir.parent / "mountains.nc", mode="w")