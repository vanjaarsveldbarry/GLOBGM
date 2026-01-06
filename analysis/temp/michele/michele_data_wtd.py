import xarray as xr
import rioxarray
from rasterio.enums import Resampling
from pathlib import Path
from tqdm import tqdm

# --- 1. Load and Prepare Datasets ---

# # Load reference grid, rename dims, and set CRS
# reference_grid_path = '/projects/prjs1222/globgm_input/_data/cmip6_input/ukesm1-0-ll/historical/pcrglobwb_cmip6-isimip3-ukesm1-0-ll_image-aqueduct_historical_gwRecharge_global_monthly-total_1960_2014_basetier1.nc'
# reference_grid = xr.open_dataset(reference_grid_path, chunks={})
# reference_grid = reference_grid.rename({'lat': 'y', 'lon': 'x'})
# reference_grid.rio.write_crs("EPSG:4326", inplace=True)

# # Load source dataset, rename dims, and set CRS
# source_zarr_path = '/projects/prjs1222/globgm_output/reference_gswp3-w5e5/historical_with_pump/merged/wtd.zarr'
# source_ds = xr.open_zarr(source_zarr_path)
# source_ds = source_ds.rename({'latitude': 'y', 'longitude': 'x'})
# source_ds.rio.write_crs("EPSG:4326", inplace=True)

# # --- 2. Reproject in a Loop Over Time ---

# # Create an empty list to store each reprojected time slice
# reprojected_slices = []

# # Iterate over each time step in the source dataset
# for time_step in tqdm(source_ds.time, desc="Reprojecting time steps"):
   
#     # Select the data for the current time step
#     source_slice = source_ds.sel(time=time_step).compute()
    
#     # Reproject the individual slice
#     reprojected_slice = source_slice.rio.reproject_match(
#         reference_grid,
#         resampling=Resampling.average
#     )
#     # Add the reprojected slice to our list
#     reprojected_slices.append(reprojected_slice)

# # Concatenate all the reprojected slices along the time dimension
# reprojected_ds = xr.concat(reprojected_slices, dim="time")
# reprojected_ds = reprojected_ds.rename({'y': 'latitude', 'x': 'longitude'})
# reprojected_ds = reprojected_ds.drop_vars(['spatial_ref'])

# # Define the output path
# save_path = Path('/projects/prjs1222/temp/wtd_5arcmin.nc')
# reprojected_ds.to_netcdf(save_path, mode='w', encoding={var: {'zlib': False} for var in reprojected_ds.data_vars})
# print(reprojected_ds)

import matplotlib.pyplot as plt

ds = xr.open_dataset('/projects/prjs1222/temp/wtd_5arcmin.nc')
# Select the first time step
first_slice = ds.isel(time=0)

# Plot the first time step for each variable
for var in first_slice.data_vars:
    plt.figure(figsize=(12, 6))
    first_slice[var].plot(cmap='viridis')
    plt.title(f'Global map of {var} at first time step')
    plt.xlabel('Longitude')
    plt.ylabel('Latitude')
    plt.savefig(f'/projects/prjs1222/temp/{var}_first_time_step.png')