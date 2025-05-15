from pathlib import Path
import xarray as xr
import time
import concurrent.futures
import sys
from tqdm import tqdm
import gc
from concurrent.futures import ProcessPoolExecutor, as_completed

def timit(func):
    def wrapper(*args, **kwargs):
        start_time = time.time()
        result = func(*args, **kwargs)
        end_time = time.time()
        print(f"Function {func.__name__} took {end_time - start_time:.4f} seconds")
        return result
    return wrapper

_save_dir = Path(sys.argv[1])
input_dir = Path(sys.argv[2])
var = sys.argv[3]
time_chunk = 6

chunk_info = (time_chunk, 1285, 3323)

def process_scenario(time_index, resolution):
    ds_final = xr.open_zarr(input_dir / f's04_{var}.zarr', 
                            overwrite_encoded_chunks=True, 
                            chunks={f'l1_{var}': {'chunks': chunk_info}, 'l2_{var}': {'chunks': chunk_info}})
    ds_final = ds_final.isel(time=slice(time_index, chunk_info[0]+time_index))
    def _process_solution(solution, ds_final):
        ds = xr.open_zarr(input_dir / f's0{solution}_{var}.zarr', 
                          overwrite_encoded_chunks=True, 
                          chunks={f'l1_{var}': {'chunks': chunk_info}, 'l2_{var}': {'chunks': chunk_info}})
        ds = ds.isel(time=slice(time_index, chunk_info[0]+time_index))
        ds = ds.reindex(latitude=ds_final.latitude, longitude=ds_final.longitude, method='nearest', tolerance=resolution)
        ds_final = ds_final.combine_first(ds)
        del ds
        gc.collect()
        return ds_final
    
    solutions = [1,2,3]
    for solution in solutions:
        ds_final = _process_solution(solution, ds_final)
    ds_final = ds_final.compute()
    ds_final.drop_vars(['latitude', 'longitude']).to_zarr(_save_dir / f'{var}.zarr', region={"time": slice(time_index, time_index + time_chunk)}, consolidated=True)
    del ds_final
    gc.collect()

def getTimeIndex():
    ds = xr.open_zarr(input_dir / f's04_{var}.zarr')
    return ds.time.size

def getSpatialResolution():
    ds = xr.open_zarr(input_dir / f's04_{var}.zarr')
    resolution = ds.latitude.values[0] - ds.latitude.values[1]
    return resolution
resolution = getSpatialResolution()

for time_index in tqdm(range(0, getTimeIndex(), time_chunk), desc=f'Processing time {var}'):
    process_scenario(time_index,resolution)
    gc.collect()
