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

_save_dir = Path(sys.argv[1])
_input_dir = Path(sys.argv[2])
var = sys.argv[3]
chunk_info = (6, 1285, 3323)


@timit
def initialise_zarrStore():
    ds = xr.open_zarr(_input_dir/f's04_{var}.zarr')
    ds.to_zarr(_save_dir / f'{var}.zarr', mode='w', safe_chunks=False, compute=False, encoding={f'l1_{var}': {'chunks': chunk_info},
                                                                                                          f'l2_{var}': {'chunks': chunk_info}})

initialise_zarrStore()