#!/usr/bin/env python
# -*- coding: utf-8 -*-
#

import os
import shutil
import sys
import datetime

import pcraster as pcr

import globgm.virtualOS as vos

# output folder for this analysis
output_folder = "/scratch-shared/edwinaha/test_baseflow_and_storage/test/"
# ~ output_folder = sys.argv[1]

# make output and temporary folders
if os.path.exists(output_folder): shutil.rmtree(output_folder)
os.makedirs(output_folder)
# - make temporary folder
tmp_dir = output_folder +  "/tmp/"
os.makedirs(tmp_dir)


# the folder that contains modflow 6 output runs
modflow6_output_folder = "/scratch-shared/marfan/globgm_ss/output/average/gswp3-w5e5/ss/mf6_post/"
# ~ modflow6_output_folder = sys.argv[2]

# clone map
clone_map = "/projects/0/dfguu/users/edwin/data/pcrglobwb_input_arise/develop/global_30sec/routing/surface_water_bodies/version_2020-05-XX/lddsound_30sec_version_202005XX.map"

# specific yield
specificYield_input_file  = "/projects/0/dfguu/users/edwin/data/pcrglobwb_input_arise/develop/global_30sec/groundwater/properties/version_202312XX/specific_yield_aquifer_30sec_filled_v20231205.map"
specificYield = pcr.readmap(specificYield_input_file)
aquiferLayerPrimaryStorageCoefficient = 0.003

# bottom layer elevation files
bottom_uppermost_layer_file = ""
bottom_uppermost_layer_elevation = pcr.readmap(bottom_layer_upper_file)
bottom_lowermost_layer_file = ""
bottom_lowermost_layer_elevation = pcr.readmap(bottom_layer_lower_file)


# obtain the groundwater head for the top layer (layer 2 of the pcraster version of GLOBGM)
groundwaterHead2 = None
for region in range(1, 4):
    
    # Note that the output from the MODFLOW6 has the convention that l1 (layer 1) is for the top one, while the pcraster version of GLOBGM use the l1 as the bottom one
    ncFile = modflow6_output_folder + "/s0" + str(region) + "_hds_ss_l1.nc"

    print(region)
    
    output = tmp_dir + 'temp.map'
    warp = vos.gdalwarpPCR_with_mv(input = ncFile, output = output, cloneOut = clone_map, tmpDir = tmp_dir, isLddMap = False, isNominalMap = False, miss_val = "-9999")
    groundwaterHead2_inp = pcr.readmap(output)


    if region == 1:
        groundwaterHead2 = groundwaterHead2_inp
    else:
        groundwaterHead2 = pcr.cover(groundwaterHead2, groundwaterHead2_inp)

    # ~ pcr.aguila(groundwaterHead2)



# obtain the groundwater head for the bottom layer (layer 1 of the pcraster version of GLOBGM)
groundwaterHead1 = None
for region in range(1, 4):
    
    # Note that the output from the MODFLOW6 has the convention that l1 (layer 1) is for the top one, while the pcraster version of GLOBGM use the l1 as the bottom one
    ncFile = modflow6_output_folder + "/s0" + str(region) + "_hds_ss_l2.nc"

    print(region)
    
    output = tmp_dir + 'temp.map'
    warp = vos.gdalwarpPCR_with_mv(input = ncFile, output = output, cloneOut = clone_map, tmpDir = tmp_dir, isLddMap = False, isNominalMap = False, miss_val = "-9999")
    groundwaterHead1_inp = pcr.readmap(output)


    if region == 1:
        groundwaterHead1 = groundwaterHead1_inp
    else:
        groundwaterHead1 = pcr.cover(groundwaterHead1, groundwaterHead1_inp)

    # ~ pcr.aguila(groundwaterHead1)
    


# calculating the corresponding groundwater storage for the top layer
storage_coefficient_2 = specificYield
storGroundwater2 = pcr.max(0.0, groundwaterHead2 - bottom_uppermost_layer_elevation) * storage_coefficient_2
# ~ pcr.aguila(storGroundwater2)

# calculating the corresponding groundwater storage for the bottom layer
confined_aquifer = pcr.cover(pcr.defined(storGroundwater2), pcr.boolean(0.0))
storage_coefficient_1 = pcr.ifthenelse(confined_aquifer, aquiferLayerPrimaryStorageCoefficient, specificYield)
storGroundwater1 = pcr.max(0.0, groundwaterHead1 - bottom_lowermost_layer_elevation) * storage_coefficient_1
# ~ pcr.aguila(storGroundwater1)

totalStorGroundwater = pcr.cover(storGroundwater2, 0.0) + pcr.cover(storGroundwater1, 0.0)
# ~ pcr.aguila(totalStorGroundwater)
pcr.report(totalStorGroundwater, output_folder + "/total_stor_groundwater.map")

