#!/bin/bash -l
#SBATCH -N 1
#SBATCH -J ini_con
#SBATCH -t 119:00:00
#SBATCH --partition=genoa
#SBATCH --output=/home/bvjaarsveld1/projects/workflow/GLOBGM/run_simulation/model_job_scripts/slurnOut/_ini_conditions_test.out

source ${HOME}/.bashrc
mamba activate globgm

simulation=gswp3-w5e5

outputDirectory=/scratch-shared/_bvjaarsveld1/output_gswp3-w5e5
data_dir=/scratch-shared/_bvjaarsveld1/_data
run_globgm_dir=/home/bvjaarsveld1/projects/workflow/GLOBGM/run_simulation

cd $run_globgm_dir/model_job_scripts

snakemake --cores 16 \
            --snakefile transient_gswp3-w5e5.smk \
            --executor slurm --jobs 20 --default-resources slurm_account=uusei11758 \
            --config simulation=$simulation \
                    outputDirectory=$outputDirectory \
                    run_globgm_dir=$run_globgm_dir \
                    data_dir=$data_dir