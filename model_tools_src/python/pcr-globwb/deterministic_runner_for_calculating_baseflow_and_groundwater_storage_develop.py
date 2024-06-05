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

    # ~ groundwaterHead1_inp = vos.netcdf2PCRobjCloneWithoutTime(ncFile  = ncFile, \
                                                             # ~ varName = "automatic",\
                                                             # ~ cloneMapFileName  = clone_map,\
                                                             # ~ LatitudeLongitude = False,\
                                                             # ~ specificFillValue = None,\
                                                             # ~ absolutePath = None)

    # ~ groundwaterHead1_inp = vos.readPCRmapClone(v = ncFile, cloneMapFileName = clone_map, tmpDir = tmp_dir, absolutePath = None, isLddMap = False, cover = None, isNomMap = False)

    output = tmp_dir + 'temp.map'
    warp = vos.gdalwarpPCR(v = ncFile, output = output, cloneMapFileName = clone_map, tmpDir = tmp_dir, isLddMap = False, isNomMap = False)
    groundwaterHead1_inp = pcr.readmap(output)


    if region == 1:
        groundwaterHead1 = groundwaterHead1_inp
    else:
        groundwaterHead1 = pcr.cover(groundwaterHead1, groundwaterHead1_inp)
    pcr.aguila(groundwaterHead1)

