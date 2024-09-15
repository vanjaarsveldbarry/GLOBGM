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
from six.moves.configparser import RawConfigParser as ConfigParser
import netCDF4
from pathlib import Path
import xarray as xr
import pandas as pd
import numpy as np
from numcodecs import Blosc

import logging
logger = logging.getLogger(__name__)

class DeterministicRunner(DynamicModel):

    def __init__(self, modelTime, model_setup):
        DynamicModel.__init__(self)

        # ~ Please also check the previous script: https://github.com/edwinkost/estimate_discharge_from_local_runoff/blob/develop/python_estimate_flow/estimate_discharge_from_local_runoff.py

        # initiate model time
        self.modelTime = modelTime        


        # get the model setup
        self.model_setup = model_setup
        
        # set clone
        self.clone = self.model_setup["clone_file"]
        pcr.setclone(self.clone)
        
        # output and tmp folders
        self.output_folder = model_setup['output_dir']
        self.tmp_folder    = model_setup['tmp_dir']

        # read ldd
        self.ldd = vos.readPCRmapClone(v                = self.model_setup["ldd_file"], \
                                       cloneMapFileName = self.clone, \
                                       tmpDir           = self.tmp_folder, \
                                       absolutePath     = None, \
                                       isLddMap         = True, \
                                       cover            = None, \
                                       isNomMap         = False)
        self.ldd = pcr.lddrepair(pcr.lddrepair(pcr.ldd(self.ldd)))                               

        # read cell area (m2)
        self.cell_area = vos.readPCRmapClone(v                = self.model_setup["cell_area_file"], \
                                             cloneMapFileName = self.clone, \
                                             tmpDir           = self.tmp_folder, \
                                             absolutePath     = None, \
                                             isLddMap         = False, \
                                             cover            = None, \
                                             isNomMap         = False)

    def initial(self): 
        
        # read cell area (m2)
        self.cell_area 

    def dynamic(self):

        # re-calculate current model time using current pcraster timestep value
        self.modelTime.update(self.currentTimeStep())

        # update water bodies at the beginning of model simulation and at every first day of the year
        if self.modelTime.timeStepPCR == 1 or (self.modelTime.doy == 1):

            logger.info(" \n\n Updating lakes and reservoirs %s \n\n", self.modelTime.currTime)

            # read lake and reservoir ids
            date_used = self.modelTime.fulldate
            lake_and_reservoir_ids = vos.netcdf2PCRobjClone(self.model_setup["lake_and_reservoir_file"],\
                                                            'waterBodyIds',\
                                                            date_used, \
                                                            useDoy = 'yearly',\
                                                            cloneMapFileName = self.clone)

            self.lake_and_reservoir_ids = pcr.nominal(lake_and_reservoir_ids)
            
        # calculating discharge only at the last day of every month
        if self.modelTime.isLastDayOfMonth():
            logger.info(" \n\n Calculating for time %s \n\n", self.modelTime.currTime)
            _compressor = Blosc(cname='zstd', clevel=5, shuffle=Blosc.BITSHUFFLE)
            _encoding_dict={'dtype': 'float32', '_FillValue': -9999, 'compressor': _compressor}
            _chunks={'time': 1, 'lat': 20000, 'lon': 20000}
            def toZarr(data, file, varName):
                array = pcr.pcr2numpy(data, vos.MV)
                timeStampPandas=pd.Timestamp(datetime.datetime(self.modelTime.year,self.modelTime.month, self.modelTime.day,0))
                with xr.open_zarr(file) as dsInfo:
                    timeStamp = datetime.datetime(self.modelTime.year,self.modelTime.month, self.modelTime.day,0)
                    index = dsInfo.get_index('time').get_loc(timeStamp.strftime('%Y-%m-%d'))
                ds = xr.DataArray(data=array, dims=['lat', 'lon'], coords={'lat':np.zeros(array.shape[0]), 'lon':np.zeros(array.shape[1])}).to_dataset(name=varName)
                ds = ds.expand_dims({'time': [timeStampPandas]}).drop_vars(['lat', 'lon']).chunk(_chunks)
                ds.to_zarr(file, region={"time": slice(index, index+1)}, consolidated=True)
            
            toZarr(vos.netcdf2PCRobjClone(self.model_setup["monthly_recharge_file"], \
                                            "groundwater_recharge", str(self.modelTime.fulldate), None, self.clone), 
                                            file=self.model_setup["recharge_output_file"], varName='gwRecharge')
            
            toZarr(vos.netcdf2PCRobjClone(self.model_setup["monthly_abstraction_file"], \
                                            "total_groundwater_abstraction", str(self.modelTime.fulldate), None, self.clone), 
                                            file=self.model_setup["abstraction_output_file"], varName='gwAbstraction')

            # # read monthly runoff (m.month-1)
            monthly_total_local_runoff    = vos.netcdf2PCRobjClone(self.model_setup["monthly_runoff_file"], \
                                                                   "total_runoff", \
                                                                   str(self.modelTime.fulldate), \
                                                                   None, \
                                                                   self.clone)
            monthly_total_local_runoff    = pcr.cover(monthly_total_local_runoff, 0.0)
            
            # # daily runoff (m3.day-1)
            self.daily_total_local_runoff = monthly_total_local_runoff * self.cell_area / self.modelTime.day 
            
            # calculate discharge at river cells (m3.s-1)
            self.river_discharge = pcr.catchmenttotal(self.daily_total_local_runoff, self.ldd) / (24. * 3600.)
            self.river_discharge = pcr.max(0.0, pcr.cover(self.river_discharge, 0.0))
            
            # calculate discharge at lakes and reservoirs
            self.lake_and_reservoir_discharge = pcr.areamaximum(self.river_discharge, self.lake_and_reservoir_ids)
            self.lake_and_reservoir_discharge = pcr.ifthen(pcr.scalar(self.lake_and_reservoir_ids) > 0.0, self.lake_and_reservoir_discharge)
            
            # merge all discharge values
            self.discharge = pcr.cover(self.lake_and_reservoir_discharge, self.river_discharge)
            # reporting 
            toZarr(self.discharge, file=self.model_setup["discharge_output_file"], varName='discharge')
           

