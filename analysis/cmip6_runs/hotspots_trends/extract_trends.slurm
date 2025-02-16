#!/bin/bash -l
#SBATCH --partition=fat_genoa
#SBATCH -N 1
#SBATCH -t 12:00:00
#SBATCH -J extract_trends
#SBATCH --cpus-per-task 1 
#SBATCH --ntasks-per-node=192
#SBATCH --exclusive
#SBATCH --out=/home/bvjaarsveld1/projects/workflow/GLOBGM/analysis/cmip6_runs/hotspots_trends/slurmOut/extract_trends.out

source ${HOME}/.bashrc
mamba activate globgm

cd /home/bvjaarsveld1/projects/workflow/GLOBGM/analysis/cmip6_runs/hotspots_trends

taskset -c 0-191 python -u ./extract_trends.py
wait