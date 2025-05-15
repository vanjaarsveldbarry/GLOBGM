import geopandas as gpd
import polars as pl
import xarray as xr
from pathlib import Path
import numpy as np
import time
from datetime import date
from datetime import date, timedelta
from pandas import to_datetime 


startTime, endTime = '1960', '2019'
min_obs_freq=36
sim_data_dir = Path(f'/projects/prjs1222/globgm_output/reference_gswp3-w5e5/historical_with_pump/merged')
obsFile = '/projects/prjs1222/GLOBGM/analysis/historical_reference_gswp3-w5e5/validation/data/observed_gwh_withlayers_data.parquet'
layerFile = '/projects/prjs1222/GLOBGM/analysis/historical_reference_gswp3-w5e5/validation/data/observed_gwh_withlayers_points.gpkg'
saveDir = Path(f'/projects/prjs1222/scratch_backup/globgm_scratch/analysis/historical_reference_gswp3-w5e5/validation/output')
saveDir.mkdir(parents=True, exist_ok=True)

def _read_obs(simFile, obsFile, startTime, endTime):
    obs_data_ds = pl.read_parquet(obsFile)
    obs_data_ds = obs_data_ds.with_columns([(pl.col('date').cast(pl.Date)).alias('date')])
    sim_ds = xr.open_zarr(simFile)
    bounds = (sim_ds['longitude'].min().item(), sim_ds['longitude'].max().item(),  
              sim_ds['latitude'].min().item(), sim_ds['latitude'].max().item())
    filtered_df = obs_data_ds.filter((pl.col('lon') >= bounds[0]) & (pl.col('lon') <= bounds[1]) & (pl.col('lat') >= bounds[2]) & (pl.col('lat') <= bounds[3]))
    filtered_df = filtered_df.filter((pl.col('date') >= to_datetime(f'{startTime}-01-01')) & (pl.col('date') <= to_datetime(f'{endTime}-01-01')))  
    filtered_df = filtered_df.rename({'gwh_m': 'obs_wtd', 'date': 'time'})
    coords = filtered_df.group_by('id_gerbil').agg([pl.col('lon').first(), pl.col('lat').first()])
    x_coords = xr.DataArray(coords['lon'], dims=['id_gerbil'], coords={'id_gerbil': coords['id_gerbil']})
    y_coords = xr.DataArray(coords['lat'], dims=['id_gerbil'], coords={'id_gerbil': coords['id_gerbil']})
    return filtered_df, x_coords, y_coords

def reindex_time(obs_data_ds, startTime, endTime):
    date_range = pl.date_range(date(int(startTime), 1, 1), date(int(endTime), 12, 1), "1mo", eager=True)
    def month_end(d):
        next_month = d.replace(day=28) + timedelta(days=4)  # this will never fail
        return next_month - timedelta(days=next_month.day)
    date_range = [month_end(d) for d in date_range]
    time_index = pl.DataFrame({"time": date_range})
    unique_wells = obs_data_ds.select(['id_gerbil', 'lon', 'lat', 'layer_no']).unique()
    join_time = time_index.join(unique_wells, how='cross')
    reindexed_df = join_time.join(obs_data_ds, on=['id_gerbil', 'time'], how='left')
    reindexed_df = reindexed_df['id_gerbil', 'time', 'lon', 'lat', 'obs_wtd', 'layer_no']
    return reindexed_df

def _read_sim(simFile, startTime, endTime, x_coords, y_coords):
    sim_ds = xr.open_zarr(simFile).rename({'latitude': 'lat', 'longitude': 'lon'}).sel(time=slice(f"{startTime}-01-01", f"{endTime}-12-31"))
    # sim_ds = xr.open_zarr(simFile).rename({'latitude': 'lat', 'longitude': 'lon'}).sel(time=slice(f"2000-01-01", f"2000-12-31"))
    sim_ds = sim_ds.sel(lon=x_coords, lat=y_coords, method='nearest')
    sim_ds = pl.from_pandas(sim_ds.to_dataframe().reset_index())
    sim_ds = sim_ds.cast({pl.Datetime: pl.Date})
    return sim_ds

def _create_validation_df(sim_ds, obs_data_ds):
    combined_df = obs_data_ds.select(['id_gerbil', 'time', 'obs_wtd', 'layer_no']).join(sim_ds, on=['id_gerbil', 'time'], how='inner')
    combined_df = combined_df.with_columns(pl.when(pl.col('layer_no') == 1).then(pl.col('l1_wtd')).when(pl.col('layer_no') == 2).then(pl.col('l2_wtd')).alias('sim_wtd'))
    combined_df = combined_df.select(['id_gerbil', 'lat', 'lon', 'time', 'layer_no', 'obs_wtd', 'sim_wtd'])
    combined_df = combined_df.drop_nulls(subset=['sim_wtd', 'obs_wtd'])
    combined_df = combined_df.with_columns(pl.col('id_gerbil').count().over('id_gerbil').alias('obs_freq'))
    combined_df = combined_df.with_columns(pl.col('obs_wtd').mean().over('id_gerbil').alias('mean_obs_wtd'))
    combined_df = combined_df.with_columns(pl.when(pl.col('mean_obs_wtd') <= 0).then(pl.lit('<0'))
                                    .when((pl.col('mean_obs_wtd') > 0) & (pl.col('mean_obs_wtd') <= 5)).then(pl.lit('0_5'))
                                    .when((pl.col('mean_obs_wtd') > 5) & (pl.col('mean_obs_wtd') <= 10)).then(pl.lit('5_10'))
                                    .when((pl.col('mean_obs_wtd') > 10) & (pl.col('mean_obs_wtd') <= 20)).then(pl.lit('10_20'))
                                    .when((pl.col('mean_obs_wtd') > 20) & (pl.col('mean_obs_wtd') <= 60)).then(pl.lit('20_60'))
                                    .when(pl.col('mean_obs_wtd') > 60).then(pl.lit('>60'))
                                    .otherwise(pl.lit('Other')).alias('depthCat'))
    return combined_df

all_validation_dfs = []

obs_data_ds, x_coords, y_coords = _read_obs(sim_data_dir / 'wtd.zarr', obsFile, startTime, endTime)
obs_data_ds = reindex_time(obs_data_ds, startTime, endTime)
sim_ds = _read_sim(sim_data_dir / f'wtd.zarr', startTime, endTime, x_coords, y_coords)
validation_df = _create_validation_df(sim_ds, obs_data_ds)
validation_df = validation_df.sort('id_gerbil')
print(validation_df.select(pl.all()))
validation_df = validation_df.filter(pl.col('obs_freq') > min_obs_freq)
validation_df.write_parquet(saveDir / 'timeseries_wtd.parquet')