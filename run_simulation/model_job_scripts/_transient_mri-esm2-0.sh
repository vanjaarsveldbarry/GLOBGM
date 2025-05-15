#!/bin/bash -l
#SBATCH -N 1
#SBATCH -J mri-esm2-0_ssp585
#SBATCH -t 24:00:00
#SBATCH --partition=genoa,rome
#SBATCH --output=/projects/prjs1222/GLOBGM/run_simulation/model_job_scripts/slurmOut/mri-esm2-0_ssp585.out

source ${HOME}/.bashrc
mamba activate globgm

simulation=mri-esm2-0

#RUN HISTORICAL
outputDirectory=/projects/prjs1222/globgm_output/$simulation
data_dir=/projects/prjs1222/globgm_input/_data
run_globgm_dir=/projects/prjs1222/GLOBGM/run_simulation

cd $run_globgm_dir/model_job_scripts

# snakemake --cores 16 \
#           --snakefile transient_GCM_historical.smk \
#           --executor slurm --jobs 100 --default-resources slurm_account=uus2024031 \
#           --config simulation=$simulation \
#                     outputDirectory=$outputDirectory \
#                     run_globgm_dir=$run_globgm_dir \
#                     data_dir=$data_dir \
#                     period="historical"
# wait

# RUN SSP126
# snakemake --cores 16 \
#           --snakefile transient_GCM_SSP.smk \
#           --executor slurm --jobs 100 --default-resources slurm_account=uus2024031 \
#           --config simulation=$simulation \
#                     outputDirectory=$outputDirectory \
#                     run_globgm_dir=$run_globgm_dir \
#                     data_dir=$data_dir \
#                     period="ssp126"
# wait
# RUN SSP370
# snakemake --cores 16 \
#           --snakefile transient_GCM_SSP.smk \
#           --executor slurm --jobs 100 --default-resources slurm_account=uus2024031 \
#           --config simulation=$simulation \
#                     outputDirectory=$outputDirectory \
#                     run_globgm_dir=$run_globgm_dir \
#                     data_dir=$data_dir \
#                     period="ssp370"
# wait

# # RUN SSP585
snakemake --cores 16 \
          --snakefile transient_GCM_SSP.smk \
          --executor slurm --jobs 100 --default-resources slurm_account=uus2024031 \
          --config simulation=$simulation \
                    outputDirectory=$outputDirectory \
                    run_globgm_dir=$run_globgm_dir \
                    data_dir=$data_dir \
                    period="ssp585"
wait