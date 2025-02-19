#!/bin/bash -l
#SBATCH --partition=fat_genoa
#SBATCH -N 1
#SBATCH -t 12:00:00
#SBATCH -J extract_trends
#SBATCH --cpus-per-task 1 
#SBATCH --ntasks-per-node=32
#SBATCH --out=/projects/prjs1222/GLOBGM/analysis/cmip6_runs/sanity_check_runs/hotspot_time_series/slurmOut/extract_trends.out

source ${HOME}/.bashrc
mamba activate globgm

cd /projects/prjs1222/GLOBGM/analysis/cmip6_runs/sanity_check_runs/hotspot_time_series

python -u ./extract_trends.py
wait