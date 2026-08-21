#!/bin/bash -l
#SBATCH -N 1
#SBATCH -J ini_con
#SBATCH -t 119:00:00
#SBATCH --partition=genoa
#SBATCH --output=/home/bvjaarsveld1/projects/workflow/GLOBGM/run_initial_conditions/model_job_scripts/slurmOut/_ini_conditions_with_pump.out

source ${HOME}/.bashrc
mamba activate globgm

run_globgm_dir=/projects/prjs1222/GLOBGM/run_initial_conditions
cd $run_globgm_dir/model_job_scripts

simulation=gswp3-w5e5
outputDirectory=/projects/prjs1222/globgm_output/output_initial_conditions
data_dir=/projects/prjs1222/globgm_input/_data

# bash ./_fetch_data.sh $data_dir

#STEP 1: Run the steady state 
# bash  ./steady_state_run.sh $simulation $outputDirectory $run_globgm_dir $data_dir

#STEP 2: Run the transient without spinup and WITHOUT pumping for the first year. 
# bash  ./transient_no_pump_run.sh $simulation $outputDirectory $run_globgm_dir $data_dir

#STEP 3: Run the transient without spinup and WITH pumping for the first year repetitively and analyse as we go 
# bash  ./transient_with_pump_run.sh $simulation $outputDirectory $run_globgm_dir $data_dir

#STEP 4: Upload initial conditions to the data folder for later use
mkdir -p $data_dir/initial_conditions/ss $data_dir/initial_conditions/tr 
cp -r $outputDirectory/ss/mf6_mod/glob_ss/models/run_output_bin/* $data_dir/initial_conditions/ss
cp -r $outputDirectory/tr_with_pump/mf6_mod/mf6_mod_1/glob_tr/models/run_output_bin/_ini_hds/* $data_dir/initial_conditions/tr
