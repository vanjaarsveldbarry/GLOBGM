# import os 
# import numpy as np
# import numba
# from numba import njit, prange
# from numba_progress import ProgressBar
# from pathlib import Path
# from tqdm import tqdm
# from numba import guvectorize, float64, int64
# from scipy.stats import theilslopes
# from dask.distributed import Client, LocalCluster


from pathlib import Path
import xarray as xr
import time
import concurrent.futures
import sys

def timit(func):
    def wrapper(*args, **kwargs):
        start_time = time.time()
        result = func(*args, **kwargs)
        end_time = time.time()
        print(f"Function {func.__name__} took {end_time - start_time:.4f} seconds")
        return result
    return wrapper

_temp_dir = Path(sys.argv[1])
var = sys.argv[2]
time_chunk = int(sys.argv[3])
chunk_info = (time_chunk, 1285, 3323)


@timit
def initialise_zarrStore():
    ds = xr.open_zarr(_temp_dir/f'input/s04_{var}.zarr')
    print(ds)
    ds.to_zarr(_temp_dir / f'output/{var}.zarr', mode='w', safe_chunks=False, compute=False, encoding={f'l1_{var}': {'chunks': chunk_info},
                                                                                                          f'l2_{var}': {'chunks': chunk_info}})

initialise_zarrStore()