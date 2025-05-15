#!/bin/bash -l
#SBATCH --partition=fat_genoa
#SBATCH -N 1
#SBATCH -t 12:00:00
#SBATCH --cpus-per-task=1
#SBATCH --ntasks-per-node=192
#SBATCH --output=/projects/prjs1222/GLOBGM/analysis/cmip6_runs/thiel_sen_slope/slurmOut/historical_ref.out
source ${HOME}/.bashrc
mamba activate globgm

cd /projects/prjs1222/GLOBGM/analysis/cmip6_runs/thiel_sen_slope

input_dir_historical=/projects/prjs1222/globgm_output/reference_gswp3-w5e5/historical_with_pump/annual

export NUMBA_NUM_THREADS=191
taskset -c 0-191 python -u ./calc_thiel_sen_slope.py $input_dir_historical "hds" "historical_ref"
wait