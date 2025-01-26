#!/bin/bash -l
#SBATCH -N 1
#SBATCH -J ini_con
#SBATCH -t 119:00:00
#SBATCH --partition=genoa
#SBATCH --output=/projects/prjs1222/GLOBGM/run_simulation/model_job_scripts/slurmOut/gswp3-w5e5_no_pump.out

source ${HOME}/.bashrc
mamba activate globgm

simulation=gswp3-w5e5

outputDirectory=/projects/prjs1222/globgm_output/historical_no_pump_natural
data_dir=/projects/prjs1222/globgm_input/_data
run_globgm_dir=/projects/prjs1222/GLOBGM/run_simulation

cd $run_globgm_dir/model_job_scripts

# snakemake --unlock --cores 16 \
# snakemake -n --report transient_gswp3-w5e5_report.html --cores 16 \
snakemake --cores 16 \
          --snakefile transient_gswp3-w5e5_natural.smk \
          --executor slurm --jobs 100 --default-resources slurm_account=uus2024031 \
          --config simulation=$simulation \
                    outputDirectory=$outputDirectory \
                    run_globgm_dir=$run_globgm_dir \
                    data_dir=$data_dir