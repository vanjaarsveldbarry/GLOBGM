#!/bin/bash
#SBATCH --job-name=bias_calculation
#SBATCH -p fat_genoa
#SBATCH -n 32

source ${HOME}/.bashrc
mamba activate globgm

sim_dir=$1
out_file=$2
_python_script=$3
osbserved_shapefile=$4

output_dir=$sim_dir/mf6_post/output_validation
python $_python_script $output_dir $sim_dir $osbserved_shapefile
wait
touch $out_file
