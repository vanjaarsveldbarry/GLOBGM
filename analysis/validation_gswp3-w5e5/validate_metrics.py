import geopandas as gpd
import pandas as pd
import xarray as xr
from pathlib import Path
import numpy as np

dataDir = Path('/scratch-shared/_bvjaarsveld1/temp/validation/output')
#Get Mean Bias for all points
validation_df = pd.read_parquet(dataDir / 'timeseries_wtd.parquet')
def calculate_mean_bias(validation_df):
    mean_bias = validation_df.groupby('wellID').agg({
        'solution': 'first',
        'depthCat': 'first',
        'lon': 'first',
        'lat': 'first',
        'obs_wtd': 'mean',
        'sim_wtd': 'mean'
    })
    mean_bias = mean_bias.reset_index()[['solution', 'wellID','depthCat', 'obs_wtd', 'sim_wtd']]
    mean_bias['bias'] = mean_bias['sim_wtd'] - mean_bias['obs_wtd']
    mean_bias.to_parquet(dataDir / 'mean_bias.parquet')

def calculate_kge_by_station(validation_df):
    def calculate_kge(group):
        obs = group['obs_wtd']
        if len(obs) <= 6:
            return np.nan
        sim = group['sim_wtd']
        cc = np.corrcoef(obs, sim)[0, 1]
        obs_std, sim_std = np.std(obs), np.std(sim)
        obs_mean, sim_mean = np.mean(obs), np.mean(sim)
        if obs_std == 0 or obs_mean == 0:
            return np.nan
        alpha = sim_std / obs_std
        beta = sim_mean / obs_mean
        kge = 1 - np.sqrt((cc - 1)**2 + (alpha - 1)**2 + (beta - 1)**2)
        return kge

    kge_by_station = validation_df.groupby('wellID', group_keys=False).apply(calculate_kge)
    kge_by_station = kge_by_station.dropna()
    kge_by_station = kge_by_station.reset_index()
    kge_by_station = kge_by_station.rename(columns={0: 'KGE'})
    kge_by_station = kge_by_station.merge(validation_df[['wellID', 'solution', 'depthCat', 'lat', 'lon']].drop_duplicates(), on='wellID', how='left')
    kge_by_station.to_parquet(dataDir / 'kge_by_station.parquet')
    kge_by_station[['solution', 'wellID','depthCat','lat','lon','KGE']]
    kge_by_station.to_parquet(dataDir / 'kge_by_station.parquet')
    
kge_df = calculate_kge_by_station(validation_df)
calculate_mean_bias(validation_df)