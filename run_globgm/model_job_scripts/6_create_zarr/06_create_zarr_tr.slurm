#!/bin/bash -l
#SBATCH -N 1
#SBATCH --exclusive
#SBATCH -t 02:00:00

source ${HOME}/.bashrc
mamba activate globgm

modelRoot=$1
year=2014
solution=s0$2

dir=$modelRoot/mf6_zarr

cd ../model_tools_src/python/to_zarr
wait

time python ./createZarr_tr.py $dir $year $solution
wait
zappend -t $dir/$solution.zarr $dir/temp_zarr_${solution}/$solution*.zarr
wait && rm -r $dir/temp_zarr_${solution}