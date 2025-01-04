#!/bin/bash -l
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --time=00:30:00
#SBATCH --constraint=scratch-node
#SBATCH --partition=genoa,rome
#SBATCH --job-name=_writeINI


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
pcrglobInputFolder=$data_dir/globgm_input/_pcrcalc_files
zarrScripts=$(realpath ../model_tools_src/python/preprocess_zarr)
trPreprocessingIni=$modelRoot/model_input/1_write_tiled_parameter_data/transient_preprocessing.ini

mkdir -p $saveFolder

process_gwRecharge() {
    local tempdir=${TMPDIR}/gwRecharge
    local inFile=$(find "$cmip6InputFolder" -maxdepth 1 -type f -name "*gwRecharge*")
    local outFile=$tempdir/average_gwRecharge_m_per_day
    mkdir -p $tempdir
    cp $inFile $tempdir
    fileName=$(basename "$inFile")
    inFile=$tempdir/$fileName
    cdo -L -f nc4 -setrtoc,-inf,0,0 -setunit,m.day-1 -divc,365.25 -timmean -yearsum -selyear,1960/2014 $inFile $outFile.temp.nc
    gdal_translate -of GTiff $outFile.temp.nc $outFile.temp.tif
    gdal_translate -of PCRaster ${outFile}.temp.tif ${outFile}.temp.map
    gdal_translate -of NETCDF ${outFile}.temp.map $tempdir/average_gwRecharge_m_per_day.map.nc
    cdo -L -invertlat $tempdir/average_gwRecharge_m_per_day.map.nc $tempdir/average_gwRecharge_m_per_dayTemp.nc
    ncwa -O -a time $tempdir/average_gwRecharge_m_per_dayTemp.nc $tempdir/average_gwRecharge_m_per_day.nc
    mv $tempdir/average_gwRecharge_m_per_day.nc $saveFolder
    rm -r $tempdir
}

process_totalRunoff_to_Discharge() {
    # Process totalRunoff -> Discharge
    local tempdir=${TMPDIR}/discharge
    local inFile=$(find "$cmip6InputFolder" -maxdepth 1 -type f -name "*totalRunoff*")
    local outFile=$tempdir/average_totalRunoff_m_per_day
    local gridFile=$pcrglobInputFolder/cdo_gridarea_30sec.map
    mkdir -p $tempdir

    cp $inFile $tempdir
    cp $gridFile $tempdir
    fileName=$(basename "$inFile")
    inFile=$tempdir/$fileName

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

    # Calculate discharge
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
    mv $tempdir/average_discharge_m3_per_second.nc $saveFolder
    rm -r $tempdir
}

process_gwRecharge & process_totalRunoff_to_Discharge
satAreaFile=$(find "$cmip6InputFolder" -type f -name "*sat_area_fraction_average*")
cp $satAreaFile $saveFolder
satAreaFile_monthly=$(find "$cmip6InputFolder" -type f -name "*sat_area_fraction_monthly*")
cp $satAreaFile_monthly $saveFolder
correctionFile=$(find "$data_dir/cmip6_input/$simulation/historical_natural" -type d -name "*gwRecharge_correction_factor.zarr*")
cp -r $correctionFile $saveFolder
wait

python -u $zarrScripts/createZarr.py $pcrglobInputFolder $saveFolder $start_year $end_year
wait

touch $outFile
