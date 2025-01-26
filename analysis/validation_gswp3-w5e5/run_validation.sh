#!/bin/bash
#SBATCH -N 1
#SBATCH -n 192
#SBATCH -t 12:00:00
#SBATCH -p fat_genoa
#SBATCH --exclusive
#SBATCH -J validation_gswp3-w5e5


source ${HOME}/.bashrc
mamba activate globgm

cd /home/bvjaarsveld1/projects/workflow/GLOBGM/analysis/validation_gswp3-w5e5


python -u ./create_validation_dataset.py
wait
python -u ./validate_metrics.py
