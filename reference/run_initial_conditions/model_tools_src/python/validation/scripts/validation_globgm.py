import os
import argparse
import geopandas as gpd
import xarray as xr
import pandas as pd
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

    # Initialize an empty DataFrame to store the results
    mean_bias_df = pd.DataFrame(columns=['solution', 'layer_no', 'mean_bias'])
    for solution in ['s01', 's02', 's03']:
        for layer_no in [1, 2]:
            results_df = pd.DataFrame(columns=['lat', 'lon', 'sim_gw', 'avg_obs_gw', 'bias'])
            # Choose the correct variable name and file based on layer_no
            data_var = 'l2_wtd' if layer_no == 2 else 'l1_wtd'
            sim_file = mf6_post_folder / f'{solution}_wtd.zarr'
            ds = xr.open_zarr(sim_file)[data_var].mean('time').compute()
            for _, row in obs_grouped.iterrows():
                lat, lon = row['rounded_lat'], row['rounded_lon']
                avg_obs_gw = row['mean_gwh_m']
                if avg_obs_gw < 0: 
                    continue
                layer_no_station = int(row['layer_no'])  # Ensure layer_no is an integer
                if layer_no_station == layer_no:
                    sim_gw = ds.sel(latitude=lat, longitude=lon, method='nearest').item()
                    bias = sim_gw - avg_obs_gw
                    if not np.isnan(bias):
                        # Append the result to the DataFrame
                        new_row = pd.DataFrame({
                            'lat': [lat],
                            'lon': [lon],
                            'sim_gw': [sim_gw],
                            'avg_obs_gw': [avg_obs_gw],
                            'bias': [bias]})
                        results_df = pd.concat([results_df, new_row], ignore_index=True)
                    no_match_found = False  # Mark that a match was found
                else:
                    pass
            save_path = output_folder / f'{folder_name}_{solution}_layer{layer_no}_bias.csv'
            if not save_path.exists():
                results_df_save = results_df.rename(columns={'bias': 'bias1'})
                results_df_save.to_csv(save_path, index=False)
            else:
                existing_df = pd.read_csv(save_path)
                new_col_name = f'bias{len(existing_df.columns) - 4 + 1}'
                results_df_save = results_df[['bias']].rename(columns={'bias': new_col_name})
                combined_df_save = pd.concat([existing_df, results_df_save], axis=1)
                combined_df_save.to_csv(save_path, index=False)
            
            mean_bias = results_df['bias'].mean()
            new_mean_bias_row = pd.DataFrame({'solution': [solution], 'layer_no': [layer_no], 'mean_bias': [mean_bias]})
            mean_bias_df = pd.concat([mean_bias_df, new_mean_bias_row], ignore_index=True)
    output_file = output_folder / f'{folder_name}_mean_bias.csv'
    if not output_file.exists():
        mean_bias_df.rename(columns={'mean_bias': 'bias1'}, inplace=True)
        mean_bias_df.to_csv(output_file, index=False)
    else:
        existing_df = pd.read_csv(output_file)
        new_col_name = f'bias{len(existing_df.columns) - 2 + 1}'
        mean_bias_df = mean_bias_df[['mean_bias']].rename(columns={'mean_bias': new_col_name})
        combined_df = pd.concat([existing_df, mean_bias_df], axis=1)
        combined_df.to_csv(output_file, index=False)
    
    return no_match_found

obs_gdf = gpd.read_file(observed_shapefile)
if 'mean_gw_he' in obs_gdf.columns:
    obs_gdf.rename(columns={'mean_gw_he': 'mean_gwh_m'}, inplace=True)
obs_gdf = obs_gdf[['lat', 'lon', 'mean_gwh_m', 'layer_no']]
obs_gdf['layer_no'] = obs_gdf['layer_no'].astype(int)
obs_gdf['rounded_lat'] = obs_gdf['lat'].apply(round_coordinates)
obs_gdf['rounded_lon'] = obs_gdf['lon'].apply(round_coordinates)
obs_grouped = obs_gdf.groupby(['rounded_lat', 'rounded_lon', 'layer_no']).mean().reset_index()

folders= [sim_dir]
# # # Run calculations in parallel using ProcessPoolExecutor
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
            