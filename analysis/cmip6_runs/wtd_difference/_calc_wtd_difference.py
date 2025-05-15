import xarray as xr
from pathlib import Path
from tqdm import tqdm
input_dit = Path('/projects/prjs1222/globgm_output/cmip6_runs/ensemble_means')
save_dir = Path('/projects/prjs1222/scratch_backup/globgm_scratch/analysis/cmip6_runs/wtd_difference/data')
save_dir.mkdir(exist_ok=True, parents=True)

#Extract the last timestep from each scenario and save it as a netCDF file
for scen in tqdm(['historical', 'ssp126', 'ssp370', 'ssp585'], desc="Processing scenarios"):
    ds = xr.open_zarr(input_dit / scen / 'wtd.zarr').isel(time=-1)
    last_timestep_info = ds.time.dt.strftime('%Y-%m-%d').item()
    savePath = save_dir / f'{scen}_{last_timestep_info}_wtd.nc'
    ds.to_netcdf(savePath, mode='w')
    
# Read the historical file
historical_ds = xr.open_dataset(save_dir / f"historical_2014-12-31_wtd.nc")
for scen in tqdm(['ssp126', 'ssp370', 'ssp585'], desc="Calculating deltas"):
    scenario_ds = xr.open_dataset(save_dir / f"{scen}_2100-12-31_wtd.nc")
    
    # Calculate the difference (delta)
    delta_ds = scenario_ds - historical_ds
    
    # Save the delta as a new netCDF file
    delta_ds.to_netcdf(save_dir / f"delta_{scen}_2100-12-31_wtd.nc", mode='w')