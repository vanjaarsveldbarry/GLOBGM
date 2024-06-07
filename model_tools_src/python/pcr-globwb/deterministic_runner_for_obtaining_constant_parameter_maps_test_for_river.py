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
output_folder = "/scratch-shared/edwinaha/test_fixed_parameter_maps/test/"
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


# parameters for the river package
global_output_file = output_folder + "/" + "river_bed_conductance.map"
river_bed_conductance  = tools.read_from_tile_folder(tile_pcraster_map_folder = tile_pcraster_map_folder, pcraster_map_file_name = "bed_conductance_used.map", clone_map = clone_map, tmp_dir = tmp_dir, saved_global_file = global_output_file)

# ~ global_output_file = output_folder + "/" + "river_stage_elevation.map"
# ~ river_stage_elevation  = tools.read_from_tile_folder(tile_pcraster_map_folder = tile_pcraster_map_folder, pcraster_map_file_name = "surface_water_elevation.map", clone_map = clone_map, tmp_dir = tmp_dir, saved_global_file = global_output_file)

global_output_file = output_folder + "/" + "river_bottom_elevation.map"
river_bottom_elevation = tools.read_from_tile_folder(tile_pcraster_map_folder = tile_pcraster_map_folder, pcraster_map_file_name = "surface_water_bed_elevation_used.map", clone_map = clone_map, tmp_dir = tmp_dir, saved_global_file = global_output_file)


# bottom layer elevations
# - uppermost
global_output_file = output_folder + "/" + "bottom_uppermost_layer.map"
bottom_uppermost_layer = tools.read_from_tile_folder(tile_pcraster_map_folder = tile_pcraster_map_folder, pcraster_map_file_name = "bottom_uppermost_layer.map", clone_map = clone_map, tmp_dir = tmp_dir, saved_global_file = global_output_file)
# - lowermost
global_output_file = output_folder + "/" + "bottom_lowermost_layer.map"
bottom_lowermost_layer  = tools.read_from_tile_folder(tile_pcraster_map_folder = tile_pcraster_map_folder, pcraster_map_file_name = "bottom_lowermost_layer.map", clone_map = clone_map, tmp_dir = tmp_dir, saved_global_file = global_output_file)


