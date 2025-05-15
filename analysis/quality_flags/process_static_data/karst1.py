import xarray as xr
from pathlib import Path
import geopandas as gpd
import rasterio
from rasterio.features import rasterize
import numpy as np
import sys

data_dir = Path(sys.argv[1])


shapefile_path = data_dir / "WHYMAP_WOKAM_v1/WHYMAP_WOKAM/shp/whymap_karst__v1_poly.shp"
karst_gdf = gpd.read_file(shapefile_path)
output_raster_path = data_dir / "karst_raster.tif"
with xr.open_dataset(data_dir.parent / "mountains.nc") as ds:
    resolution = abs(ds['longitude'][1] - ds['longitude'][0])  # Assuming uniform grid
    resolution = float(resolution.values)  # Convert to float if necessary
# Get the bounds of the GeoDataFrame
bounds = karst_gdf.total_bounds
minx, miny, maxx, maxy = bounds

# Create a transform and shape for the raster
transform = rasterio.transform.from_bounds(minx, miny, maxx, maxy, 
                                            int((maxx - minx) / resolution), 
                                            int((maxy - miny) / resolution))
out_shape = (int((maxy - miny) / resolution), int((maxx - minx) / resolution))

# Rasterize the GeoDataFrame
raster = rasterize(
    ((geom, 1) for geom in karst_gdf.geometry),
    out_shape=out_shape,
    transform=transform,
    fill=0,
    dtype=np.uint8
)

# Write the raster to a file
with rasterio.open(
    output_raster_path,
    "w",
    driver="GTiff",
    height=raster.shape[0],
    width=raster.shape[1],
    count=1,
    dtype=raster.dtype,
    crs=karst_gdf.crs,
    transform=transform,
) as dst:
    dst.write(raster, 1)
    

