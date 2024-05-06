#!/bin/bash -l
#SBATCH --partition=genoa
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=00:15:00


source ${HOME}/.bashrc
mamba activate globgm

modelRoot=$1
solution=s0$2

root=$(realpath ./globgm/model_tools_src/python/to_zarr)

inputFolder=$modelRoot/mf6_post
outputFolder=$modelRoot/mf6_zarr

mkdir -p $outputFolder/temp

python -u $root/createZarr.py $inputFolder $outputFolder $solution
wait #&& rm -r $outputFolder/temp

# cd $outputFolder
# file_list=$(find $outputFolder/temp -name "*s04*hds*" -type d)
# zappend -t $outputFolder/test/mycube.zarr $file_list