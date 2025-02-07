#!/bin/bash -l
#SBATCH -N 1
#SBATCH -J test
#SBATCH -t 12:00:00
#SBATCH --partition=genoa
#SBATCH --exclusive
#SBATCH --output=/home/bvjaarsveld1/projects/workflow/GLOBGM/analysis/cmip6_runs/test.out

source ${HOME}/.bashrc
mamba activate globgm
export NUMBA_NUM_THREADS=190
python -u /home/bvjaarsveld1/projects/workflow/GLOBGM/analysis/cmip6_runs/batch_workload_numba.py