#!/bin/bash -l
#SBATCH -N 1
#SBATCH -J sn_W5E5
#SBATCH -t 12:00:00
#SBATCH --partition=genoa
#SBATCH --output=sn_W5E5.out

source ${HOME}/.bashrc
mamba activate globgm

simulation=$1
outputDirectory=$2
run_globgm_dir=$3
data_dir=$4

cd $run_globgm_dir/model_job_scripts

snakemake -n --cores 16 --until prepare_model_partitioning \
        --snakefile transient_no_pump_run.smk \
        --config simulation=$simulation \
                outputDirectory=$outputDirectory \
                run_globgm_dir=$run_globgm_dir \
                data_dir=$data_dir