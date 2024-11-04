#!/bin/bash -l
#SBATCH -N 1
#SBATCH -t 02:00:00
#SBATCH --partition=genoa
#SBATCH --exclusive
#SBATCH --constraint=scratch-node

source ${HOME}/.bashrc
mamba activate globgm

#Write tiles input
modelRoot=$1
data_dir=$2
outFile=$3
calib_str=$4


simulation=$(basename $(dirname $modelRoot))
cmip6InputFolder=$data_dir/cmip6_input/$simulation/historical_natural
forcingDir=$TMPDIR/forcing_input
_pcr_calc_files=$data_dir/globgm_input/_pcrcalc_files
mkdir -p $forcingDir

model_input=$(realpath $modelRoot/model_input/2_partition_and_write_model_input)
OUT_DIR=$TMPDIR/input_map/steady-state
IN_DIR=$data_dir/globgm_input
pcrlobwbDir=$(realpath ../model_tools_src/python/pcr-globwb)

# #SUBMODELS INPUT
exe=$data_dir/_bin/mf6ggm_181121
inpmod=mf6_mod_ss.inp
inpexe=mf6ggm_ss.inp
moddir=$modelRoot/mf6_mod
yodaInput=$data_dir/globgm_input
inpdir=$(realpath $modelRoot/model_input/2_partition_and_write_model_input/steady-state)
globgmDir=$TMPDIR

# Step 1 preprocess the 5 arcmin netcdf data to 30 arcseconds
process_gwRecharge() {
    local tempdir=${TMPDIR}/gwRecharge
    local inFile=$(find "$cmip6InputFolder" -type f -name "*gwRecharge*")
    local outFile=$tempdir/average_gwRecharge_m_per_day
    mkdir -p $tempdir

    years_array=($(cdo showyear $inFile))
    first_year=${years_array[0]}
    last_year=${years_array[-1]}

    cdo -L -f nc4 -setrtoc,-inf,0,0 -setunit,m.day-1 -divc,365.25 -timmean -yearsum -selyear,$first_year/$last_year $inFile $outFile.temp.nc    
    gdal_translate -of GTiff $outFile.temp.nc $outFile.temp.tif
    gdal_translate -of PCRaster ${outFile}.temp.tif ${outFile}.temp.map
    gdal_translate -of NETCDF ${outFile}.temp.map $tempdir/average_gwRecharge_m_per_day.map.nc
    cdo -L -invertlat $tempdir/average_gwRecharge_m_per_day.map.nc $tempdir/average_gwRecharge_m_per_dayTemp.nc
    ncwa -O -a time $tempdir/average_gwRecharge_m_per_dayTemp.nc $tempdir/average_gwRecharge_m_per_day.nc
    mv $tempdir/average_gwRecharge_m_per_day.nc $forcingDir
    rm -r $tempdir
}

