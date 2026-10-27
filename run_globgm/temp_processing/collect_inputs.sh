#!/bin/bash
#SBATCH -J collect_inputs
#SBATCH -p staging
#SBATCH -t 1-00:00:00
#SBATCH -c 4
#SBATCH -o /gpfs/work4/0/prjs1222/globgm_port/GLOBGM/run_globgm/temp_processing/collect_inputs.out
set -euo pipefail
src=/gpfs/work4/0/prjs1222/globgm_input/_data/globgm_input
dst=/gpfs/work4/0/prjs1222/globgm_port/input
mkdir -p "$dst"

cp -p "$src/lddsound_30sec_version_202005XX_correct_lat.nc" "$dst/"
mkdir -p "$dst/topography_30sec_03sec"
cp -p "$src/topography_30sec_03sec/dem_average_topography_parameters_30sec_february_2021_global_covered_with_zero.nc" "$dst/topography_30sec_03sec/"
cp -p "$src/confining_layer_thickness_version_2016_remapbil_to_30sec.nc" "$dst/"
cp -p "$src/lakes_and_reservoirs_30sec_global_2019_version_202005XX.nc" "$dst/"

# monthly 30" forcing from the DAG
# pixi exec --spec python=3.12 --spec python-irodsclient \
  # python /gpfs/work4/0/prjs1222/globgm_port/GLOBGM/run_globgm/temp_processing/get_1km_forcing.py "$dst/forcing_30sec"

# DAG_PASSWORD='Rp5m3Tt6ssTAuboO-GsZarfuT-dI0gM7'