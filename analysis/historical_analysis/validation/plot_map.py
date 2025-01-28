import geopandas as gpd
import pandas as pd
import xarray as xr
from pathlib import Path
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt
import contextily as ctx

test = 'jarno'
dataDir = Path(f'/scratch-shared/_bvjaarsveld1/temp/validation/output')

metric_points = pd.read_parquet(dataDir / 'jarno/mean_bias_wtd.parquet')
metric_points = metric_points['id_gerbil'].unique()

points = gpd.read_file('/scratch-shared/_bvjaarsveld1/temp/validation/output/jarno/filtered_layers.gpkg')
points = points[points['id_gerbil'].isin(metric_points)]
# Plot the points with a grey base map
fig, ax = plt.subplots(1, 1, figsize=(10, 10))
points.plot(ax=base, marker='o', color='red', markersize=5)
ctx.add_basemap(ax, source=ctx.providers.Stamen.TonerLite, crs=points.crs)
plt.savefig('/home/bvjaarsveld1/projects/workflow/GLOBGM/analysis/validation_gswp3-w5e5/plots/points_map.png')
