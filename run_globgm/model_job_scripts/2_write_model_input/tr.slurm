#!/bin/bash -l
#SBATCH -N 1
#SBATCH -t 00:45:00
#SBATCH --partition=genoa

source ${HOME}/.bashrc
mamba activate globgm

model_job_scripts=$1
slurmDir_tr=$2
modelRoot=$3
modelScratch=$4
start_year=$5
end_year=$6

tr_writeInput_setup_script=$model_job_scripts/2_write_model_input/_setup_tr.slurm
sbatch -o $slurmDir_tr/2_write_model_input/2_write_model_input_setup.out $tr_writeInput_setup_script $modelRoot $modelScratch $start_year $end_year

model_job_scripts_writeTile=$model_job_scripts/2_write_model_input/_writeTiles_tr.slurm
sbatch -o $slurmDir_tr/2_write_model_input/_writeTiles_tr/tr_write_tiles_%a.out --array=1-163:3 $model_job_scripts_writeTile $modelRoot $modelScratch $start_year $end_year