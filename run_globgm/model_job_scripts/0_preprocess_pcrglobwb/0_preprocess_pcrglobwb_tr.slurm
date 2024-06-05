#!/bin/bash -l
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem-per-cpu=1750
#SBATCH --time=00:30:00
#SBATCH --constraint=scratch-node
#SBATCH --partition=genoa,rome


source ${HOME}/.bashrc
mamba activate globgm

modelRoot=$1
slurmDir_tr=$2
start_year=$3
end_year=$4
cmip6InputFolder=$(dirname $modelRoot)/cmip6_input/historical
pcrglobInputFolder=$(realpath ../_data/globgm_input)
PCR_GLOB_dir=$(realpath ../model_tools_src/python/pcr-globwb)
saveFolder=$modelRoot/forcing_input
trPreprocessingIni=$(realpath ../model_input/_2_preprocess_pcrglobwb/transient_preprocessing.ini)

gwRechargeFile=$(find "$cmip6InputFolder" -type f -name "*gwRecharge*")
cp $gwRechargeFile $saveFolder/gwRecharge_monthTot_output.nc

totalGroundwaterAbstractionFile=$(find "$cmip6InputFolder" -type f -name "*totalGroundwaterAbstraction*")
cp $totalGroundwaterAbstractionFile $saveFolder/totalGroundwaterAbstraction_monthTot_output.nc
wait

# Create initial zarr store
zarrScripts=$(realpath ../model_tools_src/python/preprocess_zarr)
python -u $zarrScripts/createZarr.py $pcrglobInputFolder $saveFolder $start_year $end_year
wait

#Preprocess discharge
monthly_runoff_file=$(find "$cmip6InputFolder" -type f -name "*totalRunoff*")

for ((year = start_year; year <= end_year; year+=1)); do
    for ((month = 1; month <= 12; month++)); do
        sbatch -o "$slurmDir_tr/tr_discharge_${year}${month}.out" $zarrScripts/_tr_writer.slurm $trPreprocessingIni $monthly_runoff_file $year $month $saveFolder $PCR_GLOB_dir
    done
done