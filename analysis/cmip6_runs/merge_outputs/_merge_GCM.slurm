#!/bin/bash -l
#SBATCH --partition=fat_genoa
#SBATCH --constraint=scratch-node
#SBATCH -N 1
#SBATCH -t 12:00:00
#SBATCH -J merge
#SBATCH --cpus-per-task 1 
#SBATCH --ntasks-per-node=192
#SBATCH --exclusive
echo $TMPDIR
df -kh $TMPDIR

source ${HOME}/.bashrc
mamba activate globgm

cd /home/bvjaarsveld1/projects/workflow/GLOBGM/analysis/cmip6_runs/merge_outputs

module load 2023
module load mpifileutils/0.11.1-gompi-2023a 

input_dir=/scratch-shared/globgm_scratch/cmip6_runs/$GCM/$scenario/mf6_post
save_dir=/scratch-shared/globgm_scratch/cmip6_runs/$GCM/$scenario/merged
temp_dir=$TMPDIR/$GCM/$scenario/$variable
mkdir -p $temp_dir/input $temp_dir/output $save_dir

mpirun -np 190 dcp $input_dir/*_$variable.zarr $temp_dir/input
wait

python -u ./initilalise_zarrStore.py $temp_dir $variable $time_chunk
wait

taskset -c 0-191 python -u ./rechunk.py $temp_dir $GCM $scenario $variable $time_chunk
wait

mpirun -np 190 dcp $temp_dir/output/$variable.zarr $save_dir
wait