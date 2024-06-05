#!/bin/bash -l
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem-per-cpu=1750
#SBATCH --time=00:30:00
#SBATCH --constraint=scratch-node
#SBATCH --partition=genoa,rome

tempDir=$TMPDIR/temp
mkdir -p $tempDir

source ${HOME}/.bashrc 
mamba activate globgm

trPreprocessingIni=$1
monthly_runoff_file=$2
year=$3
month=$4
saveFolder=$5
PCR_GLOB_dir=$6

cd $PCR_GLOB_dir
python deterministic_runner_for_calculating_discharge_from_runoff.py $trPreprocessingIni $monthly_runoff_file $tempDir $year $month $saveFolder