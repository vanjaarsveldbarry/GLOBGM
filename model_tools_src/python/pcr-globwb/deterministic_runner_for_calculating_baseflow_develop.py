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
modflow6_output_folder = "/scratch-shared/marfan/globgm_ss/output/average/gswp3-w5e5/ss/mf6_post/"
# ~ modflow6_output_folder = sys.argv[2]

# clone map
clone_map = "/projects/0/dfguu/users/edwin/data/pcrglobwb_input_arise/develop/global_30sec/routing/surface_water_bodies/version_2020-05-XX/lddsound_30sec_version_202005XX.map"

# cell area (m2)
cell_area_file = "/projects/0/dfguu/users/edwin/data/pcrglobwb_input_arise/develop/others/estimate_cell_dimension/30sec/cdo_gridarea_30sec.map"
cell_area = pcr.readmap(cell_area_file)


# constant parameters for the river package
river_bed_conductance_file  = ""
river_bed_conductance = pcr.readmap(river_bed_conductance_file)
river_bottom_elevation_file = ""
river_bottom_elevation = pcr.readmap(river_bottom_elevation_file)

# river water level elevation
river_stage_elevation_file  = ""
river_stage_elevation = pcr.readmap(river_stage_elevation_file)


# constant parameters for the drain package
folder_for_the_drain_package = "/scratch-shared/edwinaha/test_fixed_parameter_maps/test/"
drain_conductance_0           = pcr.readmap(folder_for_the_drain_package + "/drain_conductance_elev_0.map" )
drain_conductance_1           = pcr.readmap(folder_for_the_drain_package + "/drain_conductance_elev_1.map" )
drain_conductance_2           = pcr.readmap(folder_for_the_drain_package + "/drain_conductance_elev_2.map" )
drain_conductance_3           = pcr.readmap(folder_for_the_drain_package + "/drain_conductance_elev_3.map" )
drain_conductance_4           = pcr.readmap(folder_for_the_drain_package + "/drain_conductance_elev_4.map" )
drain_conductance_5           = pcr.readmap(folder_for_the_drain_package + "/drain_conductance_elev_5.map" )
drain_conductance_6           = pcr.readmap(folder_for_the_drain_package + "/drain_conductance_elev_6.map" )
drain_conductance_7           = pcr.readmap(folder_for_the_drain_package + "/drain_conductance_elev_7.map" )
drain_conductance_8           = pcr.readmap(folder_for_the_drain_package + "/drain_conductance_elev_8.map ")
drain_conductance_9           = pcr.readmap(folder_for_the_drain_package + "/drain_conductance_elev_9.map" )
drain_conductance_10          = pcr.readmap(folder_for_the_drain_package + "/drain_conductance_elev_10.map")
drain_conductance_11          = pcr.readmap(folder_for_the_drain_package + "/drain_conductance_elev_11.map")
drain_conductance_12          = pcr.readmap(folder_for_the_drain_package + "/drain_conductance_elev_12.map")

drain_elevation_uppermost_0   = pcr.readmap(folder_for_the_drain_package + "/drain_elevation_uppermost_elev_0.map" )
drain_elevation_uppermost_1   = pcr.readmap(folder_for_the_drain_package + "/drain_elevation_uppermost_elev_1.map" )
drain_elevation_uppermost_2   = pcr.readmap(folder_for_the_drain_package + "/drain_elevation_uppermost_elev_2.map" )
drain_elevation_uppermost_3   = pcr.readmap(folder_for_the_drain_package + "/drain_elevation_uppermost_elev_3.map" )
drain_elevation_uppermost_4   = pcr.readmap(folder_for_the_drain_package + "/drain_elevation_uppermost_elev_4.map" )
drain_elevation_uppermost_5   = pcr.readmap(folder_for_the_drain_package + "/drain_elevation_uppermost_elev_5.map" )
drain_elevation_uppermost_6   = pcr.readmap(folder_for_the_drain_package + "/drain_elevation_uppermost_elev_6.map" )
drain_elevation_uppermost_7   = pcr.readmap(folder_for_the_drain_package + "/drain_elevation_uppermost_elev_7.map" )
drain_elevation_uppermost_8   = pcr.readmap(folder_for_the_drain_package + "/drain_elevation_uppermost_elev_8.map ")
drain_elevation_uppermost_9   = pcr.readmap(folder_for_the_drain_package + "/drain_elevation_uppermost_elev_9.map" )
drain_elevation_uppermost_10  = pcr.readmap(folder_for_the_drain_package + "/drain_elevation_uppermost_elev_10.map")
drain_elevation_uppermost_11  = pcr.readmap(folder_for_the_drain_package + "/drain_elevation_uppermost_elev_11.map")
drain_elevation_uppermost_12  = pcr.readmap(folder_for_the_drain_package + "/drain_elevation_uppermost_elev_12.map")

