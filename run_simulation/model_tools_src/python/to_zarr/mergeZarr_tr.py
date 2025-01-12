import sys
from pathlib import Path
import xarray as xr
import pandas as pd
import concurrent.futures
import xarray as xr
import warnings
warnings.simplefilter("ignore") 
import time
import os
import subprocess
import shutil
from datetime import datetime


_chunks={'time': 1, 'latitude': 20000, 'longitude': 20000}

saveDirectory = Path(sys.argv[1])
directory = Path(sys.argv[2])
solution=sys.argv[3]
year=sys.argv[4]
month=sys.argv[5]
var=sys.argv[6]

tempDirectory=directory/ f'temp_zarr'
tempDirectory.mkdir(parents=True, exist_ok=True)

#Convert .flt to ZARR
def convert_file(infile):
    savePath=f"{tempDirectory}/{infile.stem}.zarr"
    if os.path.exists(savePath): shutil.rmtree(savePath)
    command = f"gdal_translate -of ZARR {infile} {savePath}"
    process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE)
    process.wait()
    return savePath

input_files = sorted(Path(directory).glob(f'*{solution}*{year}{month}*.flt'))
with concurrent.futures.ProcessPoolExecutor(2) as executor:
    futures = {executor.submit(convert_file, file) for file in input_files}
    tempZarrPaths = [f.result() for f in concurrent.futures.as_completed(futures)]
for f in tempZarrPaths:
    timeStamp=Path(f).stem[-11:-3]
    date_object = datetime.strptime(timeStamp, '%Y%m%d')
    if 'l1' in f:
        varName=f'l1_{var}'
        l1_ds = xr.open_zarr(f, chunks='auto')
        variable_names = list(l1_ds.data_vars.keys())[0]
        l1_ds = l1_ds.rename({'X': 'longitude', 'Y': 'latitude', variable_names: varName})
        l1_ds = l1_ds.expand_dims({'time': pd.date_range(f"{timeStamp}", periods=1)}).chunk(_chunks)
        
    if 'l2' in f:	
        varName=f'l2_{var}'
        l2_ds = xr.open_zarr(f, chunks='auto')
        variable_names = list(l2_ds.data_vars.keys())[0]
        l2_ds = l2_ds.rename({'X': 'longitude', 'Y': 'latitude', variable_names: varName})
        l2_ds = l2_ds.expand_dims({'time': pd.date_range(f"{timeStamp}", periods=1)}).chunk(_chunks)  
        
ds = xr.merge([l1_ds, l2_ds])
ds = ds.chunk(_chunks)
ds = ds.drop_vars(['latitude', 'longitude'])
dsInfo = xr.open_zarr(saveDirectory / f"s0{solution}_{var}.zarr")
date_object = datetime.strptime(timeStamp, '%Y%m%d')
index = dsInfo.get_index('time').get_loc(date_object.strftime('%Y-%m-%d'))
ds.to_zarr(saveDirectory / f"s0{solution}_{var}.zarr", region={"time": slice(index, index+1)}, consolidated=True)
print(f"Saved {timeStamp}")