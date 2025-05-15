from pathlib import Path
import numpy as np
import xarray as xr

dataPath = Path('/projects/prjs1222/scratch_backup/globgm_scratch/analysis/cmip6_runs/thiel_sen_slope/data')
savePath = dataPath / 'plot_data'
savePath.mkdir(exist_ok=True)

var='hds'

for _scen in ['ssp126', 'ssp370', 'ssp585', 'historical']:
    for layer in [1, 2]:
        ds_layer = xr.open_dataset(dataPath / f'{_scen}_l{layer}_{var}.nc')

        # Save datasets for each significance level bracket
        ds_strong_evidence = ds_layer.where(ds_layer['p'] <= 0.05)
        ds_strong_evidence.to_netcdf(savePath / f'layer{layer}_{_scen}_{var}_strong_evidence.nc')

        ds_no_evidence = ds_layer.where(ds_layer['p'] > 0.05)
        ds_no_evidence.to_netcdf(savePath / f'layer{layer}_{_scen}_{var}_no_evidence.nc')