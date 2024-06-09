#!/bin/bash -l
#SBATCH -N 1
#SBATCH -t 00:45:00
#SBATCH --partition=genoa

source ${HOME}/.bashrc
mamba activate globgm

model_job_scripts=$1
slurmDir_ss=$2
modelRoot=$3
modelScratch=$4

ss_writeInput_setup_script=$model_job_scripts/2_write_model_input/_setup_ss.slurm
sbatch -o $slurmDir_ss/2_write_model_input/2_write_model_input_setup.out $ss_writeInput_setup_script $modelRoot $modelScratch

model_job_scripts_writeTile=$model_job_scripts/2_write_model_input/_writeTiles_ss.slurm
jobid=$(sbatch -o $slurmDir_ss/2_write_model_input/_writeTiles_ss/ss_write_tiles_%a.out --array=1-163:3 $model_job_scripts_writeTile $modelRoot $modelScratch | awk '{print $4}')

model_job_scripts_writeModels=$model_job_scripts/2_write_model_input/_writeModels_ss.slurm
sbatch --dependency=afterok:$jobid -o $slurmDir_ss/2_write_model_input/_writeModels_ss.out $model_job_scripts_writeModels $modelRoot