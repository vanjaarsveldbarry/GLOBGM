#!/bin/bash
#SBATCH -N 1
#SBATCH -n 192
#SBATCH -t 12:00:00
#SBATCH -p fat_genoa
#SBATCH --exclusive
#SBATCH -J validation_gswp3-w5e5
#SBATCH -o /home/bvjaarsveld1/projects/workflow/GLOBGM/analysis/validation_gswp3-w5e5/validation_gswp3-w5e5.out


source ${HOME}/.bashrc
mamba activate globgm

cd /home/bvjaarsveld1/projects/workflow/GLOBGM/analysis/validation_gswp3-w5e5

python -u ./create_validation_dataset_wtd.py
wait
python -u ./validate_metrics_wtd.py
wait


python -u ./create_validation_dataset_hds.py
wait
python -u ./validate_metrics_hds.py
wait
