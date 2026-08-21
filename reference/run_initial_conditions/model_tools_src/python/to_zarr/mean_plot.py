import sys
from pathlib import Path
import xarray as xr
import pandas as pd
import warnings
warnings.simplefilter("ignore") 
import os
import numpy as np


_chunks={'time': 1, 'latitude': 20000, 'longitude': 20000}

saveDirectory = Path(sys.argv[1])
solution=sys.argv[2]
var=sys.argv[3]

file=saveDirectory / f"s0{solution}_{var}.zarr"
ds = xr.open_zarr(file).isel(time=slice(11,12))
for layer in ['l1', 'l2']:
    savePath_abs=saveDirectory / f"s0{solution}_{var}_{layer}_abs.csv"
    if not os.path.exists(savePath_abs):
        df_abs = pd.DataFrame({f'iteration1': ds[f'{layer}_{var}'].mean(['latitude', 'longitude']).values[:].astype(np.float32)})
        df_abs.to_csv(savePath_abs, index=False)
    else:
        df_abs = pd.read_csv(savePath_abs).astype(np.float32)
        df_abs[f'iteration{len(df_abs.columns)+1}'] = ds[f'{layer}_{var}'].mean(['latitude', 'longitude']).values[:].astype(np.float32)
        df_abs.to_csv(savePath_abs, index=False)