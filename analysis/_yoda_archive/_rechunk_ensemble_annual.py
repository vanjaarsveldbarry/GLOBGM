import xarray as xr
from pathlib import Path
import sys
from tqdm import tqdm
import gc
dataPath = Path('/projects/prjs1222/scratch_backup/globgm_scratch/archive/cmip6/ensemble')

data_input = dataPath / 'annual_temp'
sub_folders = [f for f in data_input.iterdir() if f.is_dir()]
save_path = dataPath / 'annual'

save_path.mkdir(parents=True, exist_ok=True)
for sub_folder in tqdm(sub_folders):
    sub_save = save_path / sub_folder.name
    ds = xr.open_zarr(sub_folder)
    ds = ds.chunk({'time': 30, 'latitude': 1285, 'longitude': 3323})
    encoding = {var: {'chunks': (30, 1285, 3323)} for var in ds.data_vars}
    ds.to_zarr(sub_save, mode = 'w', encoding=encoding)
    print(ds)