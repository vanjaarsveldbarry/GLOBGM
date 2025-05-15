#!/bin/bash
#SBATCH -N 1
#SBATCH -t 12:00:00
#SBATCH -p genoa
#SBATCH --tasks-per-node=180
#SBATCH --cpus-per-task=1
#SBATCH -J chmod_scratch
#SBATCH -o /projects/prjs1222/GLOBGM/chmod_scratch.out

module load 2023
module load mpifileutils/0.11.1-gompi-2023a 

mpirun -np 180 dchmod --mode 777 /scratch-shared/globgm_scratch