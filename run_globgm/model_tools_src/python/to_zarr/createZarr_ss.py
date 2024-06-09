import subprocess
import sys
from pathlib import Path
import shutil
import os
import xarray as xr
from numcodecs import Blosc
import concurrent.futures
import pandas as pd

# Create a compressor
compressor = Blosc(cname='zstd', clevel=5, shuffle=Blosc.SHUFFLE)
_encoding_dict={'dtype': 'float32', '_FillValue': -9999, 'compressor': compressor}
_chunks={'time': 1, 'latitude': 20000, 'longitude': 20000}

inputFolder = sys.argv[1]
solution = sys.argv[2]
saveFolder=sys.argv[3]
input_files = Path(inputFolder).glob(f'*{solution}*.flt')

def process_file(infile):
    savePath=f"{inputFolder}/_temp_{solution}/{solution}/{infile.stem}.zarr"
    if os.path.exists(savePath): shutil.rmtree(savePath)
    Path(savePath).parent.mkdir(parents=True, exist_ok=True)
    command = f"gdal_translate -of ZARR -co COMPRESS=ZSTD -co ZSTD_LEVEL=5 {infile} {savePath}"
    process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE)
    process.wait()

with concurrent.futures.ProcessPoolExecutor() as executor:
    executor.map(process_file, input_files)
    
file=sorted(Path(f"{inputFolder}/_temp_{solution}/{solution}").glob(f'*{solution}*.zarr'))[0]
timeStamp=file.stem[-11:-3]

varName='l1_hds'
l1_ds = xr.open_zarr(f"{inputFolder}/_temp_{solution}/{solution}/{solution}_hds.ss.{timeStamp}_l1.zarr", chunks='auto')
variable_names = list(l1_ds.data_vars.keys())[0]
l1_ds = l1_ds.rename({'X': 'longitude', 'Y': 'latitude', variable_names: varName})
l1_ds = l1_ds.expand_dims({'time': pd.date_range(f"{timeStamp}", periods=1)}).chunk(_chunks)
l1_ds.to_zarr(f"{saveFolder}/{solution}.zarr", mode='w', consolidated=True, encoding={'l1_hds': _encoding_dict})

varName='l2_hds'
l2_ds = xr.open_zarr(f"{inputFolder}/_temp_{solution}/{solution}/{solution}_hds.ss.{timeStamp}_l2.zarr", chunks='auto')
variable_names = list(l2_ds.data_vars.keys())[0]
l2_ds = l2_ds.rename({'X': 'longitude', 'Y': 'latitude', variable_names: varName})
l2_ds = l2_ds.expand_dims({'time': pd.date_range(f"{timeStamp}", periods=1)}).chunk(_chunks)
l2_ds.to_zarr(f"{saveFolder}/{solution}.zarr", mode='a', consolidated=True, encoding={'l2_hds': _encoding_dict})

varName='l1_wtd'
l1_ds = xr.open_zarr(f"{inputFolder}/_temp_{solution}/{solution}/{solution}_wtd.ss.{timeStamp}_l1.zarr", chunks='auto')
variable_names = list(l1_ds.data_vars.keys())[0]
l1_ds = l1_ds.rename({'X': 'longitude', 'Y': 'latitude', variable_names: varName})
l1_ds = l1_ds.expand_dims({'time': pd.date_range(f"{timeStamp}", periods=1)}).chunk(_chunks)
l1_ds.to_zarr(f"{saveFolder}/{solution}.zarr", mode='a', consolidated=True, encoding={'l1_wtd': _encoding_dict})

varName='l2_wtd'
l2_ds = xr.open_zarr(f"{inputFolder}/_temp_{solution}/{solution}/{solution}_wtd.ss.{timeStamp}_l2.zarr", chunks='auto')
variable_names = list(l2_ds.data_vars.keys())[0]
l2_ds = l2_ds.rename({'X': 'longitude', 'Y': 'latitude', variable_names: varName})
l2_ds = l2_ds.expand_dims({'time': pd.date_range(f"{timeStamp}", periods=1)}).chunk(_chunks)
l2_ds.to_zarr(f"{saveFolder}/{solution}.zarr", mode='a', consolidated=True, encoding={'l2_wtd': _encoding_dict})