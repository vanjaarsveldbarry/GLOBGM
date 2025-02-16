from pathlib import Path
import xarray as xr
import time
import concurrent.futures
import sys
from tqdm import tqdm
import gc

def timit(func):
    def wrapper(*args, **kwargs):
        start_time = time.time()
        result = func(*args, **kwargs)
        end_time = time.time()
        print(f"Function {func.__name__} took {end_time - start_time:.4f} seconds")
        return result
    return wrapper

_temp_dir = Path(sys.argv[1])
GCM = Path(sys.argv[2])
scenario = sys.argv[3]
var = sys.argv[4]
time_chunk = int(sys.argv[5])

chunk_info = (time_chunk, 1285, 3323)

def process_scenario(time_index):
    ds_final = xr.open_zarr(_temp_dir / f'input/s04_{var}.zarr', 
                            overwrite_encoded_chunks=True, 
                            chunks={f'l1_{var}': {'chunks': chunk_info}, 'l2_{var}': {'chunks': chunk_info}})
    ds_final = ds_final.isel(time=slice(time_index, chunk_info[0]+time_index))
    def _process_solution(solution, ds_final):
        ds = xr.open_zarr(_temp_dir / f'input/s0{solution}_{var}.zarr', 
                          overwrite_encoded_chunks=True, 
                          chunks={f'l1_{var}': {'chunks': chunk_info}, 'l2_{var}': {'chunks': chunk_info}})
        ds = ds.isel(time=slice(time_index, chunk_info[0]+time_index))
        ds = ds.reindex(latitude=ds_final.latitude, longitude=ds_final.longitude, method='nearest')
        ds_final = ds_final.combine_first(ds)
        del ds
        gc.collect()
        return ds_final
    
    solutions = [1,2,3]
    for solution in solutions:
        ds_final = _process_solution(solution, ds_final)
    ds_final = ds_final.compute()
    ds_final.drop_vars(['latitude', 'longitude']).to_zarr(_temp_dir / f'output/{var}.zarr', region={"time": slice(time_index, time_index + time_chunk)}, consolidated=True)
    del ds_final
    gc.collect()

def getTimeIndex():
    ds = xr.open_zarr(_temp_dir / f'input/s04_{var}.zarr')
    return ds.time.size

for time_index in tqdm(range(0, getTimeIndex(), time_chunk)):
    process_scenario(time_index)
    gc.collect()