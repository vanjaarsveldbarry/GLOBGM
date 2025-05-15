#!/bin/bash
#SBATCH -N 1
#SBATCH -n 192
#SBATCH -t 12:00:00
#SBATCH -p fat_genoa
#SBATCH --exclusive
#SBATCH -J validation_gswp3-w5e5
#SBATCH -o /projects/prjs1222/GLOBGM/analysis/historical_reference_gswp3-w5e5/validation/slurmOut/validation_gswp3-w5e5.out


source ${HOME}/.bashrc
mamba activate globgm

cd /projects/prjs1222/GLOBGM/analysis/historical_reference_gswp3-w5e5/validation

taskset -c 0-190 python -u ./create_validation_dataset_wtd.py
wait
python -u ./validate_metrics_wtd.py
wait

python -u ./kge_cdf_plot.py