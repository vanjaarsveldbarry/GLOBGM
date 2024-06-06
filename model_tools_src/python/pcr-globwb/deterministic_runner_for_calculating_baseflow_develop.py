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
output_folder = "/scratch-shared/edwinaha/test_baseflow/test/"
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
tile_pcraster_map_folder = "/scratch-shared/edwinbar/globgm_tile_map_files_for_arfan/map_input/steady-state/average/tile_%03i-163/steady-state_only/maps/"

# clone map
clone_map = "/projects/0/dfguu/users/edwin/data/pcrglobwb_input_arise/develop/global_30sec/routing/surface_water_bodies/version_2020-05-XX/lddsound_30sec_version_202005XX.map"


# parameters for the river package top layer
river_bed_conductance  = None
print()
for tile in range(1, 163+1):
    print(tile)
    tile_folder = tile_pcraster_map_folder %(tile)
    river_bed_conductance_input_file = tile_folder + "/bed_conductance_used.map"
    
    if tile == 1: 
        river_bed_conductance = vos.readPCRmapClone(v = river_bed_conductance_input_file, cloneMapFileName = clone_map, tmpDir = tmp_dir)
    else:
        river_bed_conductance = pcr.cover(river_bed_conductance, vos.readPCRmapClone(v = river_bed_conductance_input_file, cloneMapFileName = clone_map, tmpDir = tmp_dir))
    if tile == 16: pcr.aguila(river_bed_conductance)    
    if tile == 163: pcr.aguila(river_bed_conductance)    


river_stage_elevation  = None
river_bottom_elevation = None
