#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import print_function

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

# EHS (20 March 2013): This is the list of general functions.
#                      The list is continuation from Rens's and Dominik's.

import shutil
import subprocess
import datetime
import random
import os
import gc
import re
import math
import sys
import types
import calendar
import glob

import netCDF4 as nc
import numpy as np
import numpy.ma as ma
import pcraster as pcr

from . import virtualOS as vos

import logging

from six.moves import range

logger = logging.getLogger(__name__)

# file cache to minimize/reduce opening/closing files.  
filecache = dict()

# Global variables:
MV = 1e20
smallNumber = 1E-39

# and set pi
pi = math.pi

# tuple of netcdf file suffixes (extensions) that can be used:
netcdf_suffixes = ('.nc4','.nc')

# maximum number of tries for reading files:
max_num_of_tries = 5



def read_from_tile_folder(tile_pcraster_map_folder, pcraster_map_file_name, clone_map, tmp_dir, saved_global_file = None):

    text = 'reading ' + pcraster_map_file_name
    print(text)
    
    for tile in range(1, 163+1):

    # ~ # for testing
    for tile in range(1, 5+1):

        print(tile)
        tile_folder = tile_pcraster_map_folder %(tile)
        input_file = tile_folder + pcraster_map_file_name
        
        if tile == 1: 
            pcraster_map = vos.readPCRmapClone(v = input_file, cloneMapFileName = clone_map, tmpDir = tmp_dir)
        else:
            pcraster_map = pcr.cover(pcraster_map, vos.readPCRmapClone(v = input_file, cloneMapFileName = clone_map, tmpDir = tmp_dir))

        # ~ if tile == 16: pcr.aguila(pcraster_map)    
        # ~ if tile == 163: pcr.aguila(pcraster_map)
    
    if saved_global_file is not None: pcr.report(pcraster_map, saved_global_file)
    
    return pcraster_map
