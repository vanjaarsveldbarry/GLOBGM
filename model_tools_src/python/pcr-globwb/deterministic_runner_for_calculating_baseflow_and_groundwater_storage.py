#!/usr/bin/env python
# -*- coding: utf-8 -*-
#

import os
import shutil
import sys
import datetime

import pcraster as pcr

from globgm.virtualOS import vos

# output folder for this analysis
output_folder = "/scratch-shared/edwinaha/test_baseflow_and_storage/"

# make output and temporary folders
if os.path.exists(output_folder): shutil.rmtree(output_folder)
os.makedirs(output_folder)
# - make temporary folder
tmp_dir = output_folder +  "/tmp/"
os.makedirs(tmp_dir)

# Note that the output from the MODFLOW6 has the convention that l1 (layer 1) is for the top one, while the pcraster version of GLOBGM use the l1 as the bottom one
modflow6_output_folder = "/scratch-shared/marfan/globgm_ss/output/average/gswp3-w5e5/ss/mf6_post/"

# clone map
clone_map = "/projects/0/dfguu/users/edwin/data/pcrglobwb_input_arise/develop/global_30sec/routing/surface_water_bodies/version_2020-05-XX/lddsound_30sec_version_202005XX.map"


# obtain the groundwater head for the bottom layer and their correponding storage
groundwaterHead1 = None
storGroundwater1 = None
for region in range(1, 4):
    
    ncFile = modflow6_output_folder + "/s0" + str(region) + "_hds_ss_l1.nc"
    groundwaterHead1_inp = vos.netcdf2PCRobjCloneWithoutTime(ncFile  = ncFile, \
                                                             varName = "automatic",\
                                                             cloneMapFileName  = clone_map,\
                                                             LatitudeLongitude = True,\
                                                             specificFillValue = None,\
                                                             absolutePath = None)
    if region == 1:
        groundwaterHead1 = groundwaterHead1_inp
    else:
        groundwaterHead1 = pcr.cover(groundwaterHead1, groundwaterHead1_inp)
    pcr.aguila(groundwaterHead1)


number_of_layers = 2


# ~ edwinaha@int5:/scratch-shared/marfan/globgm_ss/output/average/gswp3-w5e5/ss/mf6_post$ ls -lah *.nc
# ~ -rw-r--r--. 1 marfan marfan 1.2G Jun  4 20:50 s01_hds_ss_l1.nc
# ~ -rw-r--r--. 1 marfan marfan 1.2G Jun  4 20:50 s01_hds_ss_l2.nc
# ~ -rw-r--r--. 1 marfan marfan 1.2G Jun  4 20:50 s01_wtd_ss_l1.nc
# ~ -rw-r--r--. 1 marfan marfan 1.2G Jun  4 20:50 s01_wtd_ss_l2.nc
# ~ -rw-r--r--. 1 marfan marfan 952M Jun  4 20:48 s02_hds_ss_l1.nc
# ~ -rw-r--r--. 1 marfan marfan 952M Jun  4 20:49 s02_hds_ss_l2.nc
# ~ -rw-r--r--. 1 marfan marfan 952M Jun  4 20:49 s02_wtd_ss_l1.nc
# ~ -rw-r--r--. 1 marfan marfan 952M Jun  4 20:49 s02_wtd_ss_l2.nc
# ~ -rw-r--r--. 1 marfan marfan  64M Jun  4 20:47 s03_hds_ss_l1.nc
# ~ -rw-r--r--. 1 marfan marfan  64M Jun  4 20:47 s03_hds_ss_l2.nc
# ~ -rw-r--r--. 1 marfan marfan  64M Jun  4 20:47 s03_wtd_ss_l1.nc
# ~ -rw-r--r--. 1 marfan marfan  64M Jun  4 20:47 s03_wtd_ss_l2.nc


# baseflow (unit: m/day)
# - initiate the (accumulated) volume rate (m3/day) (for accumulating the fluxes from all layers)
totalBaseflowVolumeRate = pcr.scalar(0.0) 

# - accumulating fluxes from all layers
for i in range(1, number_of_layers+1):
    
    # from the river leakage
    var_name = 'riverLeakageLayer'+str(i)
    
    riverLeakageLayer1  = pcr.ifthenelse(groundwaterHead1 > riverBedElevation1, riverConductance1 * (riverStageElevation1 - groundwaterHead1), riverConductance1 * (riverStageElevation - riverBedElevation1))

    vars()['riverLeakageLayer'+str(i)] = pcr.ifthenelse(vars()['groundwaterHead'+str(i)] > vars()['riverBedElevation'+str(i)], vars()['NNN'+str(i)] * (vars()['NNN'+str(i)] - vars()['NNN'+str(i)]), vars()['NNN'+str(i)] * (vars()['NNN'+str(i)] - vars()['NNN'+str(i)]))

    riverLeakageLayer1  = pcr.ifthenelse(groundwaterHead1 > riverBedElevation1, riverConductance1 * (riverStageElevation1 - groundwaterHead1), riverConductance1 * (riverStageElevation - riverBedElevation1))


    # from the drain package
    var_name = 'drainLayer'+str(i)
    
    drainLayer1 = pcr.max(0.0, drainConductance1 * (groundwaterHead1 - drainElevation1))
    
    


    vars()['NNN'+str(i)]
    
    vars()['riverLeakageLayer'+str(i)] = vars()['groundwaterHead'+str(i)] 


    
    riverConductance1 * (groundwaterHead1 - riverBedElevation1) 
    
    # river formula: 
    
    
    
    vars(self)[var_name] = 
    
    totalBaseflowVolumeRate += pcr.cover(vars()[var_name], 0.0)
    
    # from the drain package
    var_name = 'drainLayer'+str(i)
    totalBaseflowVolumeRate += pcr.cover(vars(self)[var_name], 0.0)
    # use only in the landmask region
    
    if i == self.number_of_layers: totalBaseflowVolumeRate = pcr.ifthen(self.landmask, totalBaseflowVolumeRate)

# - convert the unit to m/day and convert the flow direction 
#   for this variable, positive values indicates flow leaving aquifer (following PCR-GLOBWB assumption, opposite direction from MODFLOW) 
baseflow = pcr.scalar(-1.0) * (totalBaseflowVolumeRate/self.cellAreaMap)

