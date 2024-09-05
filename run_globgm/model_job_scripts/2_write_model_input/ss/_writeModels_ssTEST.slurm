#!/bin/bash -l
#SBATCH -N 1
#SBATCH -t 02:00:00
#SBATCH --partition=genoa
#SBATCH --exclusive
#SBATCH --constraint=scratch-node
#SBATCH -o /projects/0/einf4705/workflow/GLOBGM/run_globgm/model_job_scripts/2_write_model_input/ss/_writeModels_ssTEST.out

source ${HOME}/.bashrc
mamba activate globgm

#Write tiles input
modelRoot=/projects/0/einf4705/workflow/output/gfdl-esm4/ss
simulation=$(basename $(dirname $modelRoot))
#TODO this too static
cmip6InputFolder=/scratch-shared/bvjaarsv/cmip6_input/$simulation/historical/natural
pcrglobInputFolder=$(realpath ../_data/globgm_input)
forcingDir=/scratch-shared/bvjaarsv/_writeModelTest/forcing_input
mkdir -p $forcingDir
model_input=$(realpath $modelRoot/model_input/1_write_tiled_parameter_data)
OUT_DIR=/scratch-shared/bvjaarsv/_writeModelTest/input_map/steady-state
IN_DIR=$(realpath ../_data/globgm_input)
pcrlobwbDir=$(realpath ../model_tools_src/python/pcr-globwb)

#SUBMODELS INPUT
exe=$(realpath ../_bin/mf6ggm_181121)
inpmod=mf6_mod_ss.inp
inpexe=mf6ggm_ss.inp
moddir=$modelRoot/mf6_mod
yodaInput=$(realpath ../_data/globgm_input)
inpdir=$(realpath $modelRoot/model_input/3_partition_and_write_model_input/steady-state)
globgmDir=$TMPDIR

# Step 1 preprocess the 5 arcmin netcdf data to 30 arcseconds
process_gwRecharge() {
    local tempdir=${TMPDIR}/gwRecharge
    local inFile=$(find "$cmip6InputFolder" -type f -name "*gwRecharge*")
    local outFile=$tempdir/average_gwRecharge_m_per_day
    mkdir -p $tempdir
    cdo -L -f nc4 -setunit,m.day-1 -divc,365.25 -timmean -yearsum -selyear,1960/2014 $inFile $outFile.temp.nc
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
    local gridFile=$pcrglobInputFolder/cdo_gridarea_30sec.map
    mkdir -p $tempdir

    cdo -L -f nc4 -setunit,m.day-1 -divc,365.25 -timmean -yearsum -selyear,1960/2014 $inFile $outFile.temp.nc
    local info=$(gdalinfo $gridFile)
    local xres=$(echo "$info" | grep "Pixel Size" | awk -F'=' '{print $2}' | awk -F',' '{print $1}' | tr -d '()')
    local yres=$(echo "$info" | grep "Pixel Size" | awk -F'=' '{print $2}' | awk -F',' '{print $2}' | tr -d '()')
    local ulx=$(echo "$info" | grep "Upper Left"  | awk '{print $3}' | tr -d ',' | tr -d '()')
    local uly=$(echo "$info" | grep "Upper Left"  | awk '{print $4}' | tr -d ',' | tr -d '()')
    local lrx=$(echo "$info" | grep "Lower Right" | awk '{print $4}' | tr -d ',' | tr -d '()')
    local lry=$(echo "$info" | grep "Lower Right" | awk '{print $5}' | tr -d ',' | tr -d '()')
    gdalwarp -tr $xres $yres -r bilinear -overwrite -te $ulx $lry $lrx $uly -of GTiff $outFile.temp.nc ${outFile}_30sec.tif
    gdal_translate -of PCRaster ${outFile}_30sec.tif ${outFile}.temp.map

    # # Calculate discharge
    cd $tempdir
    cp $pcrglobInputFolder/cdo_gridarea_30sec.map .
    cp $pcrglobInputFolder/lddsound_30sec_version_202005XX.map .
    cp $pcrglobInputFolder/waterBodyIds_lakes_and_reservoirs_30sec_global_2019_version_202005XX.map .

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

# process_gwRecharge & process_totalRunoff_to_Discharge
# wait

# # #Step 2 Write .map tiles
cd $pcrlobwbDir
cp /projects/0/einf4705/workflow/GLOBGM/run_globgm/model_input/1_write_tiled_parameter_data/steady-state_config.ini $model_input/steady-state_config.ini

#EDWIN MODIFY OUTPUT DIRECTORY
OUT_DIR=/scratch-shared/bvjaarsv/_writeModelTest/input_map/steady-state
num=001
python deterministic_runner_for_monthly_offline_globgm.py $model_input/steady-state_config.ini debug steady-state-only tile_${num}-163 $IN_DIR $OUT_DIR $forcingDir &
wait

# # # Copy for post-processing
# for ((i=1; i<=163; i+=1));do
#     tile=$(printf "%03d" $i)
#     mkdir -p $modelRoot/input_map/steady-state/tile_${tile}-163/steady-state_only/maps && cp "${OUT_DIR}/tile_${tile}-163/steady-state_only/maps/top_uppermost_layer.map" "$modelRoot/input_map/steady-state/tile_${tile}-163/steady-state_only/maps" &
# done
# wait

# mkdir -p $moddir
# cp ${inpdir}/${inpmod} ${moddir}/${inpmod}
# cp ${inpdir}/${inpexe} ${moddir}/${inpexe}

# #REPLACE NECESSARY STRINGS
# sed -i "s|{yoda_input}|${yodaInput}|g" ${moddir}/${inpmod}
# sed -i "s|{globgm_dir}|${globgmDir}|g" ${moddir}/${inpmod}
# wait

# cd ${moddir}

# for ((i=1; i<=384; i+=12)); do
#     ii=$((i + 11))
#     if [ $ii -gt 384 ]; then
#         ii=384
#     fi
#     ${exe} ${inpexe} $i $ii &
# done
# wait

# cd $moddir/glob_ss/log
# num_files=$(ls | wc -l)
# [ $num_files -eq 384 ] || { echo "Some models are missing"; exit 1; }