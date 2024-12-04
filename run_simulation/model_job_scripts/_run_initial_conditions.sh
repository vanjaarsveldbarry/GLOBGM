#!/bin/bash -l
#SBATCH -N 1
#SBATCH -J ini_con
#SBATCH -t 12:00:00
#SBATCH --partition=genoa
#SBATCH --output=_ini_conditions.out

source ${HOME}/.bashrc
mamba activate globgm

run_globgm_dir=/projects/0/einf4705/workflow/GLOBGM/run_globgm
cd $run_globgm_dir/model_job_scripts


simulation=gswp3-w5e5
outputDirectory=/projects/0/einf4705/workflow/output
data_dir=/projects/0/einf4705/_data


#STEP 1: Run the steady state 
# bash  ./steady-state_run.sh $simulation $outputDirectory $run_globgm_dir $data_dir

#STEP 2: Run the transient without spinup and WITHOUT pumping for the first year. 
bash  ./transient_no_pump_run.sh $simulation $outputDirectory $run_globgm_dir $data_dir


#STEP 3: Run the transient without spinup and WITH pumping for the first year repetitively and analyse as we go 