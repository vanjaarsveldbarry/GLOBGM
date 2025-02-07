import geopandas as gpd
from geocube.api.core import make_geocube
from pathlib import Path
import xarray as xr
from functools import partial
from geocube.rasterize import rasterize_image
dataFolder = Path('/scratch-shared/globgm_scratch/analysis/historical_reference_gswp3-w5e5/data')

target_grid = xr.open_dataset(dataFolder / 'target_grid.nc').load()
x_res = (target_grid.lon[1] - target_grid.lon[0]).values
y_res = (target_grid.lat[1] - target_grid.lat[0]).values

gdf = gpd.read_file(dataFolder / 'pa_groundwatershed_summary.gpkg').reset_index().rename(columns={'index': 'id'})
geo_grid = make_geocube(vector_data=gdf,
                        measurements=['id'],
                        resolution=(y_res, x_res))
geo_grid = geo_grid.rename({'x': 'lon', 'y': 'lat'})
geo_grid = geo_grid.drop_vars('spatial_ref')
geo_grid = geo_grid.reindex(lat=target_grid.lat, lon=target_grid.lon, method='nearest')
geo_grid.to_netcdf(dataFolder / 'pa_boundaries.nc')

