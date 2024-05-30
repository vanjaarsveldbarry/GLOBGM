#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
import pcraster as pcr
import glob

main_folder = "/scratch-shared/edwinbar/globgm_tile_map_files_for_arfan/map_input/steady-state/average_backup/average/"

tiles = glob.glob(main_folder + "/tile_*")


for tile in tiles:
    
    print(tile)
    
    top_uppermost_file    = tile + "/steady-state-only/maps/top_uppermost_layer.map"
    bottom_uppermost_file = tile + "/steady-state-only/maps/bottom_uppermost_layer.map"
    bottom_lowermost_file = tile + "/steady-state-only/maps/bottom_lowermost_layer.map"
    
    pcr.setclone(top_uppermost_file)

    top_uppermost    = pcr.cover(pcr.readmap(top_uppermost_file   ), 0.0)
    bottom_uppermost = pcr.cover(pcr.readmap(bottom_uppermost_file), 0.0)
    bottom_lowermost = pcr.cover(pcr.readmap(bottom_lowermost_file), 0.0)
    
    pcr.report(top_uppermost   , top_uppermost_file   )
    pcr.report(bottom_uppermost, bottom_uppermost_file)
    pcr.report(bottom_lowermost, bottom_lowermost_file)
    
