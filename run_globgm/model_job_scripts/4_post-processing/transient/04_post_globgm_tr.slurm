#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=00:30:00
#SBATCH --partition=genoa,rome
#SBATCH --exclusive

modelRoot=$1
solution=$2
startDate=$3
endDate=$4
var=$5

source ${HOME}/.bashrc
mamba activate globgm

to_zarrFolder=$(realpath ../model_tools_src/python/to_zarr)
_zarrWriter=$(realpath ./4_post-processing/transient/_zarrWriter.slurm)

dir=$modelRoot/mf6_post
mkdir -p $dir

# Create empty final zarr store
python -u $to_zarrFolder/createZarr_tr.py $modelRoot $solution $dir $startDate $endDate wtd
python -u $to_zarrFolder/createZarr_tr.py $modelRoot $solution $dir $startDate $endDate hds
wait

sbatch --exclusive -o $modelRoot/slurm_logs/4_post-processing/_s0${solution}_zarrWriter/${solution}_wtd.out $_zarrWriter $modelRoot wtd $solution $startDate $endDate
sbatch --exclusive -o $modelRoot/slurm_logs/4_post-processing/_s0${solution}_zarrWriter/${solution}_hds.out $_zarrWriter $modelRoot hds $solution $startDate $endDate