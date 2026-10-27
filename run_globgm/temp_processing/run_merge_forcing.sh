#!/bin/bash
# Merge the downloaded clone tiles into global 30" forcing, one file per variable.
# Uses every core of the node it runs on: bash run_merge_forcing.sh
set -euo pipefail
period=1979_1994
inp=/gpfs/work4/0/prjs1222/globgm_port/input

cd /gpfs/work4/0/prjs1222/globgm_port/GLOBGM
pixi run python run_globgm/temp_processing/merge_forcing.py \
  "$inp/forcing_30sec" "$period" "$inp/forcing_30sec_global/$period"
