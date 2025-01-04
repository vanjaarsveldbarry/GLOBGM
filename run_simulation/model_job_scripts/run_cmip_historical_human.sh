#!/bin/bash -l
#SBATCH -N 1
#SBATCH -J sn_W5E5
#SBATCH -t 12:00:00
#SBATCH --partition=genoa
#SBATCH --output=sn_W5E5.out

source ${HOME}/.bashrc
mamba activate globgm
iRodsPassword='E-sEOmhJCh1kdgASIliTCGeItYbUu59l'
run_globgm_dir=/home/bvjaarsveld1/projects/workflow/GLOBGM/run_simulation
outputDirectory=/scratch-shared/_bvjaarsveld1/historical/historical_human
data_dir=/scratch-shared/_bvjaarsveld1/historical/_data

simulation=gswp3-w5e5
cd $run_globgm_dir/model_job_scripts

bash ./_fetch_data.sh $data_dir $iRodsPassword

# snakemake --cores 16 \
#           --until write_model_forcing_setup \
#           --snakefile transient_historical_human.smk \
#           --config simulation=$simulation \
#                     outputDirectory=$outputDirectory \
#                     run_globgm_dir=$run_globgm_dir \
#                     data_dir=$data_dir

















#########################################################################################################################
#STEP 1: Run the steady state 


#STEP 2: Run the transient without spinup and WITHOUT pumping for the first year. 


#STEP 3: Run the transient without spinup and WITH pumping for the first year repetitively and analyse as we go 






########################################historical####################
# simulation=gswp3-w5e5
# outputDirectory=/projects/0/einf4705/workflow/output
# run_globgm_dir=/projects/0/einf4705/workflow/GLOBGM/run_globgm
# data_dir=/projects/0/einf4705/_data

# cd $run_globgm_dir/model_job_scripts

# snakemake --cores 16 \
# --snakefile Snakefile_W5E5.smk \
# --config simulation=$simulation \
#          outputDirectory=$outputDirectory \
#          run_globgm_dir=$run_globgm_dir \
#          data_dir=$data_dir
