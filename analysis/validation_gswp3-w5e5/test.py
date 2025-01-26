import geopandas as gpd
import pandas as pd
import xarray as xr
from pathlib import Path

# dataDir = Path('/projects/prjs1222/globgm_output/historical_with_pump/gswp3-w5e5/mf6_postOLD')
# solution = 3
locationFile='/projects/prjs1222/GLOBGM/analysis/validation_gswp3-w5e5/data/tr_all_well_locations.gpkg'
obs_data_file='/projects/prjs1222/GLOBGM/analysis/validation_gswp3-w5e5/data/observed_gw_all.parquet'

# sim_ds = xr.open_zarr(dataDir / f's0{solution}_wtd.zarr')
# obs_data_ds = pd.read_parquet(obs_data_file)
# print(obs_data_ds)

# def filter_locations_within_bounds(sim_ds, locations_gdf):
#     bounds = (
#         sim_ds.longitude.min().values.item(), 
#         sim_ds.longitude.max().values.item(),  
#         sim_ds.latitude.min().values.item(), 
#         sim_ds.latitude.max().values.item()
#     )
#     filtered_locations_gdf = locations_gdf.cx[bounds[0]:bounds[1], bounds[2]:bounds[3]]
#     return filtered_locations_gdf

# locations_gdf = filter_locations_within_bounds(sim_ds, gpd.read_file(locationFile))

# for location in locations_gdf.itertuples():
#     sim_time_series = sim_ds.sel(latitude=location.lat, longitude=location.lon, method='nearest')#.compute()
#     print(sim_time_series)
#     obs_time_series = obs_data_ds[obs_data_ds['wellID'] == location.id_gerbil]
#     print(obs_time_series)
#     break
