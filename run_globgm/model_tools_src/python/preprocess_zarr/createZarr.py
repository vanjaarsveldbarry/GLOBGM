import xarray as xr
from pathlib import Path
import sys
from numcodecs import Blosc
import pandas as pd

input_folder=Path(sys.argv[1])
saveFolder=Path(sys.argv[2])
start_year=int(sys.argv[3])
end_year=int(sys.argv[4])


_compressor = Blosc(cname='zstd', clevel=5, shuffle=Blosc.BITSHUFFLE)
_encoding_dict={'dtype': 'float32', '_FillValue': -9999, 'compressor': _compressor}
_chunks={'time': 1, 'lat': 20000, 'lon': 20000}

time_dim = pd.date_range(start=f'{start_year}-01-31', end=f'{end_year}-12-31', freq='ME')

ds=xr.open_dataset(input_folder / 'lddsound_30sec_version_202005XX_correct_lat.nc', chunks={})
ds = ds.expand_dims({'time': time_dim})
ds = ds.rename({'Band1': 'discharge'})
ds = ds.chunk(_chunks)
ds.to_zarr(saveFolder / f"discharge.zarr", compute=False, mode='w', consolidated=True, encoding={'discharge': _encoding_dict})

ds = ds.rename({'discharge': 'gwRecharge'})
ds.to_zarr(saveFolder / f"gwRecharge.zarr", compute=False, mode='w', consolidated=True, encoding={'gwRecharge': _encoding_dict})

ds = ds.rename({'gwRecharge': 'gwAbstraction'})
ds.to_zarr(saveFolder / f"gwAbstraction.zarr", compute=False, mode='w', consolidated=True, encoding={'gwAbstraction': _encoding_dict})