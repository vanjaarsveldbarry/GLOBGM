#!/bin/bash -l
#SBATCH --partition=genoa
#SBATCH -N 1
#SBATCH -t 72:00:00
#SBATCH -J data_copy
#SBATCH --cpus-per-task 1
#SBATCH --ntasks-per-node=190
#SBATCH --exclusive
#SBATCH --output=data_copy.out

module load 2023
module load mpifileutils/0.11.1-gompi-2023a


source_dir=PATH_TO_SOURCE_FOLDER
target_dir=PATH_TARGET_FOLDER


mpirun -np 190 dcp $source_dir $target_dir