import geopandas as gpd
import pandas as pd
import xarray as xr
from pathlib import Path
import numpy as np

dataDir = Path('/scratch-shared/_bvjaarsveld1/temp/validation/output')
#Get Mean Bias for all points
validation_df = pd.read_parquet(dataDir / 'timeseries_hds.parquet')
def calculate_mean_bias(validation_df):
    final_mean_bias = pd.DataFrame()
    for layer in [1,2]:
        layer_df = validation_df[validation_df['layer'] == layer]
        mean_bias = validation_df.groupby('wellID').agg({
            'solution': 'first',
            'lon': 'first',
            'lat': 'first',
            'obs_hds': 'mean',
            f'l{layer}_hds': 'mean'
        })
        mean_bias = mean_bias.dropna(subset=[f'l{layer}_hds'])
        mean_bias = mean_bias.rename(columns={f'l{layer}_hds': 'sim_hds'})
        final_mean_bias = pd.concat([final_mean_bias, mean_bias])
    final_mean_bias = final_mean_bias.reset_index()[['solution', 'wellID', 'obs_hds', 'sim_hds']]
    final_mean_bias['bias'] = final_mean_bias['sim_hds'] - final_mean_bias['obs_hds']
    mean_bias.to_parquet(dataDir / 'mean_bias_hds.parquet')

def calculate_kge_by_station(validation_df):
    def calculate_kge(group):
        obs = group['obs_hds']
        if len(obs) <= 6:
            return np.nan
        sim = group['sim_hds']
        cc = np.corrcoef(obs, sim)[0, 1]
        obs_std, sim_std = np.std(obs), np.std(sim)
        obs_mean, sim_mean = np.mean(obs), np.mean(sim)
        if obs_std == 0 or obs_mean == 0:
            return np.nan
        alpha = sim_std / obs_std
        beta = sim_mean / obs_mean
        kge = 1 - np.sqrt((cc - 1)**2 + (alpha - 1)**2 + (beta - 1)**2)
        return kge

    final_kge = pd.DataFrame()
    for layer in [1,2]:
        layer_df = validation_df[validation_df['layer'] == layer]
        layer_df = layer_df[['wellID', 'time', 'lon', 'lat', 'layer', 'obs_hds', f'l{layer}_hds', 'solution']]
        layer_df = layer_df.rename(columns={f'l{layer}_hds': 'sim_hds'})
        kge_by_station = layer_df.groupby('wellID', group_keys=False).apply(calculate_kge)
        kge_by_station = kge_by_station.dropna()
        kge_by_station = kge_by_station.reset_index()
        kge_by_station = kge_by_station.rename(columns={0: 'KGE'})
        final_kge = pd.concat([final_kge, kge_by_station])
    final_kge = final_kge.merge(validation_df[['wellID', 'solution', 'lat', 'lon', 'layer']].drop_duplicates(), on='wellID', how='left')
    final_kge.to_parquet(dataDir / 'kge_by_station_wtd.parquet')
calculate_mean_bias(validation_df)
kge_df = calculate_kge_by_station(validation_df)
