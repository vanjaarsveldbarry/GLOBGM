#!/bin/bash -l
#SBATCH --nodes=1
#SBATCH --exclusive
#SBATCH --time=06:00:00
#SBATCH --partition=fat_genoa
#SBATCH --job-name=_writeInput


source ${HOME}/.bashrc
mamba activate globgm

modelRoot=$1
start_year=$2
end_year=$3
simulation=$(basename $(dirname $modelRoot))
cmip6InputFolder=/scratch-shared/bvjaarsv/cmip6_input/$simulation/historical
saveFolder=$modelRoot/forcing_input
PCR_GLOB_dir=$(realpath ../model_tools_src/python/pcr-globwb)
trPreprocessingIni=$modelRoot/model_input/1_write_tiled_parameter_data/transient_preprocessing.ini

diff=$(($end_year - $start_year))
if [ $SLURM_ARRAY_TASK_ID -eq 1 ]; then
    start_year=$start_year
    if [ $diff -lt 50 ]; then
        end_year=$end_year
    else
        end_year=$(($start_year + 49))
    fi
fi

if [ $SLURM_ARRAY_TASK_ID -eq 2 ]; then
    start_year=$(($start_year + 50))
    if [ $diff -lt 100 ]; then
        end_year=$end_year
    fi
fi
mkdir -p $saveFolder
cd $PCR_GLOB_dir
monthly_runoff_file=$(find "$cmip6InputFolder" -maxdepth 1 -type f -name "*totalRunoff*")
monthly_recharge_file=$(find "$cmip6InputFolder" -maxdepth 1 -type f -name "*gwRecharge*")
monthly_abstraction_file=$(find "$cmip6InputFolder" -maxdepth 1 -type f -name "*totalGroundwaterAbstraction*")
for ((year = start_year; year <= end_year; year+=2)); do
    yearStart=$year
    yearEnd=$(($yearStart + 1))
    if [ $yearEnd -gt $end_year ]; then
        yearEnd=$end_year
    fi
    tempDir=$TMPDIR/temp_${yearEnd}
    mkdir -p $tempDir
    python deterministic_runner_for_calculating_discharge_from_runoff.py $tempDir $trPreprocessingIni $yearStart $yearEnd $saveFolder $monthly_runoff_file $monthly_recharge_file $monthly_abstraction_file &
done
wait