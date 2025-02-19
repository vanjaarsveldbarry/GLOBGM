#!/bin/bash -l
#SBATCH --partition=fat_genoa
#SBATCH -N 1
#SBATCH -t 12:00:00
#SBATCH --cpus-per-task 1 
#SBATCH --ntasks-per-node=192
#SBATCH --output=/home/bvjaarsveld1/projects/workflow/GLOBGM/analysis/cmip6_runs/thiel_sen_slope/slurmOut/create_plots_data.out

cd /home/bvjaarsveld1/projects/workflow/GLOBGM/analysis/cmip6_runs/thiel_sen_slope

source ${HOME}/.bashrc
mamba activate globgm

python -u /home/bvjaarsveld1/projects/workflow/GLOBGM/analysis/cmip6_runs/thiel_sen_slope/create_plot_datasets.py