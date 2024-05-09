#!/bin/bash -l
#SBATCH --partition=genoa
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=00:15:00


source ${HOME}/.bashrc
mamba activate globgm

modelRoot=$1
solution=s0$2

inputFolder=$modelRoot/mf6_post
outputFolder=$modelRoot/mf6_to_zarr

mkdir -p $outputFolder
cd ../model_tools_src/python/to_zarr
wait

python -u ./createZarr_ss.py $inputFolder $outputFolder $solution
wait