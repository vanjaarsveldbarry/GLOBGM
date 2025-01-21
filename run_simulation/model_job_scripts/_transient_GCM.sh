#!/bin/bash -l
#SBATCH -N 1
#SBATCH -J ini_con
#SBATCH -t 119:00:00
#SBATCH --partition=genoa
#SBATCH --output=/home/bvjaarsveld1/projects/workflow/GLOBGM/run_simulation/model_job_scripts/slurmOut/ipsl-cm6a-lr_historical_test.out

source ${HOME}/.bashrc
mamba activate globgm

simulation=ipsl-cm6a-lr

#RUN HISTORICAL
outputDirectory=/scratch-shared/_bvjaarsveld1/cmip6_runs/$simulation
data_dir=/scratch-shared/_bvjaarsveld1/_data
run_globgm_dir=/home/bvjaarsveld1/projects/workflow/GLOBGM/run_simulation

# cd $run_globgm_dir/model_job_scripts

# snakemake --cores 16 \
#           --snakefile transient_GCM_historical.smk \
#           --executor slurm --jobs 100 --default-resources slurm_account=uusei11758 \
#           --config simulation=$simulation \
#                     outputDirectory=$outputDirectory \
#                     run_globgm_dir=$run_globgm_dir \
#                     data_dir=$data_dir \
#                     period="historical"
# wait

#RUN SSP126
outputDirectory=/scratch-shared/_bvjaarsveld1/cmip6_runs/$simulation
data_dir=/scratch-shared/_bvjaarsveld1/_data
run_globgm_dir=/home/bvjaarsveld1/projects/workflow/GLOBGM/run_simulation

cd $run_globgm_dir/model_job_scripts
snakemake --cores 16 \
          --snakefile transient_GCM_SSP.smk \
          --executor slurm --jobs 100 --default-resources slurm_account=uusei11758 \
          --config simulation=$simulation \
                    outputDirectory=$outputDirectory \
                    run_globgm_dir=$run_globgm_dir \
                    data_dir=$data_dir \
                    period="ssp126"
wait


#RUN SSP126
#RUN SSP126
#RUN SSP126