process_totalRunoff_to_Discharge() {
    # Process totalRunoff -> Discharge
    local tempdir=${TMPDIR}/discharge
    local inFile=$(find "$cmip6InputFolder" -type f -name "*totalRunoff*")
    local outFile=$tempdir/average_totalRunoff_m_per_day
    mkdir -p $tempdir

    years_array=($(cdo showyear $inFile))
    first_year=${years_array[0]}
    last_year=${years_array[-1]}

    cdo -L -f nc4 -setunit,m.day-1 -divc,365.25 -timmean -yearsum -selyear,$first_year/$last_year $inFile $outFile.temp.nc
    local info=$(gdalinfo $_pcr_calc_files/cdo_gridarea_30sec.map)
    local xres=$(echo "$info" | grep "Pixel Size" | awk -F'=' '{print $2}' | awk -F',' '{print $1}' | tr -d '()')
    local yres=$(echo "$info" | grep "Pixel Size" | awk -F'=' '{print $2}' | awk -F',' '{print $2}' | tr -d '()')
    local ulx=$(echo "$info" | grep "Upper Left"  | awk '{print $3}' | tr -d ',' | tr -d '()')
    local uly=$(echo "$info" | grep "Upper Left"  | awk '{print $4}' | tr -d ',' | tr -d '()')
    local lrx=$(echo "$info" | grep "Lower Right" | awk '{print $4}' | tr -d ',' | tr -d '()')
    local lry=$(echo "$info" | grep "Lower Right" | awk '{print $5}' | tr -d ',' | tr -d '()')
    gdalwarp -tr $xres $yres -r bilinear -overwrite -te $ulx $lry $lrx $uly -of GTiff $outFile.temp.nc ${outFile}_30sec.tif
    gdal_translate -of PCRaster ${outFile}_30sec.tif ${outFile}.temp.map

    # # # # Calculate discharge
    cd $tempdir
    cp -r $_pcr_calc_files/* $tempdir
    local cdo_gridarea_30sec=cdo_gridarea_30sec.map
    local lddsound_30sec_version_202005XX=lddsound_30sec_version_202005XX.map
    local average_totalRunoff_m_per_day_30sec=average_totalRunoff_m_per_day.temp.map
    local waterBodyIds_lakes_and_reservoirs_30sec_global_2019_version_202005XX=waterBodyIds_lakes_and_reservoirs_30sec_global_2019_version_202005XX.map

    pcrcalc average_river_discharge_m3_per_second.map = "cover(max(0.0, catchmenttotal($average_totalRunoff_m_per_day_30sec * $cdo_gridarea_30sec, ldd($lddsound_30sec_version_202005XX)) / (24.*3600.)), 0.0)"
    pcrcalc average_lake_reservoir_discharge_m3_per_second.map = "if(scalar($waterBodyIds_lakes_and_reservoirs_30sec_global_2019_version_202005XX) gt 0, areamaximum(average_river_discharge_m3_per_second.map, nominal($waterBodyIds_lakes_and_reservoirs_30sec_global_2019_version_202005XX)))"
    pcrcalc average_discharge_m3_per_second.map = "cover(average_lake_reservoir_discharge_m3_per_second.map, average_river_discharge_m3_per_second.map)"
    gdal_translate -of NETCDF average_discharge_m3_per_second.map $tempdir/average_discharge_m3_per_second.map.nc
    cdo -L -invertlat $tempdir/average_discharge_m3_per_second.map.nc $tempdir/average_discharge_m3_per_second.nc
    mv $tempdir/average_discharge_m3_per_second.nc $forcingDir
    rm -r $tempdir
}
process_gwRecharge & process_totalRunoff_to_Discharge
satAreaFile=$(find "$cmip6InputFolder" -type f -name "*sat_area_fraction_average*")
cp $satAreaFile $forcingDir
correctionFile=$(find "$cmip6InputFolder" -type d -name "*gwRecharge_correction_factor.zarr*")
cp -r $correctionFile $forcingDir
wait

# #Step 2 Write .map tiles
cd $pcrlobwbDir
counter=0
for ((i=1; i<=163; i+=1)); do
    num=$(printf "%03d" $((10#$i)))
    python deterministic_runner_for_monthly_offline_globgm.py $model_input/steady-state/steady-state_config.ini debug steady-state-only tile_${num}-163 $IN_DIR $OUT_DIR $forcingDir $calib_str &
    counter=$((counter+1))
    if [ $counter -eq 24 ]; then
        wait
        counter=0
    fi
done
wait

# Copy for post-processing
for ((i=1; i<=163; i+=1));do
    tile=$(printf "%03d" $i)
    mkdir -p $modelRoot/input_map/steady-state/tile_${tile}-163/steady-state_only/maps && cp "${OUT_DIR}/tile_${tile}-163/steady-state_only/maps/top_uppermost_layer.map" "$modelRoot/input_map/steady-state/tile_${tile}-163/steady-state_only/maps" &
done
wait

mkdir -p $moddir
cp ${inpdir}/${inpmod} ${moddir}/${inpmod}
cp ${inpdir}/${inpexe} ${moddir}/${inpexe}

# # #REPLACE NECESSARY STRINGS
sed -i "s|{yoda_input}|${yodaInput}|g" ${moddir}/${inpmod}
sed -i "s|{globgm_dir}|${globgmDir}|g" ${moddir}/${inpmod}
wait

cd ${moddir}

for ((i=1; i<=384; i+=12)); do
    ii=$((i + 11))
    if [ $ii -gt 384 ]; then
        ii=384
    fi
    ${exe} ${inpexe} $i $ii &
done
wait

cd $moddir/glob_ss/log
num_files=$(ls | wc -l)
[ $num_files -eq 384 ] || { echo "Some models are missing"; exit 1; }

wait 
touch $outFile