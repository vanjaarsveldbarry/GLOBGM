#!/bin/bash -l
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --time=00:30:00
#SBATCH --partition=genoa,rome

tempDir=$TMPDIR/temp
mkdir -p $tempDir

source ${HOME}/.bashrc 
mamba activate globgm

trPreprocessingIni=$1
year=$2
month=$3
saveFolder=$4
PCR_GLOB_dir=$5
monthly_runoff_file=$6
monthly_recharge_file=$7
monthly_abstraction_file=$8

cd $PCR_GLOB_dir
python deterministic_runner_for_calculating_discharge_from_runoff.py $tempDir $trPreprocessingIni $year $month $saveFolder $monthly_runoff_file $monthly_recharge_file $monthly_abstraction_file