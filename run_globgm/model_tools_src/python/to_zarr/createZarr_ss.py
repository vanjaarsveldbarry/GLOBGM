import subprocess
import sys
from pathlib import Path
import shutil
import os
import xarray as xr
from numcodecs import Blosc
import concurrent.futures


# Create a compressor
compressor = Blosc(cname='zstd', clevel=5, shuffle=Blosc.SHUFFLE)

inputFolder = sys.argv[1]
outputFolder = sys.argv[2]
solution = sys.argv[3]


input_files = Path(inputFolder).glob(f'*{solution}*.flt')

# for infile in input_files:
def process_file(infile):
    savePath=f"{outputFolder}/{solution}/{infile.stem}.zarr"
    if os.path.exists(savePath): shutil.rmtree(savePath)
    Path(savePath).parent.mkdir(parents=True, exist_ok=True)
    command = f"gdal_translate -of ZARR -co COMPRESS=ZSTD -co ZSTD_LEVEL=5 {infile} {savePath}"
    process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE)
    process.wait()

with concurrent.futures.ProcessPoolExecutor() as executor:
    executor.map(process_file, input_files)