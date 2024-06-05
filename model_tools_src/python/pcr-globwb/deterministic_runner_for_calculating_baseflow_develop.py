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
modflow6_output_folder   = "/scratch-shared/marfan/globgm_ss/output/average/gswp3-w5e5/ss/mf6_post/"
# ~ modflow6_output_folder = sys.argv[2]

# the folder that contain the pcraster maps in tiles
tile_pcraster_map_folder = "/scratch-shared/edwinbar/globgm_tile_map_files_for_arfan/map_input/steady-state/average/tile_001-163/steady-state_only/maps/"

# clone map
clone_map = "/projects/0/dfguu/users/edwin/data/pcrglobwb_input_arise/develop/global_30sec/routing/surface_water_bodies/version_2020-05-XX/lddsound_30sec_version_202005XX.map"


# parameters for the river package top layer
river_bed_conductance  =  
river_stage_elevation  =
river_bottom_elevation =




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
    



# get the river package outflow


