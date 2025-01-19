import os
import argparse
import geopandas as gpd
import xarray as xr
# import pandas as pd
# import logging
# import psutil
# import time
from concurrent.futures import ProcessPoolExecutor, as_completed
from tqdm import tqdm
import numpy as np
import sys
from pathlib import Path

dataPath = Path('./data').resolve()
output_folder = Path(sys.argv[1])
sim_dir = Path(sys.argv[2])
observed_shapefile = Path(sys.argv[3])
max_workers = 22

output_folder.mkdir(parents=True, exist_ok=True)

def round_coordinates(value, resolution=0.008333333333333333):
    return round(value / resolution) * resolution

def calculate_bias_for_folder(folder_path, obs_grouped, output_folder):
    no_match_found = True  # Flag to track if any matches were found
    
    folder_name = folder_path.name
    
    # # Construct path to mf6_post and check for its existence
    mf6_post_folder = folder_path / 'mf6_post'
    if not os.path.exists(mf6_post_folder):
        print(f"'mf6_post' directory missing in {folder_path}. Skipping...")
        return None

    # Create CSV for this specific folder at the start
    bias_csv_path = output_folder / f"bias_results_{folder_name}.csv"
    with open(bias_csv_path, 'w') as f:
        f.write("lat,lon,sim_gw,obs_gw,bias\n")  # Write header

    for solution in ['s01', 's02', 's03', 's04']:
        for layer_no in [1, 2]:
            # Choose the correct variable name and file based on layer_no
            data_var = 'l2_wtd' if layer_no == 2 else 'l1_wtd'
            sim_file = mf6_post_folder / f'{solution}_wtd.zarr'

            ds = xr.open_zarr(sim_file)[data_var].compute()
            # for _, row in tqdm(obs_grouped.iterrows(), total=len(obs_grouped), desc=f"Processing stations in solution {solution} layer {layer_no}"):
            for _, row in obs_grouped.iterrows():
                lat, lon = row['rounded_lat'], row['rounded_lon']
                avg_obs_gw = row['mean_gwh_m']
                layer_no_station = int(row['layer_no'])  # Ensure layer_no is an integer
                if layer_no_station == layer_no:
                    sim_gw = ds.sel(latitude=lat, longitude=lon, method='nearest').item()
                    bias = sim_gw - avg_obs_gw
                    if not np.isnan(bias):
                        # Log details about the match and save to CSV immediately
                        with open(bias_csv_path, 'a') as f:
                            f.write(f"{lat},{lon},{sim_gw},{avg_obs_gw},{bias}\n")  # Append bias result
                    no_match_found = False  # Mark that a match was found
                else:
                    pass
    return no_match_found

obs_gdf = gpd.read_file(observed_shapefile)
if 'mean_gw_he' in obs_gdf.columns:
    obs_gdf.rename(columns={'mean_gw_he': 'mean_gwh_m'}, inplace=True)
obs_gdf = obs_gdf[['lat', 'lon', 'mean_gwh_m', 'layer_no']]
obs_gdf['layer_no'] = obs_gdf['layer_no'].astype(int)
obs_gdf['rounded_lat'] = obs_gdf['lat'].apply(round_coordinates)
obs_gdf['rounded_lon'] = obs_gdf['lon'].apply(round_coordinates)
obs_grouped = obs_gdf.groupby(['rounded_lat', 'rounded_lon', 'layer_no']).mean().reset_index()

folders = sorted([f for f in Path(sim_dir).iterdir() if f.is_dir()])

if folders == []:
    print(f"No folders found in {sim_dir}. Exiting...")
    sys.exit(1)
# # Run calculations in parallel using ProcessPoolExecutor
with ProcessPoolExecutor(max_workers=max_workers) as executor:
    future_to_folder = {
        executor.submit(calculate_bias_for_folder, folder, obs_grouped, output_folder): folder
        for folder in folders
    }

    for future in tqdm(as_completed(future_to_folder), total=len(future_to_folder), desc="Processing folders"):
        folder = future_to_folder[future]
        no_match_found = future.result() 
        # Get no match status
        
        if no_match_found:
            print(f"No matching coordinates found for folder: {folder}")
        else:
            print(f"Processed folder: {folder}")