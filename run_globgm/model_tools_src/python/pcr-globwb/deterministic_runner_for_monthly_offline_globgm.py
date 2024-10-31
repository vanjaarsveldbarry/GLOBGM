#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# PCR-GLOBWB (PCRaster Global Water Balance) Global Hydrological Model
#
# Copyright (C) 2016, Edwin H. Sutanudjaja, Rens van Beek, Niko Wanders, Yoshihide Wada, 
# Joyce H. C. Bosmans, Niels Drost, Ruud J. van der Ent, Inge E. M. de Graaf, Jannis M. Hoch, 
# Kor de Jong, Derek Karssenberg, Patricia López López, Stefanie Peßenteiner, Oliver Schmitz, 
# Menno W. Straatsma, Ekkamol Vannametee, Dominik Wisser, and Marc F. P. Bierkens
# Faculty of Geosciences, Utrecht University, Utrecht, The Netherlands
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

import os
import sys
import datetime
import calendar
from dateutil.relativedelta import relativedelta
import glob
import shutil
import re

import pcraster as pcr
from pcraster.framework import DynamicModel
from pcraster.framework import DynamicFramework

import globgm

from globgm.currTimeStep import ModelTime 


import logging
logger = logging.getLogger(__name__)

import globgm.disclaimer as disclaimer

class DeterministicRunner(DynamicModel):

    def __init__(self, configuration, modelTime, system_arguments):
        DynamicModel.__init__(self)

        # model time object
        self.modelTime = modelTime      
        
        # make the configuration available for the other method/function
        self.configuration = configuration

        # model and reporting objects
        self.globgm    = globgm.modflow.ModflowCoupling(configuration, modelTime)
        self.reporting = globgm.Reporting(configuration, self.globgm, modelTime)
        
        # set the clone map
        pcr.setclone(configuration.cloneMap)
        
        # TODO: pre-factors based on the system arguments
        

    def initial(self): 
        
        # get or prepare the initial condition for groundwater head 
        self.globgm.get_initial_heads()

    def dynamic(self):

        # re-calculate current model time using current pcraster timestep value
        self.modelTime.update(self.currentTimeStep())

        # update/calculate model and daily merging, and report ONLY at the last day of the month
        if self.modelTime.isLastDayOfMonth():
            
            # update MODFLOW model (It will pick up current model time from the modelTime object)
            self.globgm.update()
            # reporting is only done at the end of the month
            # self.reporting.report()



def main():
    
    # print disclaimer
    disclaimer.print_disclaimer()

    # get the full path of configuration/ini file given in the system argument
    iniFileName   = os.path.abspath(sys.argv[1])
    
    # debug option
    debug_mode = False
    if len(sys.argv) > 2:
        if sys.argv[2] == "debug": debug_mode = True
    
    # options to perform steady state calculation
    steady_state_only = False
    if len(sys.argv) > 3: 
        if sys.argv[3] == "steady-state-only": steady_state_only = True

    if len(sys.argv) > 4: #JV
        tile = sys.argv[4]
        if steady_state_only == True:
            inDir = sys.argv[5]
            outDir = sys.argv[6]
            forcingDir = sys.argv[7]
            calib_str = sys.argv[8]
            iniFileName_new = os.path.join(os.path.dirname(iniFileName),'%s.ini'%tile)
            f = open(iniFileName,'r'); s = f.read(); f.close()
            iniFileName = iniFileName_new
            s = s.replace('$tile$',tile)
            s = s.replace('IN_DIR',inDir)
            s = s.replace('OUT_DIR',outDir)
            s = s.replace('FORCING_DIR',forcingDir)
            
            def parse_calib_str(calib_str):
                params = {}
                parts = calib_str.split('_')
                print(parts)
                for part in parts:
                    match = re.search(r'(\d+\.\d+)', part)
                    if match:
                        key = part[:match.start()]
                        value = str(match.group(1))
                        params[key] = value
                return params
            params=parse_calib_str(calib_str)
            s = s.replace('KH_UNCON_PF',params.get('khuncon'))
            s = s.replace('KH_CON_PF',params.get('khcon'))
            s = s.replace('KH_CAR_PF',params.get('khcar'))
            s = s.replace('KV_CON_PF',params.get('kvconf'))
            s = s.replace('RIV_RES_PF',params.get('riverres'))
            f = open(iniFileName,'w'); f.write(s); f.close()
        else:
            inDir = sys.argv[5]
            outDir = sys.argv[6]
            forcingDir = sys.argv[7]
            nMonths = sys.argv[9]
            startDate = datetime.datetime.strptime(sys.argv[8], "%Y%m%d")
            preliminary_endDate = startDate + relativedelta(months=(int(nMonths)-1))
            _, last_day = calendar.monthrange(preliminary_endDate.year, preliminary_endDate.month)
            endDate = datetime.datetime(preliminary_endDate.year, preliminary_endDate.month, last_day)
            startDate = startDate.strftime("%Y-%m-%d")
            endDate = endDate.strftime("%Y-%m-%d")
        
            iniFileName_new = os.path.join(os.path.dirname(iniFileName),'%s.ini'%tile)
            f = open(iniFileName,'r'); s = f.read(); f.close()
            iniFileName = iniFileName_new
            s = s.replace('$tile$',tile)
            s = s.replace('IN_DIR',inDir)
            s = s.replace('OUT_DIR',outDir)
            s = s.replace('FORCING_DIR',forcingDir)
            s = s.replace('START_DATE',startDate)
            s = s.replace('END_DATE',endDate)
            f = open(iniFileName,'w'); f.write(s); f.close()
    # object to handle configuration/ini file
    configuration = globgm.Configuration(iniFileName = iniFileName, \
                                         debug_mode = debug_mode, \
                                         steady_state_only = steady_state_only)      

    # if steady_state_only startTime = endTime
    if steady_state_only:
       configuration.globalOptions['endTime'] = configuration.globalOptions['startTime']
    
    # timeStep info: year, month, day, doy, hour, etc
    currTimeStep = ModelTime() 
    
    # Running the deterministic_runner
    currTimeStep.getStartEndTimeSteps(configuration.globalOptions['startTime'],
                                      configuration.globalOptions['endTime'])
    logger.info('Model run starts.')
    deterministic_runner = DeterministicRunner(configuration, currTimeStep, sys.argv)
    
    dynamic_framework = DynamicFramework(deterministic_runner, currTimeStep.nrOfTimeSteps)
    dynamic_framework.setQuiet(True)
    dynamic_framework.run()

if __name__ == '__main__':
    # print disclaimer
    disclaimer.print_disclaimer(with_logger = True)
    sys.exit(main())