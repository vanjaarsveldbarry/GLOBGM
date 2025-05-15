import xarray as xr
from pathlib import Path
import numpy as np
import sys
data_dir = Path(sys.argv[1]).parent
start_year = sys.argv[2]

ds = xr.open_dataset(data_dir/ f"output/{start_year}/spin_up_boolean_{start_year}.nc")
ds_final = ds[['hds_mask']].rename({"hds_mask": "spinup_qa"})	
ds_final['spinup_qa'].values = np.zeros_like(ds_final['spinup_qa'].values)
ds_final['spinup_qa'] = xr.where((ds['hds_mask'] == 1) & (ds['gwRecharge_mask'] == 1) & (ds['abstraction_mask'] == 1), 1, ds_final['spinup_qa'])
ds_final['spinup_qa'] = xr.where((ds['hds_mask'] == 1) & (ds['gwRecharge_mask'] == 1) & (ds['abstraction_mask'] == 0), 2, ds_final['spinup_qa'])
ds_final['spinup_qa'] = xr.where((ds['hds_mask'] == 1) & (ds['gwRecharge_mask'] == -1) & (ds['abstraction_mask'] == 1), 3, ds_final['spinup_qa'])
ds_final['spinup_qa'] = xr.where((ds['hds_mask'] == 1) & (ds['gwRecharge_mask'] == -1) & (ds['abstraction_mask'] == 0), 4, ds_final['spinup_qa'])
ds_final['spinup_qa'] = xr.where((ds['hds_mask'] == -1) & (ds['gwRecharge_mask'] == 1) & (ds['abstraction_mask'] == 1), 5, ds_final['spinup_qa'])
ds_final['spinup_qa'] = xr.where((ds['hds_mask'] == -1) & (ds['gwRecharge_mask'] == 1) & (ds['abstraction_mask'] == 0), 6, ds_final['spinup_qa'])
ds_final['spinup_qa'] = xr.where((ds['hds_mask'] == -1) & (ds['gwRecharge_mask'] == -1) & (ds['abstraction_mask'] == 1), 7, ds_final['spinup_qa'])
ds_final['spinup_qa'] = xr.where((ds['hds_mask'] == -1) & (ds['gwRecharge_mask'] == -1) & (ds['abstraction_mask'] == 0), 8, ds_final['spinup_qa'])
ds_final['spinup_qa'] = xr.where(ds['hds_mask'] == 9, 9, ds_final['spinup_qa'])
ds_final['spinup_qa'] = ds_final['spinup_qa'].astype(np.int8)
ds_final.to_netcdf(data_dir/ f"output/spin_up_{start_year}.nc", mode='w')
print(f'{start_year} done')