import geopandas as gpd
import os
from pathlib import Path
import pandas as pd
shapefile_dir = Path('/scratch-shared/globgm_scratch/analysis/cmip6_runs/hotspots_trends/data/hotspots_geometry/shapefiles')

gdfs = []
for filepath in shapefile_dir.glob('*.shp'):
    name = filepath.stem
    gdf = gpd.read_file(filepath)
    gdf['name'] = name
    gdf = gdf.dissolve(by='name').reset_index()
    gdf = gdf[['name', 'geometry', 'km2']]
    gdfs.append(gdf)

combined_gdf = gpd.GeoDataFrame(pd.concat(gdfs, ignore_index=True))
print(combined_gdf)
combined_gdf.to_file('/scratch-shared/globgm_scratch/analysis/cmip6_runs/hotspots_trends/data/hotspots_geometry/hotspots.gpkg', driver='GPKG')