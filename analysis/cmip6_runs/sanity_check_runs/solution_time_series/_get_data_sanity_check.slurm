#!/bin/bash -l
#SBATCH --partition=fat_genoa
#SBATCH -N 1
#SBATCH -t 24:00:00
#SBATCH --cpus-per-task=1
#SBATCH --ntasks-per-node=192
#SBATCH --exclusive
#SBATCH -o /projects/prjs1222/GLOBGM/analysis/cmip6_runs/sanity_check_runs/solution_time_series/slurmOut/_get_data_sanity_check_%j.out


source ${HOME}/.bashrc
mamba activate globgm

cd /projects/prjs1222/GLOBGM/analysis/cmip6_runs/sanity_check_runs/solution_time_series

python -u ./get_data_sanity_check.py