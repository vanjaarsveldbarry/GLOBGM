#!/bin/bash 

# we use one core
#SBATCH -N 1

# within a core, 64 cores will be used
#SBATCH -n 64

# wall clock time
#SBATCH -t 119:59:59

# the type of node
#SBATCH -p genoa

# job name
#SBATCH -J globgm

#~ # mail alert at start, end and abortion of execution
#~ #SBATCH --mail-type=ALL
#~ # send mail to this address
#~ #SBATCH --mail-user=XXX@gmail.com



set -x


# configuration (.ini) file - PLEASE MODIFY THIS!
# - historical
INI_FILE="/home/edwinaha/github/edwinkost/GLOBGM/model_tools_src/python/pcr-globwb/globgm/config/globgm_offline_05min_global_develop_for_beda.ini"


# location of your GLOBGM model scripts - PLEASE MODIFY THIS
PCRGLOBWB_MODEL_SCRIPT_FOLDER="/home/edwinaha/github/edwinkost/GLOBGM/model_tools_src/python/pcr-globwb/"


# load all software, conda etc
. /home/edwin/load_all_default.sh


# unset pcraster working threads
unset PCRASTER_NR_WORKER_THREADS


# test pcraster
pcrcalc


# go to the folder that contain PCR-GLOBWB scripts
cd ${PCRGLOBWB_MODEL_SCRIPT_FOLDER}
pwd


python3 deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug

