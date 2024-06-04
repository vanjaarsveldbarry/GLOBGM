#!/bin/bash

#SBATCH -t 16:00:00

#~ #SBATCH --output=ss_%j.out
#~ #SBATCH --error=ss_%j.err

#SBATCH -p genoa
#SBATCH -N 1

#SBATCH -n 192

MODEL_SCRIPT_FOLDER="/home/edwinaha/github/edwinkost/GLOBGM/model_tools_src/python/pcr-globwb/"
INI_FILE="/home/edwinaha/github/edwinkost/GLOBGM/model_input/1_write_tiled_parameter_data/develop/steady-state_config_develop_edwinaha_debug.ini"

TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE="/scratch-shared/edwinaha/globgm_tile_map_files_for_arfan/map_input/steady-state/average/ini_files/"

#~ cd {git_dir}/model_tools_src/python/pcr-globwb

cd ${MODEL_SCRIPT_FOLDER}


# activate the pcrglobwb conda environment
. /home/edwin/load_all_default.sh


python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_078-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &

wait
