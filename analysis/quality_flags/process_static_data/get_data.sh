#!/bin/bash -l

source ${HOME}/.bashrc
mamba activate globgm

directory=/projects/prjs1222/scratch_backup/globgm_scratch/analysis/quality_flags/data/static/_raw
scripts=/projects/prjs1222/GLOBGM/analysis/quality_flags/process_static_data

mkdir -p $directory
cd $directory
#Mountains
# cp /projects/prjs1222/globgm_input/_data/globgm_input/topography_30sec_03sec/dem_standard_deviation_topography_parameters_30sec_february_2021_global_covered_with_zero.nc $directory
# python $scripts/mountains.py $directory

#Permafrost
# wget -O PZI.flt http://www.geo.uzh.ch/microsite/cryodata/pf_global/PZI.flt
# wget -O PZI.hdr http://www.geo.uzh.ch/microsite/cryodata/pf_global/PZI.hdr
# gdal_translate -of netCDF PZI.flt PZI.nc
# python $scripts/perfamforst.py $directory

#Karst
# wget -O WHYMAP_WOKAM_v1.zip https://download.bgr.de/bgr/grundwasser/whymap/shp/WHYMAP_WOKAM_v1.zip
# unzip WHYMAP_WOKAM_v1.zip -d WHYMAP_WOKAM_v1
# python $scripts/karst1.py $directory
# gdal_translate -of netCDF $directory/karst_raster.tif $directory/karst_temp.nc
# python $scripts/karst2.py $directory

# mkdir -p $(dirname $directory)/karst_shp
# find $directory/WHYMAP_WOKAM_v1/WHYMAP_WOKAM/shp -type f -name "*whymap_karst__v1_poly*" -exec cp {} $(dirname $directory)/karst_shp/ \;

#Create qulaity control map
# python $scripts/construct_quality_dataset.py $directory