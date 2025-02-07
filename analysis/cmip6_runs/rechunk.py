import zarr
from rechunker import rechunk
from pathlib import Path
from dask.diagnostics import ProgressBar
import xarray as xr

time_bounds = (None, None)

input_path = Path("/scratch-shared/globgm_scratch/temp/dataOrig")
savePath = Path("/scratch-shared/globgm_scratch/temp/data")
savePath.mkdir(exist_ok=True, parents=True)

var = "wtd"
target_chunks = {"time": -1, "latitude": 1000, "longitude": 250}
# for scenario in ["historical", "ssp126", "ssp370", "ssp585"]:
for scenario in ["historical", "ssp126", "ssp370"]:
    #     time_bounds = ("1960-01-01", "1969-12-31")
    # else:
    #     time_bounds = ("2060-01-01", "2069-12-31")

    ds = xr.open_zarr(input_path / f"{scenario}/s03_{var}.zarr").sel(time=slice(time_bounds[0], time_bounds[1])).compute()
    ds = ds.chunk(target_chunks)
    del ds[f'l2_{var}'].encoding['chunks']
    del ds[f'l1_{var}'].encoding['chunks']
    ds.to_zarr(savePath / f"{scenario}/s03_{var}.zarr", mode="w", consolidated=True, 
               encoding={f'l2_{var}': {'chunks': (-1, 1000, 250)}, 
                         f'l1_{var}': {'chunks': (-1, 1000, 250)}})
    print(f"Saved {scenario}")