def main():
    
    TEMPDIR=sys.argv[1]
    config_file = sys.argv[2]
    YEAR_START = sys.argv[3]
    YEAR_END = sys.argv[4]
    SAVEFOLDER=sys.argv[5]

    config = ConfigParser()
    config.optionxform = str
    config.read(config_file)

    model_setup = {}
    model_setup["clone_file"] = config.get("model_setup", "clone_file")
    model_setup["ldd_file"] = config.get("model_setup", "ldd_file")
    model_setup["cell_area_file"] = config.get("model_setup", "cell_area_file")
    model_setup["lake_and_reservoir_file"] = config.get("model_setup", "lake_and_reservoir_file")
    model_setup["monthly_runoff_file"] = sys.argv[6]
    model_setup["monthly_recharge_file"] = sys.argv[7]
    model_setup["monthly_abstraction_file"] = sys.argv[8]
    model_setup["output_dir"] = f"{TEMPDIR}/{YEAR_START}_{YEAR_END}"
    
    # if MONTH == "2":
    #     model_setup["start_date"] = f"{YEAR}-{str(MONTH).zfill(2)}-28"
    #     model_setup["end_date"] = f"{YEAR}-{str(MONTH).zfill(2)}-28"
        
    # else:
    #     if MONTH in ["4", "6", "9", "11"]:
    #         model_setup["start_date"] = f"{YEAR}-{str(MONTH).zfill(2)}-30"
    #         model_setup["end_date"] = f"{YEAR}-{str(MONTH).zfill(2)}-30"  
    
    #     else:
    #         model_setup["start_date"] = f"{YEAR}-{str(MONTH).zfill(2)}-31"
    #         model_setup["end_date"] = f"{YEAR}-{str(MONTH).zfill(2)}-31"
    model_setup["start_date"] = f"{YEAR_START}-01-31"
    model_setup["end_date"] = f"{YEAR_END}-12-31"
    
    model_setup["discharge_output_file"] = f"{SAVEFOLDER}/discharge.zarr"
    model_setup["recharge_output_file"] = f"{SAVEFOLDER}/gwRecharge.zarr"
    model_setup["abstraction_output_file"] = f"{SAVEFOLDER}/gwAbstraction.zarr"

    # make output and temporary folders
    if os.path.exists(model_setup["output_dir"]):
        shutil.rmtree(model_setup["output_dir"])
    os.makedirs(model_setup["output_dir"])

    # make temporary folder
    model_setup["tmp_dir"] = os.path.join(model_setup["output_dir"], "tmp")
    os.makedirs(model_setup["tmp_dir"])

    # initialize logging
    log_file_directory = os.path.join(model_setup["output_dir"], "log")
    os.makedirs(log_file_directory)
    vos.initialize_logging(log_file_directory)

    # timeStep info: year, month, day, doy, hour, etc
    currTimeStep = ModelTime()
    currTimeStep.getStartEndTimeSteps(model_setup["start_date"], model_setup["end_date"])

    # Running the deterministic_runner
    logger.info('Starting the calculation.')
    deterministic_runner = DeterministicRunner(currTimeStep, model_setup)
    dynamic_framework = DynamicFramework(deterministic_runner, currTimeStep.nrOfTimeSteps)
    dynamic_framework.setQuiet(True)
    dynamic_framework.run()
            
if __name__ == '__main__':
    sys.exit(main())