drain_elevation_lowermost_0   = pcr.readmap(folder_for_the_drain_package + "/drain_elevation_lowermost_elev_0.map" )
drain_elevation_lowermost_1   = pcr.readmap(folder_for_the_drain_package + "/drain_elevation_lowermost_elev_1.map" )
drain_elevation_lowermost_2   = pcr.readmap(folder_for_the_drain_package + "/drain_elevation_lowermost_elev_2.map" )
drain_elevation_lowermost_3   = pcr.readmap(folder_for_the_drain_package + "/drain_elevation_lowermost_elev_3.map" )
drain_elevation_lowermost_4   = pcr.readmap(folder_for_the_drain_package + "/drain_elevation_lowermost_elev_4.map" )
drain_elevation_lowermost_5   = pcr.readmap(folder_for_the_drain_package + "/drain_elevation_lowermost_elev_5.map" )
drain_elevation_lowermost_6   = pcr.readmap(folder_for_the_drain_package + "/drain_elevation_lowermost_elev_6.map" )
drain_elevation_lowermost_7   = pcr.readmap(folder_for_the_drain_package + "/drain_elevation_lowermost_elev_7.map" )
drain_elevation_lowermost_8   = pcr.readmap(folder_for_the_drain_package + "/drain_elevation_lowermost_elev_8.map ")
drain_elevation_lowermost_9   = pcr.readmap(folder_for_the_drain_package + "/drain_elevation_lowermost_elev_9.map" )
drain_elevation_lowermost_10  = pcr.readmap(folder_for_the_drain_package + "/drain_elevation_lowermost_elev_10.map")
drain_elevation_lowermost_11  = pcr.readmap(folder_for_the_drain_package + "/drain_elevation_lowermost_elev_11.map")
drain_elevation_lowermost_12  = pcr.readmap(folder_for_the_drain_package + "/drain_elevation_lowermost_elev_12.map")

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



# calculate flow from the river package (unit: m3/day)
# - positive if flow entering aquifer 
# -- from the river package of the top layer 
river_flux_top_layer = pcr.ifthenelse(groundwaterHead2 > river_bottom_elevation, river_bed_conductance * pcr.max(0.0, river_stage_elevation - groundwaterHead2),\
                                                                                 river_bed_conductance * pcr.max(0.0, river_stage_elevation - river_bottom_elevation))
# -- from the river package of the bottom layer 
river_flux_bot_layer = pcr.ifthenelse(groundwaterHead1 > river_bottom_elevation, river_bed_conductance * pcr.max(0.0, river_stage_elevation - groundwaterHead1),\
                                                                                 river_bed_conductance * pcr.max(0.0, river_stage_elevation - river_bottom_elevation))
total_river_flux = river_flux_top_layer + river_flux_bot_layer


