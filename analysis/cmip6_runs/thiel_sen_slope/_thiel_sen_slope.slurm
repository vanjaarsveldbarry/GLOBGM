#!/bin/bash -l
#SBATCH --partition=fat_genoa
#SBATCH -N 1
#SBATCH -t 12:00:00
#SBATCH --cpus-per-task=1
#SBATCH --ntasks-per-node=192
#SBATCH --constraint=scratch-node


echo $TMPDIR
df -kh $TMPDIR

source ${HOME}/.bashrc
mamba activate globgm
module load 2023
module load mpifileutils/0.11.1-gompi-2023a

cd /home/bvjaarsveld1/projects/workflow/GLOBGM/analysis/cmip6_runs/thiel_sen_slope

input_dir=/scratch-shared/globgm_scratch/cmip6_runs/$GCM/$scenario/merged
temp_dir=$TMPDIR/$GCM/$scenario/$variable
mkdir -p $temp_dir
wait

taskset -c 0-191 mpirun -np 190 dcp $input_dir/*$variable.zarr $temp_dir
wait

export NUMBA_NUM_THREADS=191
taskset -c 0-191 python -u ./calc_thiel_sen_slope.py $temp_dir $GCM $scenario $variable
wait