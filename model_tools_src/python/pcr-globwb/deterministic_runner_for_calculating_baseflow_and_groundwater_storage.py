#!/usr/bin/env python
# -*- coding: utf-8 -*-
#

import os
import shutil
import sys
import datetime

import pcraster as pcr

from pcraster.framework import DynamicModel
from pcraster.framework import DynamicFramework

from globgm.currTimeStep import ModelTime 

import globgm.ncConverter_for_discharge_30sec as netcdf_writer 
import globgm.virtualOS as vos 

import logging
logger = logging.getLogger(__name__)

number_of_layers = 2



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

