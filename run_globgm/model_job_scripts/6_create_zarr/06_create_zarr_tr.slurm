#!/bin/bash -l
#SBATCH -N 1
#SBATCH --exclusive
#SBATCH -t 02:00:00

source ${HOME}/.bashrc
mamba activate globgm

modelRoot=$1
solution=s0$2
start_year=$3
end_year=$4

dir=$modelRoot/mf6_zarr

cd ../model_tools_src/python/to_zarr
wait

for ((year=start_year; year<=end_year; year++))
do
    time python ./createZarr_tr.py $dir $year $solution &
done
wait

zappend -t $dir/$solution.zarr $dir/temp_zarr_${solution}/$solution*.zarr
wait && find $dir/temp_zarr_${solution} -type d -mindepth 1 -print0 | xargs -0 -n 1 -P 48 -I {} rm -rf {}
wait && rm -r $dir/temp_zarr_${solution}