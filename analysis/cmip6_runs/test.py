import xarray as xr 
import seaborn as sns
import matplotlib.pyplot as plt
import pandas as pd

solution = 3
fig, axes = plt.subplots(2, 2, figsize=(20, 20))
for idx, solution in enumerate([3]):
    ds_historical = xr.open_zarr(f'/scratch-shared/globgm_scratch/temp/data/historical/s0{solution}_wtd.zarr', chunks='auto')
    # ds_historical = ds_historical.sel(time=slice('2014-01-31', '2014-12-31'))
    ds_historical = ds_historical.mean(dim=['latitude', 'longitude']).load()
    ds_historical = ds_historical.to_dataframe().reset_index()
    ds_historical['scenario'] = 'historical'
    print(ds_historical)
    ds_ssp126 = xr.open_zarr(f'/scratch-shared/globgm_scratch/temp/data/ssp126/s0{solution}_wtd.zarr', chunks='auto')
    # ds_ssp126 = ds_ssp126.sel(time=slice('2015-01-31', '2015-12-31'))
    ds_ssp126 = ds_ssp126.mean(dim=['latitude', 'longitude']).load()
    ds_ssp126 = ds_ssp126.to_dataframe().reset_index()
    ds_ssp126['scenario'] = 'ssp126'
    print(ds_ssp126)
    ds_ssp370 = xr.open_zarr(f'/scratch-shared/globgm_scratch/temp/data/ssp370/s0{solution}_wtd.zarr', chunks='auto')
    # ds_ssp370 = ds_ssp370.sel(time=slice('2015-01-31', '2015-12-31'))
    ds_ssp370 = ds_ssp370.mean(dim=['latitude', 'longitude']).load()
    ds_ssp370 = ds_ssp370.to_dataframe().reset_index()
    ds_ssp370['scenario'] = 'ssp370'
    print(ds_ssp370)
    
    ds_ssp585 = xr.open_zarr(f'/scratch-shared/globgm_scratch/temp/data/ssp585/s0{solution}_wtd.zarr', chunks='auto')
    # ds_ssp585 = ds_ssp585.sel(time=slice('2015-01-31', '2015-12-31'))
    ds_ssp585 = ds_ssp585.mean(dim=['latitude', 'longitude']).load()
    ds_ssp585 = ds_ssp585.to_dataframe().reset_index()
    ds_ssp585['scenario'] = 'ssp585'
    print(ds_ssp585)

    df_combined = pd.concat([ds_historical, ds_ssp126, ds_ssp370, ds_ssp585])
    print(df_combined)
    palette = {'historical': 'grey', 'ssp126': 'blue', 'ssp370': 'black', 'ssp585': 'red'}
    sns.lineplot(x='time', y='l1_wtd', data=df_combined, hue='scenario', palette=palette, ax=axes[idx, 0])
    sns.lineplot(x='time', y='l2_wtd', data=df_combined, hue='scenario', palette=palette, ax=axes[idx, 1])
    
    axes[idx, 0].invert_yaxis()
    axes[idx, 1].invert_yaxis()
    
    if idx == 0:
        axes[idx, 0].set_title('l1_wtd')
        axes[idx, 1].set_title('l2_wtd')
        axes[idx, 0].set_ylabel(f'Solution: {solution}')
        axes[idx, 1].set_ylabel(f'Solution: {solution}')
    
    else:
        axes[idx, 0].set_ylabel(f'Solution: {solution}')
        axes[idx, 1].set_ylabel(f'Solution: {solution}')
    
plt.savefig(f'/scratch-shared/globgm_scratch/temp/lineplot.png')
