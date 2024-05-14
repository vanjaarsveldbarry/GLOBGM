import sys
from pathlib import Path
import xarray as xr
import pandas as pd
import concurrent.futures
import xarray as xr
import warnings
warnings.simplefilter("ignore") 
import time


_chunks={'time': 1, 'latitude': 20000, 'longitude': 20000}

directory = Path(sys.argv[1])
solution=sys.argv[2]
tempDirectory=Path(sys.argv[3]) / f'temp_zarr_{solution}'

zarrSavePath=directory/f'{solution}.zarr'
input_files = sorted(tempDirectory.glob(f'*.zarr'))

def initialise_zarrStore(input_files):
    startDate = f"{input_files[0].stem[4:]}01"
    endDate = f"{input_files[-1].stem[4:]}12"
    time_index = pd.date_range(start=startDate, end=endDate, freq='D')
    ds = xr.open_zarr(input_files[0])
    ds_target=xr.zeros_like(ds).reindex(time=time_index).chunk(_chunks)
    ds_target.to_zarr(zarrSavePath, mode='w', consolidated=True, compute=False)
    
initialise_zarrStore(input_files)

def process_file(index, file):
    ds = xr.open_zarr(file).drop_vars(['latitude', 'longitude']).chunk(_chunks)
    ds.to_zarr(zarrSavePath, region={"time": slice(index, index+1)}, consolidated=True)
    return ds
    
def process_file_with_args(args):
    return process_file(*args)

with concurrent.futures.ProcessPoolExecutor(12) as executor:
    futures = [executor.submit(process_file, i, file) for i, file in enumerate(input_files)]
    results = [f.result() for f in concurrent.futures.as_completed(futures)]