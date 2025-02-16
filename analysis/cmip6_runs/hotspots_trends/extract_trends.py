import xarray as xr
from pathlib import Path
import geopandas as gpd
from tqdm import tqdm

hotspots_ds = gpd.read_file('/scratch-shared/globgm_scratch/analysis/cmip6_runs/hotspots_trends/data/hotspots_geometry/hotspots.gpkg')

for GCM in ['ipsl-cm6a-lr']:
    for scen in ['historical', 'ssp126', 'ssp370', 'ssp585']:
        data_dir = Path(f'/scratch-shared/globgm_scratch/cmip6_runs/{GCM}/{scen}/merged')
        save_dir = Path(f'/scratch-shared/globgm_scratch/analysis/cmip6_runs/hotspots_trends/data/timeseries/{GCM}/{scen}')
        save_dir.mkdir(parents=True, exist_ok=True)
        for var in ['hds', 'wtd']:
            ds = xr.open_zarr(data_dir / f'{var}.zarr')
            for i, hotspot in tqdm(hotspots_ds.iterrows(), desc=f'Extracting {GCM} {scen} {var}', total=hotspots_ds.shape[0]):
                bbox = hotspot.geometry.bounds
                min_lat, min_lon, max_lat, max_lon = bbox[1], bbox[0], bbox[3], bbox[2]
                subset_ds = ds.sel(latitude=slice(max_lat, min_lat), longitude=slice(min_lon, max_lon))
                subset_ds= subset_ds.mean(['latitude', 'longitude']).compute()
                subset_ds = subset_ds.to_dataframe().reset_index()
                subset_ds['name'] = hotspot['name']
                subset_ds.to_parquet(save_dir / f'{hotspot["name"]}_{var}.parquet')