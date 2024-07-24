import xarray as xr
import sys
from pathlib import Path
from numcodecs import Blosc
import pandas as pd
import dask
dask.config.set(**{'array.slicing.split_large_chunks': False})

modelRoot=Path(sys.argv[1])
solution=Path(sys.argv[2])
saveDir=Path(sys.argv[3])
startDate=sys.argv[4]
endDate=sys.argv[5]
var=sys.argv[6]

_compressor = Blosc(cname='zstd', clevel=5, shuffle=Blosc.BITSHUFFLE)
_encoding_dict={'dtype': 'float32', '_FillValue': -9999, 'compressor': _compressor}
_chunks={'time': 1, 'latitude': 20000, 'longitude': 20000}

steadyStateFile=modelRoot.parent / f'ss/mf6_post/s0{solution}_{var}.zarr'
ds = xr.open_zarr(steadyStateFile)[[f'l1_{var}', f'l2_{var}']]
time_dim = pd.date_range(start=f'{startDate}-01-31', end=f'{endDate}-12-31', freq='ME')
ds = ds.reindex(time=time_dim)
ds = ds.chunk(_chunks)
ds.to_zarr(saveDir / f"s0{solution}_{var}.zarr", mode='w', consolidated=True, compute=False, encoding={f'l1_{var}': _encoding_dict, f'l2_{var}': _encoding_dict})