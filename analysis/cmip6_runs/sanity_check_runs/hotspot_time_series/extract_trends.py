import xarray as xr
from pathlib import Path
import geopandas as gpd
from tqdm import tqdm
import rioxarray

hotspots_ds = gpd.read_file('/scratch-shared/globgm_scratch/analysis/cmip6_runs/hotspots_trends/data/hotspots_geometry/hotspots.gpkg')
hotspots_ds = hotspots_ds[hotspots_ds['name'].isin(['Australia', 'ArabianPeninsula', 'California'])]
root_save = Path('/scratch-shared/globgm_scratch/analysis/cmip6_runs/sanity_check_runs/hotspots_time_series')
data_dir= Path('/projects/prjs1222/globgm_output/_backup/cmip6_runs')
for GCM in ['ipsl-cm6a-lr', 'gfdl-esm4', 'mpi-esm1-2-hr', 'mri-esm2-0', 'ukesm1-0-ll']:
    for scen in ['historical', 'ssp126']:#, 'ssp370', 'ssp585']:
        data_dir_sub = Path(data_dir / f'{GCM}/{scen}')
        save_dir = root_save/  f'data/{GCM}/{scen}'
        save_dir.mkdir(parents=True, exist_ok=True)
        for solution in [1, 2, 3]:
            for var in ['hds']:
                ds = xr.open_zarr(data_dir_sub / f'mf6_post/s0{solution}_{var}.zarr')
                for i, hotspot in tqdm(hotspots_ds.iterrows(), desc=f'Extracting {GCM} {scen} {var} {solution}', total=hotspots_ds.shape[0]):
                    bbox = hotspot.geometry.bounds
                    min_lat, min_lon, max_lat, max_lon = bbox[1], bbox[0], bbox[3], bbox[2]
                    if (min_lat >= ds.latitude.min().item() and max_lat <= ds.latitude.max().item() and
                        min_lon >= ds.longitude.min().item() and max_lon <= ds.longitude.max().item()):
                        ds_test = ds[f'l2_{var}'].sel(latitude=slice(max_lat, min_lat), longitude=slice(min_lon, max_lon)).isel(time=0)
                        ds_test = ds_test.rio.write_crs("EPSG:4326")
                        ds_test = ds_test.rio.clip([hotspot.geometry], ds_test.rio.crs)
                        ds_test = ds_test.sum(...).compute().values
                        if ds_test != 0:
                            subset_ds = ds.sel(latitude=slice(max_lat, min_lat), longitude=slice(min_lon, max_lon))
                            subset_ds = subset_ds.resample(time='YE').mean()
                            # subset_ds = xr.where(subset_ds[f'l1_{var}'].notnull(), subset_ds[f'l1_{var}'], subset_ds[f'l1_{var}']).rename(f'{var}')
                            # subset_ds = subset_ds.rio.write_crs("EPSG:4326")
                            # subset_ds = subset_ds.rio.clip([hotspot.geometry], subset_ds.rio.crs)
                            subset_ds= subset_ds.mean(['latitude', 'longitude']).compute().to_dataframe().reset_index()
                            subset_ds['name'] = hotspot['name']
                            subset_ds.to_parquet(save_dir / f'{hotspot["name"]}_{var}.parquet')
                            print(subset_ds)