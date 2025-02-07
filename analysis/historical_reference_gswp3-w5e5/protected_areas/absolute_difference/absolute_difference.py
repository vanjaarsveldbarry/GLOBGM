from pathlib import Path
import pandas as pd
import geopandas as gpd
import matplotlib.pyplot as plt
from mpl_toolkits.axes_grid1 import make_axes_locatable
from geodatasets import get_path

path = get_path("naturalearth.land")
df_base = gpd.read_file(path)

dataDir = Path('/scratch-shared/globgm_scratch/analysis/historical_reference_gswp3-w5e5/protected_areas/output')
saveDir = Path('/scratch-shared/globgm_scratch/analysis/historical_reference_gswp3-w5e5/protected_areas/plots')
saveDir.mkdir(parents=True, exist_ok=True)

df_no_pump = pd.read_parquet(dataDir / 'no_pump_protected_areas.parquet')[['pa_id', '2019-12']]
df_with_pump = pd.read_parquet(dataDir / 'with_pump_protected_areas.parquet')[['pa_id', '2019-12']]

gdf = gpd.read_file(dataDir.parent / 'data/pa_groundwatershed_summary.gpkg')
gdf = gdf.reset_index().rename(columns={'index': 'pa_id'})
gdf = gdf[gdf['pa_id'].isin(df_with_pump['pa_id'])]
gdf = gdf.merge(df_with_pump, on='pa_id', how='left').rename(columns={'2019-12': 'with_pump'})
gdf = gdf.merge(df_no_pump, on='pa_id', how='left').rename(columns={'2019-12': 'no_pump'})
gdf['absolute_difference'] = gdf['no_pump'] - gdf['with_pump']
gdf = gdf.sort_values(by='absolute_difference', ascending=False)

# Define the latitude and longitude boundaries
# lat_min, lat_max = -44, -10
# lon_min, lon_max = 113, 154
# lat_min, lat_max = -35, -22
# lon_min, lon_max = 16, 33
lat_min, lat_max = 32, 49
lon_min, lon_max = -125, -114
# lat_min, lat_max = -60, 90
# lon_min, lon_max = -180, 180

# Clip the GeoDataFrame to the specified boundaries
gdf = gdf.cx[lon_min:lon_max, lat_min:lat_max]
df_base = df_base.cx[lon_min:lon_max, lat_min:lat_max]

fig, ax = plt.subplots(1, 1, figsize=(10, 10))
divider = make_axes_locatable(ax)
cax = divider.append_axes("right", size="5%", pad=0.1)

df_base.plot(ax=ax, color='lightgrey')
gdf.plot(column='absolute_difference', cmap='seismic_r', linewidth=None, ax=ax, vmin=-0.0001, vmax=0.0001)

sm = plt.cm.ScalarMappable(cmap='seismic_r', norm=plt.Normalize(vmin=-0.0001, vmax=0.0001))
sm._A = []
cbar = fig.colorbar(sm, cax=cax)

ax.set_xlim(lon_min, lon_max)
ax.set_ylim(lat_min, lat_max)

ax.set_title('Protected Areas - Absolute Difference (No Pump vs With Pump)', fontsize=15)
ax.set_xlabel('Longitude')
ax.set_ylabel('Latitude')
plt.savefig(saveDir / 'absolute_difference.png', dpi=300)