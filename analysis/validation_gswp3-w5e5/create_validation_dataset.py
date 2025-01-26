import geopandas as gpd
import polars as pl
import xarray as xr
from pathlib import Path
import numpy as np
import time
from datetime import date
from datetime import date, timedelta

solutions = [1, 2, 3]
startTime, endTime = '1960', '2019'
sim_data_dir = Path('/scratch-shared/_bvjaarsveld1/temp/data')
obsFile = '/home/bvjaarsveld1/projects/workflow/GLOBGM/analysis/validation_gswp3-w5e5/data/observed_gw_all.parquet'
saveDir = Path('/scratch-shared/_bvjaarsveld1/temp/validation/output')
saveDir.mkdir(parents=True, exist_ok=True)

def _read_obs(simFile, obsFile, startTime, endTime):
    obs_data_ds = pl.read_parquet(obsFile)
    sim_ds = xr.open_zarr(simFile)
    bounds = (
        sim_ds['longitude'].min().item(), 
        sim_ds['longitude'].max().item(),  
        sim_ds['latitude'].min().item(), 
        sim_ds['latitude'].max().item()
    )
    filtered_df = obs_data_ds.filter(
        (pl.col('lon') >= bounds[0]) & (pl.col('lon') <= bounds[1]) & 
        (pl.col('lat') >= bounds[2]) & (pl.col('lat') <= bounds[3])
    )
    filtered_df = filtered_df.filter(
        (pl.col('date') >= f'{startTime}-01-01') & (pl.col('date') <= f'{endTime}-12-31')
    )
    coords = filtered_df.group_by('wellID').agg([pl.col('lon').first(), pl.col('lat').first()])
    x_coords = xr.DataArray(coords['lon'], dims=['wellID'], coords={'wellID': coords['wellID']})
    y_coords = xr.DataArray(coords['lat'], dims=['wellID'], coords={'wellID': coords['wellID']})
    return filtered_df, x_coords, y_coords

def reindex_time(obs_data_ds, startTime, endTime):
    date_range = pl.date_range(date(int(startTime), 1, 1), date(int(endTime), 12, 1), "1mo", eager=True)
    
    def month_end(d):
        next_month = d.replace(day=28) + timedelta(days=4)  # this will never fail
        return next_month - timedelta(days=next_month.day)
    
    date_range = [month_end(d) for d in date_range]
    time_index = pl.DataFrame({"time": date_range})
    
    # Extract unique wellID, lon, and lat
    unique_wells = obs_data_ds.select(['wellID', 'lon', 'lat']).unique()
    
    # Cross join time_index with unique_wells to create all combinations
    join_time = time_index.join(unique_wells, how='cross')
    
    # Join the expanded time index with the original data
    reindexed_df = join_time.join(obs_data_ds, on=['wellID', 'time'], how='left')
    
    return reindexed_df

def _read_sim(simFile, startTime, endTime, x_coords, y_coords):
    sim_ds = xr.open_zarr(simFile).rename({'latitude': 'lat', 'longitude': 'lon'}).sel(time=slice(f"{startTime}-01-01", f"{endTime}-12-31"))
    sim_ds = sim_ds.sel(lon=x_coords, lat=y_coords, method='nearest')
    sim_ds = xr.where(sim_ds.l1_wtd.notnull(), sim_ds.l1_wtd, sim_ds.l2_wtd)
    sim_ds.name = 'sim_wtd'
    return sim_ds

def _create_validation_df(sim_ds, obs_data_ds):
    sim_ds = pl.from_pandas(sim_ds.to_dataframe().reset_index())
    sim_ds = sim_ds.cast({pl.Datetime: pl.Date})
    combined_df = obs_data_ds.join(sim_ds, on=['time', 'wellID'])
    combined_df = combined_df.select(['wellID', 'time', 'lon_right', 'lat_right', 'obs_wtd', 'sim_wtd'])
    combined_df = combined_df.rename({'lon_right': 'lon', 'lat_right': 'lat'})
    combined_df = combined_df.with_columns([
        pl.when(pl.col('obs_wtd').is_not_null()).then(pl.col('sim_wtd')).otherwise(None).alias('sim_wtd'),
        pl.when(pl.col('sim_wtd').is_not_null()).then(pl.col('obs_wtd')).otherwise(None).alias('obs_wtd')
    ])
    combined_df = combined_df.drop_nulls(subset=['obs_wtd', 'sim_wtd'])
    return combined_df

all_validation_dfs = []

for solution in solutions:
    obs_data_ds, x_coords, y_coords = _read_obs(sim_data_dir / f's0{solution}_wtd.zarr', obsFile, startTime, endTime)
    obs_data_ds = obs_data_ds.unique(subset=['wellID', 'date'])
    obs_data_ds = obs_data_ds.sort(by=['wellID', 'date'])
    obs_data_ds = obs_data_ds.with_columns([(pl.col('date').cast(pl.Date)).alias('date')])
    obs_data_ds = obs_data_ds.rename({'gwh_m': 'obs_wtd', 'date': 'time'})
    obs_data_ds = obs_data_ds.with_columns(pl.col("time").dt.month_end().alias("time"))
    print('Start Time Indexing')
    obs_data_ds = reindex_time(obs_data_ds, startTime, endTime)
    print('Done Time Indexing')
    sim_ds = _read_sim(sim_data_dir / f's0{solution}_wtd.zarr', startTime, endTime, x_coords, y_coords)
    print('Done sim ds')
    validation_df = _create_validation_df(sim_ds, obs_data_ds)
    print('validation_df')
    validation_df = validation_df.with_columns(pl.lit(solution).alias('solution'))
    all_validation_dfs.append(validation_df)
combined_df = pl.concat(all_validation_dfs)
print('concat')

combined_df = combined_df.with_columns(pl.when(pl.col('obs_wtd') < 5).then(pl.lit('0_5'))
                                    .when((pl.col('obs_wtd') >= 5) & (pl.col('obs_wtd') < 10)).then(pl.lit('5_10'))
                                    .when((pl.col('obs_wtd') >= 10) & (pl.col('obs_wtd') < 20)).then(pl.lit('10_20'))
                                    .when((pl.col('obs_wtd') >= 20) & (pl.col('obs_wtd') < 60)).then(pl.lit('20_60'))
                                    .when(pl.col('obs_wtd') >= 60).then(pl.lit('>60'))
                                    .otherwise(pl.lit('Other')).alias('depthCat'))
print('combined')
combined_df.write_parquet(saveDir / 'timeseries_wtd.parquet')
