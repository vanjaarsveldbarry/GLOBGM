#!/bin/bash -l
#SBATCH -N 1
#SBATCH -J ini_con
#SBATCH -t 119:00:00
#SBATCH --partition=genoa
#SBATCH --output=/home/bvjaarsveld1/projects/workflow/GLOBGM/run_initial_conditions/model_job_scripts/slurmOut/_ini_conditions_with_pump.out

source ${HOME}/.bashrc
mamba activate globgm

run_globgm_dir=/home/bvjaarsveld1/projects/workflow/GLOBGM/run_initial_conditions
cd $run_globgm_dir/model_job_scripts

simulation=gswp3-w5e5
outputDirectory=/scratch-shared/_bvjaarsveld1/output_initial_conditions
data_dir=/scratch-shared/_bvjaarsveld1/_data

# bash ./_fetch_data.sh $data_dir

#STEP 1: Run the steady state 
# bash  ./steady_state_run.sh $simulation $outputDirectory $run_globgm_dir $data_dir

#STEP 2: Run the transient without spinup and WITHOUT pumping for the first year. 
# bash  ./transient_no_pump_run.sh $simulation $outputDirectory $run_globgm_dir $data_dir

#STEP 3: Run the transient without spinup and WITH pumping for the first year repetitively and analyse as we go 
bash  ./transient_with_pump_run.sh $simulation $outputDirectory $run_globgm_dir $data_dir

#STEP 4: Upload initial conditions to YODA

