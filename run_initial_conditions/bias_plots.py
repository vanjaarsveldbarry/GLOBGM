import pandas as pd
from pathlib import Path
import seaborn as sns
import geopandas as gpd
from shapely.geometry import Point
import matplotlib.pyplot as plt
from mpl_toolkits.axes_grid1 import make_axes_locatable


dataPath = Path('/scratch-shared/_bvjaarsveld1/output_initial_conditions/gswp3-w5e5/tr_with_pump/mf6_post/output_validation')

bias_points_final = pd.DataFrame()

for solution in [1, 2, 3]:
    # Read and preprocess data for layer 2
    df_layer2 = pd.read_csv(dataPath / f'tr_with_pump_s0{solution}_layer2_bias.csv')
    df_layer2 = df_layer2[['lat', 'lon', 'bias43']]
    # Read and preprocess data for layer 1
    df_layer1 = pd.read_csv(dataPath / f'tr_with_pump_s0{solution}_layer1_bias.csv')
    df_layer1 = df_layer1[['lat', 'lon', 'bias43']]
    df_combined = pd.concat([df_layer1, df_layer2])
    df_combined['Solution'] = solution
    bias_points_final = pd.concat([bias_points_final, df_combined])
    # Create a GeoDataFrame from the bias points
    geometry = [Point(xy) for xy in zip(bias_points_final['lon'], bias_points_final['lat'])]
    gdf = gpd.GeoDataFrame(bias_points_final, geometry=geometry)

# Plot the GeoDataFrame

# Load the world map
world = gpd.read_file(gpd.datasets.get_path('naturalearth_lowres'))

# Plot the GeoDataFrame
fig, ax = plt.subplots(1, 1, figsize=(10, 6))
world.plot(ax=ax, color='lightgrey')

# Create a divider for the existing axes instance
divider = make_axes_locatable(ax)
cax = divider.append_axes("right", size="5%", pad=0.1)

# Plot the GeoDataFrame with a smaller color bar
gdf.plot(column='bias43', ax=ax, legend=True, cmap='turbo', markersize=5, vmin=-20, vmax=20, cax=cax)

plt.title('Bias Points')
plt.xlabel('Longitude')
plt.ylabel('Latitude')
plt.tight_layout()
plt.savefig('/scratch-shared/_bvjaarsveld1/_temp/bias_points_plot_20.png')
# Plot the GeoDataFrame
world = gpd.read_file(gpd.datasets.get_path('naturalearth_lowres'))

fig, ax = plt.subplots(1, 1, figsize=(10, 6))
divider = make_axes_locatable(ax)
cax = divider.append_axes("right", size="5%", pad=0.1)
world.plot(ax=ax, color='lightgrey')
gdf.plot(column='bias43', ax=ax, legend=True, cmap='turbo', markersize=20, vmin=-20, vmax=20, cax=cax)
plt.title('Bias Points')
plt.xlabel('Longitude')
plt.ylabel('Latitude')
plt.tight_layout()
ax.set_xlim([-130, -60])
ax.set_ylim([20, 55])
plt.savefig('/scratch-shared/_bvjaarsveld1/_temp/bias_points_plot_US.png')

# Plot the CDF of bias43 using seaborn
gdf = gdf[['Solution', 'bias43']]
plt.figure(figsize=(10, 6))
ax = sns.ecdfplot(data=gdf, x='bias43', hue='Solution', palette='tab10')
plt.title('CDF of Bias43 by Solution')
plt.xlabel('Bias43')
plt.ylabel('ECDF')
plt.tight_layout()
plt.xlim(-50, 50)
plt.axvline(x=0, color='black', linestyle='--', linewidth=1)
plt.savefig('/scratch-shared/_bvjaarsveld1/_temp/bias_points_cdf.png')

