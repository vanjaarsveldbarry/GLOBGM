#!/bin/bash -l
#SBATCH -N 1
#SBATCH --exclusive
#SBATCH --constraint=scratch-node
#SBATCH -t 12:00:00
#SBATCH --partition=rome

source ${HOME}/.bashrc
mamba activate globgm

modelRoot=$1
solution=s0$2
start_year=$3
end_year=$4
outFile=${5}/6_create_zarr/6_create_zarr_tr_${2}.out
dir=$modelRoot/mf6_zarr
cd ../model_tools_src/python/to_zarr
wait

for ((year=start_year; year<=end_year; year++))
do
    time python -u ./createZarr_tr.py $dir $year $solution $TMPDIR &
done
wait
echo "INNITIAL WRITE DONE"

time python -u ./mergeZarr_tr.py $dir $solution $TMPDIR 
wait