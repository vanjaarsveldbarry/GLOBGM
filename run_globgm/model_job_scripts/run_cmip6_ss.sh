#!/bin/bash -l
#SBATCH -N 1
#SBATCH -J sn_ss_W5E5
#SBATCH -t 24:00:00
#SBATCH --partition=genoa
#SBATCH --output=/projects/0/einf4705/workflow/GLOBGM/run_globgm/model_job_scripts/sn_W5E5.out

source ${HOME}/.bashrc
mamba activate globgm

simulation=gswp3-w5e5
outputDirectory=/projects/0/einf4705/workflow/output/ss_test
run_globgm_dir=/projects/0/einf4705/workflow/GLOBGM/run_globgm
data_dir=/projects/0/einf4705/_data

cd $run_globgm_dir/model_job_scripts

#TEST ONE RULE
snakemake --rerun-incomplete --cores 1 --force -R --until write_model_input \
--snakefile Snakefile_W5E5_ss.smk \
--config simulation=$simulation \
         outputDirectory=$outputDirectory \
         run_globgm_dir=$run_globgm_dir \
         data_dir=$data_dir