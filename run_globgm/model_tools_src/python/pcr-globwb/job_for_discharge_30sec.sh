#!/bin/bash
#SBATCH -t 04:00:00

#~ #SBATCH --output=ss_%j.out
#~ #SBATCH --error=ss_%j.err

#SBATCH -p genoa
#SBATCH -N 1

#SBATCH -n 32

SBATCH --export YEAR="2000"

# activate the pcrglobwb conda environment
# load miniconda
# - using 2022 modules (suitable for genoa nodes)
module load 2022
module load Miniconda3/4.12.0
unset PYTHONPATH
source activate /home/hydrowld/.conda/envs/pcrglobwb_python3

MODEL_SCRIPT_FOLDER="/home/edwinaha/github/edwinkost/GLOBGM/model_tools_src/python/pcr-globwb/"

cd ${MODEL_SCRIPT_FOLDER}

python deterministic_runner_for_calculating_discharge_from_runoff.py ${YEAR} 
