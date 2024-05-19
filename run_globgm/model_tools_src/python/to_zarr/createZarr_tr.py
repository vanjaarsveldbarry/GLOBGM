import xarray as xr
import sys
from pathlib import Path
from numcodecs import Blosc
import pandas as pd
from tqdm import tqdm
import os
import subprocess
import shutil
import concurrent.futures


directory = Path(sys.argv[1])
year=sys.argv[2]
solution=sys.argv[3]
tempDir=Path(sys.argv[4])

mf6_postDir = directory.parent / 'mf6_post'
tempDirectory=tempDir / f'temp_zarr_{solution}/_temp_{year}'
tempDirectory.mkdir(parents=True, exist_ok=True)
zarrSavePath=tempDirectory.parent
zarrSavePath.mkdir(parents=True, exist_ok=True)
compressor = Blosc(cname='zstd', clevel=5, shuffle=Blosc.BITSHUFFLE)
_encoding_dict={'dtype': 'float32', '_FillValue': -9999, 'compressor': compressor}
_chunks={'time': 1, 'latitude': 20000, 'longitude': 20000}
# Convert .flt to zarr#
def convert_file(infile):
    savePath=f"{tempDirectory}/{infile.stem}.zarr"
    if os.path.exists(savePath): shutil.rmtree(savePath)
    command = f"gdal_translate -of ZARR {infile} {savePath}"
    process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE)
    process.wait()

input_files = sorted(Path(mf6_postDir).glob(f'*{solution}*{year}*.flt'))
with concurrent.futures.ProcessPoolExecutor(48) as executor:
    futures = {executor.submit(convert_file, file) for file in input_files}
    results = [f.result() for f in concurrent.futures.as_completed(futures)]

def merge_variables(month):
    timeStamp = f'{year}{month:02d}'
    varName='l1_hds'
    file=sorted(Path(tempDirectory).glob(f'*{solution}*hds*{timeStamp}*_l1*.zarr'))[0]
    l1_ds = xr.open_zarr(file, chunks='auto')
    variable_names = list(l1_ds.data_vars.keys())[0]
    l1_ds = l1_ds.rename({'X': 'longitude', 'Y': 'latitude', variable_names: varName})
    l1_ds = l1_ds.expand_dims({'time': pd.date_range(f"{timeStamp}01", periods=1)}).chunk(_chunks)
    l1_ds.to_zarr(zarrSavePath / f"{solution}_{timeStamp.zarr", mode='w', consolidated=True, encoding={'l1_hds': _encoding_dict})
    shutil.rmtree(file)

    varName='l2_hds'
    file=sorted(Path(tempDirectory).glob(f'*{solution}*hds*{timeStamp}*_l2*.zarr'))[0]
    l2_ds = xr.open_zarr(file, chunks='auto')
    variable_names = list(l2_ds.data_vars.keys())[0]
    l2_ds = l2_ds.rename({'X': 'longitude', 'Y': 'latitude', variable_names: varName})
    l2_ds = l2_ds.expand_dims({'time': pd.date_range(f"{timeStamp}01", periods=1)}).chunk(_chunks)
    l2_ds.to_zarr(zarrSavePath / f"{solution}_{timeStamp}.zarr", mode='a', consolidated=True, encoding={'l2_hds': _encoding_dict})
    shutil.rmtree(file)

    varName='l1_wtd'
    file=sorted(Path(tempDirectory).glob(f'*{solution}*wtd*{timeStamp}*_l1*.zarr'))[0]
    l1_ds = xr.open_zarr(file, chunks='auto')
    variable_names = list(l1_ds.data_vars.keys())[0]
    l1_ds = l1_ds.rename({'X': 'longitude', 'Y': 'latitude', variable_names: varName})
    l1_ds = l1_ds.expand_dims({'time': pd.date_range(f"{timeStamp}01", periods=1)}).chunk(_chunks)
    l1_ds.to_zarr(zarrSavePath / f"{solution}_{timeStamp}.zarr", mode='a', consolidated=True, encoding={'l1_wtd': _encoding_dict})
    shutil.rmtree(file)

    varName='l2_wtd'
    file=sorted(Path(tempDirectory).glob(f'*{solution}*wtd*{timeStamp}*_l2*.zarr'))[0]
    l2_ds = xr.open_zarr(file, chunks='auto')
    variable_names = list(l2_ds.data_vars.keys())[0]
    l2_ds = l2_ds.rename({'X': 'longitude', 'Y': 'latitude', variable_names: varName})
    l2_ds = l2_ds.expand_dims({'time': pd.date_range(f"{timeStamp}01", periods=1)}).chunk(_chunks)
    l2_ds.to_zarr(zarrSavePath / f"{solution}_{timeStamp}.zarr", mode='a', consolidated=True, encoding={'l2_wtd': _encoding_dict})
    shutil.rmtree(file)

with concurrent.futures.ProcessPoolExecutor(12) as executor:
    futures = {executor.submit(merge_variables, month)for month in range(1,13)}
    results = [f.result() for f in concurrent.futures.as_completed(futures)]