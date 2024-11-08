#!/bin/bash -l
#SBATCH -N 1
#SBATCH -J sn_W5E5
#SBATCH -t 12:00:00
#SBATCH --partition=genoa
#SBATCH --output=sn_W5E5.out

source ${HOME}/.bashrc
mamba activate globgm

simulation=gswp3-w5e5
outputDirectory=/projects/0/einf4705/workflow/output
run_globgm_dir=/projects/0/einf4705/workflow/GLOBGM/run_globgm
data_dir=/projects/0/einf4705/_data

cd $run_globgm_dir/model_job_scripts

snakemake --cores 16 \
--snakefile Snakefile_W5E5.smk \
--config simulation=$simulation \
         outputDirectory=$outputDirectory \
         run_globgm_dir=$run_globgm_dir \
         data_dir=$data_dir
