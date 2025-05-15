#!/bin/bash

source ${HOME}/.bashrc
mamba activate globgm


cd /projects/prjs1222/GLOBGM/analysis/cmip6_runs/wtd_difference
python -u ./_calc_wtd_difference.py 
wait