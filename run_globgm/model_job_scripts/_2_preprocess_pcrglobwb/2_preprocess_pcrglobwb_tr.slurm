#!/bin/bash -l
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem-per-cpu=1750
#SBATCH --time=00:30:00

source ${HOME}/.bashrc
mamba activate globgm

modelRoot=$1
slurmDir_tr=$2
cmip6InputFolder=$modelRoot/cmip6_input
pcrglobInputFolder=$(realpath ../_data/globgm_input)
PCR_GLOB_dir=$(realpath ../model_tools_src/python/pcr-globwb)
saveFolder=$modelRoot/forcing_input
trPreprocessingIni=$(realpath ../model_input/_2_preprocess_pcrglobwb/transient_preprocessing.ini)

tempdir=$saveFolder/temp
mkdir -p $tempdir

gwRechargeFile=$(find "$cmip6InputFolder" -type f -name "*gwRecharge*")
cp $gwRechargeFile $saveFolder/gwRecharge_monthTot_output.nc

totalGroundwaterAbstractionFile=$(find "$cmip6InputFolder" -type f -name "*totalGroundwaterAbstraction*")
cp $totalGroundwaterAbstractionFile $saveFolder/totalGroundwaterAbstraction_monthTot_output.nc
wait

# #Preprocess discharge
monthly_runoff_file=$(find "$cmip6InputFolder" -type f -name "*totalRunoff*")
# extract_years() {
#     nc_file=$1


#     # Extract the filename from the path
#     filename=$(basename $nc_file)

#     # Extract the start and end years
#     start_year=$(echo $filename | awk -F"_" '{print $(NF-2)}')
#     # end_year=$(echo $filename | awk -F"_" '{print $(NF-1)}')
#     end_year=1965 

# }
# extract_years $monthly_runoff_file
if [[ $monthly_runoff_file == *"historical"* ]]; then
    start_year=2014
    end_year=2014

else
    start_year=2015
    end_year=2015
fi

for ((year = start_year; year <= end_year; year+=3)); do
    year1=$year
    ((year2 = year1 + 1))
    ((year3 = year1 + 2))

    echo $trPreprocessingIni

    if (( $year2 > end_year ))&& (( $year3 > end_year )); then
        sbatch -n 32 --time=01:30:00 --mem-per-cpu=1750 -o "$slurmDir_tr/tr_discharge_$(basename "$folder")_${year}.out" \
        --wrap="cd $PCR_GLOB_dir && source ${HOME}/.bashrc && mamba activate globgm && python deterministic_runner_for_calculating_discharge_from_runoff.py $trPreprocessingIni $monthly_runoff_file $tempdir $year1"
    fi

    if (( $year3 > end_year )) && (( $year2 < end_year )); then
        sbatch -n 48 --time=01:30:00 --mem-per-cpu=1750 -o "$slurmDir_tr/tr_discharge_$(basename "$folder")_${year}.out" \
        --wrap="cd $PCR_GLOB_dir && source ${HOME}/.bashrc && mamba activate globgm && python deterministic_runner_for_calculating_discharge_from_runoff.py $trPreprocessingIni $monthly_runoff_file $tempdir $year1 &
                cd $PCR_GLOB_dir && source ${HOME}/.bashrc && mamba activate globgm && python deterministic_runner_for_calculating_discharge_from_runoff.py $trPreprocessingIni $monthly_runoff_file $tempdir $year2"
    fi

    if (( $year3 <= end_year )); then
        sbatch -n 64 --time=01:30:00 --mem-per-cpu=1750 -o "$slurmDir_tr/tr_discharge_$(basename "$folder")_${year}.out" \
        --wrap="cd $PCR_GLOB_dir && source ${HOME}/.bashrc && mamba activate globgm && python deterministic_runner_for_calculating_discharge_from_runoff.py $trPreprocessingIni $monthly_runoff_file $tempdir $year1 &
                cd $PCR_GLOB_dir && source ${HOME}/.bashrc && mamba activate globgm && python deterministic_runner_for_calculating_discharge_from_runoff.py $trPreprocessingIni $monthly_runoff_file $tempdir $year2 &
                cd $PCR_GLOB_dir && source ${HOME}/.bashrc && mamba activate globgm && python deterministic_runner_for_calculating_discharge_from_runoff.py $trPreprocessingIni $monthly_runoff_file $tempdir $year3"
    fi
done