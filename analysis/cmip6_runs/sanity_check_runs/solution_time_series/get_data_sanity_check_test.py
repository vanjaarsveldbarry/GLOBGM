from pathlib import Path
import xarray as xr
import pandas as pd
data_dir = Path("/projects/prjs1222/globgm_output/_backup/cmip6_runs")
scenario = "ssp585"
# GCM_list = ['gfdl-esm4', 'ipsl-cm6a-lr', 'mpi-esm1-2-hr', 'mri-esm2-0', 'ukesm1-0-ll']
GCM_list = ['ipsl-cm6a-lr']
save_dir=Path("/scratch-shared/globgm_scratch/analysis/cmip6_runs/sanity_check_runs/solution_time_series/data")
save_dir.mkdir(exist_ok=True, parents=True)

for solution in [3]:#,2,1,4]:
    df_final = pd.DataFrame()
    for GCM in GCM_list:
        ds = xr.open_dataset(data_dir / f"{GCM}/{scenario}/mf6_post/s0{solution}_hds.zarr")['l2_hds']#.isel(time=slice(0,60))
        ds = ds.mean(['latitude', 'longitude']).compute()
        df = ds.to_dataframe().reset_index()
        df['scenario'] = scenario
        df['GCM'] = GCM
        df = df[['GCM', 'scenario', 'time', 'l2_hds']]
        df_final = pd.concat([df_final, df])
        print(solution, GCM)
    df_final.to_parquet(save_dir / f"{scenario}_s0{solution}.parquet")