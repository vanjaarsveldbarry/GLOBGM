import subprocess
import sys
from pathlib import Path
import shutil
import os
import xarray as xr
from numcodecs import Blosc


# Create a compressor
compressor = Blosc(cname='zstd', clevel=5, shuffle=Blosc.SHUFFLE)

inputFolder = sys.argv[1]
outputFolder = sys.argv[2]
solution = sys.argv[3]


input_files = Path(inputFolder).glob(f'*{solution}*.flt')

for infile in input_files:
    print(infile)
    savePath=f"{outputFolder}/temp/{infile.stem}.zarr"
    if os.path.exists(savePath): shutil.rmtree(savePath)
    command = f"gdal_translate -of ZARR {infile} {savePath}"
    process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE)
    process.wait()
    # os.remove(infile)

input_files = Path(f"{outputFolder}/temp").glob(f"*{solution}*.zarr")
savePath=f"{outputFolder}/temp/{solution}"

# Create a compressor
compressor = Blosc(cname='zstd', clevel=5, shuffle=Blosc.BITSHUFFLE)
_encoding_dict={'dtype': 'float32', '_FillValue': -9999, 'compressor': compressor}
zarrSavePath=f"{outputFolder}/{solution}.zarr"
for number, infile in enumerate(input_files):
    ds = xr.open_zarr(infile, chunks='auto')
    variable_names = list(ds.data_vars.keys())[0]
    if 'l1' in infile.stem: layer='l1'
    if 'l2' in infile.stem: layer='l2'
    if 'hds' in infile.stem: variable='hds'
    if 'wtd' in infile.stem: variable='wtd'
    
    if number == 0: mode = 'w'
    if number != 0: mode = 'a'
    
    varName=f'{layer}_{variable}'
    ds = ds.rename({'X': 'longitude', 'Y': 'latitude', variable_names: varName})
    encoding = {f'{varName}': _encoding_dict}
    ds.to_zarr(zarrSavePath, mode=mode, consolidated=True, encoding=encoding)