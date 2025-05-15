#!/bin/bash -l
#SBATCH --partition=fat_genoa
#SBATCH -N 1
#SBATCH -t 12:00:00
#SBATCH --cpus-per-task 1 
#SBATCH --ntasks-per-node=192
#SBATCH --output=/projects/prjs1222/GLOBGM/analysis/cmip6_runs/thiel_sen_slope/slurmOut/create_plots_data_historical.out

cd /projects/prjs1222/GLOBGM/analysis/historical_reference_gswp3-w5e5/thiel_sen_slope

source ${HOME}/.bashrc
mamba activate globgm

python -u ./create_plot_datasets_historical.py