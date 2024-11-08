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
data_dir=$4
outFile=$5
simulation=$(basename $(dirname $modelRoot))
cmip6InputFolder=$data_dir/cmip6_input/$simulation/historical
saveFolder=$modelRoot/forcing_input
PCR_GLOB_dir=$(realpath ../model_tools_src/python/pcr-globwb)


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
clone_file=$data_dir/globgm_input/global_30sec_clone.map
ldd_file=$data_dir/globgm_input/lddsound_30sec_version_202005XX_correct_lat.nc
cell_area_file=$data_dir/globgm_input/cdo_grid_area_30sec_map_correct_lat.nc
lake_and_reservoir_file=$data_dir/globgm_input/lakes_and_reservoirs_30sec_global_2019_version_202005XX.nc
for ((year = start_year; year <= end_year; year+=2)); do
    yearStart=$year
    yearEnd=$(($yearStart + 1))
    if [ $yearEnd -gt $end_year ]; then
        yearEnd=$end_year
    fi
    tempDir=$TMPDIR/temp_${yearEnd}
    mkdir -p $tempDir
    python deterministic_runner_for_calculating_discharge_from_runoff.py $tempDir $yearStart $yearEnd $saveFolder $monthly_runoff_file $monthly_recharge_file $monthly_abstraction_file \
                                                                         $clone_file $ldd_file $cell_area_file $lake_and_reservoir_file &
done
wait

outFile="${outFile%?}"
touch "${outFile}$SLURM_ARRAY_TASK_ID"