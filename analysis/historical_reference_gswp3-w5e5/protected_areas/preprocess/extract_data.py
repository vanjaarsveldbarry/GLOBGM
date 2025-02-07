import xarray as xr
import numpy as np 
import pandas as pd
from tqdm import tqdm
import warnings
from pathlib import Path
from concurrent.futures import ProcessPoolExecutor, as_completed
import time

saveDir = Path('/scratch-shared/globgm_scratch/analysis/historical_reference_gswp3-w5e5/output')

df_no_pump = pd.DataFrame()
df_with_pump = pd.DataFrame()

for solution in range(4, 0, -1):
    sim_ds_no_pump = xr.open_zarr(f'/scratch-shared/globgm_scratch/historical_reference_gswp3-w5e5/historical_no_pump_natural/mf6_post/s0{solution}_wtd.zarr', chunks={})
    sim_ds_no_pump = sim_ds_no_pump.sel(time=['1960-01-31', '2019-12-31']).compute()
    sim_ds_no_pump = xr.where(sim_ds_no_pump.l1_wtd.notnull(), sim_ds_no_pump.l1_wtd, sim_ds_no_pump.l2_wtd)

    lat_min, lat_max = sim_ds_no_pump.latitude.min().values, sim_ds_no_pump.latitude.max().values
    lon_min, lon_max = sim_ds_no_pump.longitude.min().values, sim_ds_no_pump.longitude.max().values

    sim_with_pump = xr.open_zarr(f'/scratch-shared/globgm_scratch/historical_reference_gswp3-w5e5/historical_with_pump/mf6_post/s0{solution}_wtd.zarr', chunks={})
    sim_with_pump = sim_with_pump.sel(latitude=slice(lat_max, lat_min), longitude=slice(lon_min,lon_max))
    sim_with_pump = sim_with_pump.sel(time=['1960-01-31', '2019-12-31']).compute()
    sim_with_pump = xr.where(sim_with_pump.l1_wtd.notnull(), sim_with_pump.l1_wtd, sim_with_pump.l2_wtd)

    pa_ds = xr.open_dataset('/scratch-shared/globgm_scratch/analysis/anthro_influence/data/pa_boundaries.nc')
    pa_ds = pa_ds.rename({'lat': 'latitude', 'lon': 'longitude'})
    pa_ds = pa_ds.sel(latitude=slice(lat_max, lat_min), longitude=slice(lon_min, lon_max)).compute()
    pa_ds = pa_ds.reindex_like(sim_ds_no_pump, method='nearest')
    pa_ds = pa_ds.where(sim_ds_no_pump.isel(time=0).notnull())
    unique_values =np.unique(pa_ds.id.values)
    unique_values = unique_values[~np.isnan(unique_values)]
    print(f'Solution {solution}: {len(unique_values)}')

    def process_value(i, sim_ds):
        def get_mean_time_slice(sim_ds, timeStamp, pa_sub_ds):
            return sim_ds.sel(time=timeStamp).mean(...).values.item()
        pa_sub_ds = pa_ds.where(pa_ds.id == i).id
        pa_sub_ds = pa_sub_ds.dropna(dim='latitude', how='all').dropna(dim='longitude', how='all')
        sim_ds = sim_ds.reindex_like(pa_sub_ds, method='nearest')
        sim_ds = xr.where(pa_sub_ds == i, sim_ds, np.nan)
        return pd.DataFrame([{'pa_id': i,
                            'solution': solution,
                            '1960_01': get_mean_time_slice(sim_ds, '1960-01-31', pa_sub_ds), 
                            '2019-12': get_mean_time_slice(sim_ds, '2019-12-31', pa_sub_ds)}])

    def process_values_parallel(unique_values, sim_ds):
        results = []
        for i in tqdm(unique_values):
                results.append(process_value(i, sim_ds))
        return results

    ds_process = [sim_with_pump, sim_ds_no_pump]
    results = []

    with ProcessPoolExecutor() as executor:
        futures = [executor.submit(process_values_parallel, unique_values, ds) for ds in ds_process]
        results = [future.result() for future in futures]

    results_with_pump, results_no_pump = results
            
    df_no_pump_sub = pd.concat(results_no_pump, ignore_index=True).dropna()
    df_with_pump_sub = pd.concat(results_with_pump, ignore_index=True).dropna()
    
    df_no_pump = pd.concat([df_no_pump, df_no_pump_sub], ignore_index=True)
    df_with_pump = pd.concat([df_with_pump, df_with_pump_sub], ignore_index=True)
    
df_no_pump.to_parquet(saveDir / f'with_pump_protected_areas.parquet', index=False)
df_with_pump.to_parquet(saveDir / f'no_pump_protected_areas.parquet', index=False)