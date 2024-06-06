#!/usr/bin/env python
# -*- coding: utf-8 -*-
#

import os
import shutil
import sys
import datetime

import pcraster as pcr

import globgm.virtualOS as vos

import globgm.various_tools as tools

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
river_bed_conductance  = tools.read_from_tile_folder(tile_pcraster_map_folder = tile_pcraster_map_folder, pcraster_map_file_name = "bed_condutance_used.map", clone_map = clone_map)

river_stage_elevation  = None
river_bottom_elevation = None