# calculate flow from the drain package (unit: m3/day)
# - positive if flow entering aquifer 
# -- from the top layer
drain_flux_top_layer_elevation_0  = pcr.scalar(-1.0) * drain_conductance_0  * pcr.max(0.0, groundwaterHead2 - drain_elevation_uppermost_0 )
drain_flux_top_layer_elevation_1  = pcr.scalar(-1.0) * drain_conductance_1  * pcr.max(0.0, groundwaterHead2 - drain_elevation_uppermost_1 )
drain_flux_top_layer_elevation_2  = pcr.scalar(-1.0) * drain_conductance_2  * pcr.max(0.0, groundwaterHead2 - drain_elevation_uppermost_2 )
drain_flux_top_layer_elevation_3  = pcr.scalar(-1.0) * drain_conductance_3  * pcr.max(0.0, groundwaterHead2 - drain_elevation_uppermost_3 )
drain_flux_top_layer_elevation_4  = pcr.scalar(-1.0) * drain_conductance_4  * pcr.max(0.0, groundwaterHead2 - drain_elevation_uppermost_4 )
drain_flux_top_layer_elevation_5  = pcr.scalar(-1.0) * drain_conductance_5  * pcr.max(0.0, groundwaterHead2 - drain_elevation_uppermost_5 )
drain_flux_top_layer_elevation_6  = pcr.scalar(-1.0) * drain_conductance_6  * pcr.max(0.0, groundwaterHead2 - drain_elevation_uppermost_6 )
drain_flux_top_layer_elevation_7  = pcr.scalar(-1.0) * drain_conductance_7  * pcr.max(0.0, groundwaterHead2 - drain_elevation_uppermost_7 )
drain_flux_top_layer_elevation_8  = pcr.scalar(-1.0) * drain_conductance_8  * pcr.max(0.0, groundwaterHead2 - drain_elevation_uppermost_8 )
drain_flux_top_layer_elevation_9  = pcr.scalar(-1.0) * drain_conductance_9  * pcr.max(0.0, groundwaterHead2 - drain_elevation_uppermost_9 )
drain_flux_top_layer_elevation_10 = pcr.scalar(-1.0) * drain_conductance_10 * pcr.max(0.0, groundwaterHead2 - drain_elevation_uppermost_10)
drain_flux_top_layer_elevation_11 = pcr.scalar(-1.0) * drain_conductance_11 * pcr.max(0.0, groundwaterHead2 - drain_elevation_uppermost_11)
drain_flux_top_layer_elevation_12 = pcr.scalar(-1.0) * drain_conductance_12 * pcr.max(0.0, groundwaterHead2 - drain_elevation_uppermost_12)
# -- from the bottom layer
drain_flux_bot_layer_elevation_0  = pcr.scalar(-1.0) * drain_conductance_0  * pcr.max(0.0, groundwaterHead1 - drain_elevation_lowermost_0 )
drain_flux_bot_layer_elevation_1  = pcr.scalar(-1.0) * drain_conductance_1  * pcr.max(0.0, groundwaterHead1 - drain_elevation_lowermost_1 )
drain_flux_bot_layer_elevation_2  = pcr.scalar(-1.0) * drain_conductance_2  * pcr.max(0.0, groundwaterHead1 - drain_elevation_lowermost_2 )
drain_flux_bot_layer_elevation_3  = pcr.scalar(-1.0) * drain_conductance_3  * pcr.max(0.0, groundwaterHead1 - drain_elevation_lowermost_3 )
drain_flux_bot_layer_elevation_4  = pcr.scalar(-1.0) * drain_conductance_4  * pcr.max(0.0, groundwaterHead1 - drain_elevation_lowermost_4 )
drain_flux_bot_layer_elevation_5  = pcr.scalar(-1.0) * drain_conductance_5  * pcr.max(0.0, groundwaterHead1 - drain_elevation_lowermost_5 )
drain_flux_bot_layer_elevation_6  = pcr.scalar(-1.0) * drain_conductance_6  * pcr.max(0.0, groundwaterHead1 - drain_elevation_lowermost_6 )
drain_flux_bot_layer_elevation_7  = pcr.scalar(-1.0) * drain_conductance_7  * pcr.max(0.0, groundwaterHead1 - drain_elevation_lowermost_7 )
drain_flux_bot_layer_elevation_8  = pcr.scalar(-1.0) * drain_conductance_8  * pcr.max(0.0, groundwaterHead1 - drain_elevation_lowermost_8 )
drain_flux_bot_layer_elevation_9  = pcr.scalar(-1.0) * drain_conductance_9  * pcr.max(0.0, groundwaterHead1 - drain_elevation_lowermost_9 )
drain_flux_bot_layer_elevation_10 = pcr.scalar(-1.0) * drain_conductance_10 * pcr.max(0.0, groundwaterHead1 - drain_elevation_lowermost_10)
drain_flux_bot_layer_elevation_11 = pcr.scalar(-1.0) * drain_conductance_11 * pcr.max(0.0, groundwaterHead1 - drain_elevation_lowermost_11)
drain_flux_bot_layer_elevation_12 = pcr.scalar(-1.0) * drain_conductance_12 * pcr.max(0.0, groundwaterHead1 - drain_elevation_lowermost_12)

total_drain_flux = drain_flux_top_layer_elevation_0  + drain_flux_bot_layer_elevation_0  + \
                   drain_flux_top_layer_elevation_1  + drain_flux_bot_layer_elevation_1  + \
                   drain_flux_top_layer_elevation_2  + drain_flux_bot_layer_elevation_2  + \
                   drain_flux_top_layer_elevation_3  + drain_flux_bot_layer_elevation_3  + \
                   drain_flux_top_layer_elevation_4  + drain_flux_bot_layer_elevation_4  + \
                   drain_flux_top_layer_elevation_5  + drain_flux_bot_layer_elevation_5  + \
                   drain_flux_top_layer_elevation_6  + drain_flux_bot_layer_elevation_6  + \
                   drain_flux_top_layer_elevation_7  + drain_flux_bot_layer_elevation_7  + \
                   drain_flux_top_layer_elevation_8  + drain_flux_bot_layer_elevation_8  + \
                   drain_flux_top_layer_elevation_9  + drain_flux_bot_layer_elevation_9  + \
                   drain_flux_top_layer_elevation_10 + drain_flux_bot_layer_elevation_10 + \
                   drain_flux_top_layer_elevation_11 + drain_flux_bot_layer_elevation_11 + \
                   drain_flux_top_layer_elevation_12 + drain_flux_bot_layer_elevation_12


# total baseflow
# - convert unit to m per day
# - also now assume that positive values for water leaving aquifer (PCR-GLOBWB convention)
total_baseflow = (total_river_flux + total_drain_flux)/cell_area * pcr.scalar(-1.0)

pcr.report(total_baseflow, output_folder + "/total_baseflow_meter_per_day.map")

