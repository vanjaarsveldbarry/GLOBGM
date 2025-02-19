from pathlib import Path
import numpy as np
import xarray as xr

dataPath = Path('/scratch-shared/globgm_scratch/analysis/cmip6_runs/thiel_sen_slope/data')
savePath = Path('/scratch-shared/globgm_scratch/analysis/cmip6_runs/thiel_sen_slope/data/plot_data')
savePath.mkdir(exist_ok=True)

mask_ds = xr.open_dataset('/scratch-shared/globgm_scratch/analysis/misc_data/lddsound_30sec_version_202005XX_correct_lat.nc')['Band1'].rename({'lon': 'longitude', 'lat': 'latitude'})
GCM = 'ipsl-cm6a-lr'

# for scen in ['historical', 'ssp126', 'ssp370', 'ssp585']:
    # for var in ['hds']:
    #     ds_layer1 = xr.open_dataset(dataPath / f'{GCM}_{scen}_l1_{var}.nc')
    #     ds_layer2 = xr.open_dataset(dataPath / f'{GCM}_{scen}_l2_{var}.nc')

    #     ds_layer1['slope'] = xr.where(ds_layer1['slope'].notnull(),
    #                                   ds_layer1['slope'], ds_layer2['slope'])
    #     ds_layer1['p'] = xr.where(ds_layer1['p'].notnull(),
    #                               ds_layer1['p'], ds_layer2['p'])
    #     ds_layer1 = ds_layer1.reindex(latitude=mask_ds.latitude,
    #                                   longitude=mask_ds.longitude,
    #                                   method='nearest')
    #     ds_layer1 = xr.where(mask_ds != 255,
    #                          ds_layer1, np.nan)
        
    #     ds_layer1.attrs['crs'] = 'EPSG:4326'
    #     # Save datasets for each significance level bracket
    #     ds_strong_evidence = ds_layer1.where(ds_layer1['p'] <= 0.01)
    #     ds_strong_evidence.to_netcdf(savePath / f'{GCM}_{scen}_{var}_strong_evidence.nc')
        
    #     ds_moderate_evidence = ds_layer1.where((ds_layer1['p'] > 0.01) & (ds_layer1['p'] <= 0.05))
    #     ds_moderate_evidence.to_netcdf(savePath / f'{GCM}_{scen}_{var}_moderate_evidence.nc')
        
    #     ds_weak_evidence = ds_layer1.where((ds_layer1['p'] > 0.05) & (ds_layer1['p'] <= 0.10))
    #     ds_weak_evidence.to_netcdf(savePath / f'{GCM}_{scen}_{var}_weak_evidence.nc')
        
    #     ds_no_evidence = ds_layer1.where(ds_layer1['p'] > 0.10)
    #     ds_no_evidence.to_netcdf(savePath / f'{GCM}_{scen}_{var}_no_evidence.nc')
        
#create mask

mask = xr.open_dataset('/scratch-shared/globgm_scratch/analysis/misc_data/lddsound_30sec_version_202005XX_correct_lat.nc')['Band1'].rename({'lon': 'longitude', 'lat': 'latitude'})
mask = mask.where(mask != 255)
mask = xr.where(mask.notnull(), 1, np.nan)
mask.to_netcdf(savePath / 'mask.nc')
