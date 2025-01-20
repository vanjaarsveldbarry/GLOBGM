localrules: setup_simulation,prepare_model_partitioning,write_model_forcing_setup,setup_output,
            _setup_subRun1,modify_ini_conditions_subRun1,
            _setup_subRun2,modify_ini_conditions_subRun2,
            _setup_subRun3,modify_ini_conditions_subRun3,
            _setup_subRun4,modify_ini_conditions_subRun4,
import os
SIMULATION = config["simulation"]
OUTPUTDIRECTORY = config["outputDirectory"]
RUN_GLOBGM_DIR = config["run_globgm_dir"]
PERIOD = config["period"]
MODELROOT_TR=f"{OUTPUTDIRECTORY}/{PERIOD}"
SLURMDIR_TR=f"{MODELROOT_TR}/slurm_logs"
DATA_DIR = config["data_dir"]

# STARTYEAR = 1960
# ENDYEAR = 2019

# subRun1_start,subRun1_end,subRun1_label = 1960,1975,1
# subRun2_start,subRun2_end,subRun2_label = 1976,1991,2
# subRun3_start,subRun3_end,subRun3_label = 1992,2007,3
# subRun4_start,subRun4_end,subRun4_label = 2008,2014,4
# nSpin = 1

STARTYEAR = 2015
ENDYEAR = 2020
subRun1_start,subRun1_end,subRun1_label = 2015,2015,1
subRun2_start,subRun2_end,subRun2_label = 2016,2016,2
subRun3_start,subRun3_end,subRun3_label = 2017,2017,3
subRun4_start,subRun4_end,subRun4_label = 2018,2018,4
subRun5_start,subRun5_end,subRun5_label = 2019,2019,5
subRun6_start,subRun6_end,subRun6_label = 2020,2020,6
nSpin = 1

rule all:
    input:
        # f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution1_wtd_subRun{subRun4_label}",
        # f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution1_hds_subRun{subRun4_label}",
        # f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution2_wtd_subRun{subRun4_label}",
        # f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution2_hds_subRun{subRun4_label}",
        # f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution3_wtd_subRun{subRun4_label}",
        # f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution3_hds_subRun{subRun4_label}",
        # f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution4_wtd_subRun{subRun4_label}",
        # f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution4_hds_subRun{subRun4_label}",
        # f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution1_hds_subRun{subRun3_label}",
        # f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution1_wtd_subRun{subRun3_label}",
        # f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution2_wtd_subRun{subRun3_label}",
        # f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution2_hds_subRun{subRun3_label}",
        # f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution3_wtd_subRun{subRun3_label}",
        # f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution3_hds_subRun{subRun3_label}",
        # f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution4_wtd_subRun{subRun3_label}",
        # f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution4_hds_subRun{subRun3_label}",
        # f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution1_hds_subRun{subRun2_label}",
        # f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution1_wtd_subRun{subRun2_label}",
        # f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution2_wtd_subRun{subRun2_label}",
        # f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution2_hds_subRun{subRun2_label}",
        # f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution3_wtd_subRun{subRun2_label}",
        # f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution3_hds_subRun{subRun2_label}",
        # f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution4_wtd_subRun{subRun2_label}",
        # f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution4_hds_subRun{subRun2_label}",
        # f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution1_hds_subRun{subRun1_label}",
        # f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution1_wtd_subRun{subRun1_label}",
        # f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution2_wtd_subRun{subRun1_label}",
        # f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution2_hds_subRun{subRun1_label}",
        # f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution3_wtd_subRun{subRun1_label}",
        # f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution3_hds_subRun{subRun1_label}",
        # f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution4_wtd_subRun{subRun1_label}",
        # f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution4_hds_subRun{subRun1_label}",
        f"{SLURMDIR_TR}/3_run_model/done_run_model_solution3_subRun{subRun1_label}"

rule setup_simulation:
    output:
        outFile=f"{SLURMDIR_TR}/1_prepare_model_partitioning/done_setup_complete"
    params:
        dir1 = MODELROOT_TR,
        dir2 = f"{SLURMDIR_TR}/1_prepare_model_partitioning",
        dir3 = f"{SLURMDIR_TR}/2_write_model_input",
        dir4 = f"{SLURMDIR_TR}/3_run_model",
        dir5 = f"{SLURMDIR_TR}/4_post-processing",

        model_input_dir = f"{RUN_GLOBGM_DIR}/model_input",
        modelroot_tr = MODELROOT_TR,
    shell:
        '''
        mkdir -p {params.dir1} {params.dir2} {params.dir3} {params.dir4} {params.dir5}
        cp -r {params.model_input_dir} {params.modelroot_tr}
        touch {output.outFile}
        '''
rule prepare_model_partitioning:
    input:
        rules.setup_simulation.output.outFile
    output:
        outFile=f"{SLURMDIR_TR}/1_prepare_model_partitioning/done_prepare_model_partitioning"
    shell:
        '''
        top={DATA_DIR}/globgm_input/clonemap_tiles/tile_163.txt
        til={DATA_DIR}/globgm_input/clonemap_tiles/idf/tile_
        exe={DATA_DIR}/_bin/datamap_070224

        cat={DATA_DIR}/globgm_input/inp_idf/hybas_lake_lev08_v1c_filt.idf
        d={DATA_DIR}/globgm_input/inp_idf/d_top_2.idf

        cd {MODELROOT_TR}

        mkdir -p ./mf6_map/
        cd ./mf6_map/

        ${{exe}} 1 './map_glob' ${{cat}} ${{d}} ${{top}} ${{til}}
        wait 
        touch {output.outFile}
        '''
rule write_model_forcing_setup:
    input:
        rules.prepare_model_partitioning.output.outFile
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_write_model_input_setup"
    shell:
        '''
        modelRoot={MODELROOT_TR}
        start_year={STARTYEAR}
        end_year={ENDYEAR}
        data_dir={DATA_DIR}
        simulation={SIMULATION}
        cmip6InputFolder=$data_dir/cmip6_input/$simulation/{PERIOD}
        saveFolder=$modelRoot/forcing_input
        pcrglobInputFolder=$data_dir/globgm_input/_pcrcalc_files
        zarrScripts=$(realpath ../model_tools_src/python/preprocess_zarr)

        mkdir -p $saveFolder

        process_gwRecharge() {{
            local tempdir=${{TMPDIR}}/gwRecharge
            local inFile=$(find "$cmip6InputFolder" -maxdepth 1 -type f -name "*gwRecharge*")
            local outFile=$tempdir/average_gwRecharge_m_per_day
            mkdir -p $tempdir
            cp $inFile $tempdir
            fileName=$(basename "$inFile")
            inFile=$tempdir/$fileName
            cdo -L -f nc4 -setrtoc,-inf,0,0 -setunit,m.day-1 -divc,365.25 -timmean -yearsum -selyear,{STARTYEAR}/{ENDYEAR} $inFile $outFile.temp.nc
            gdal_translate -of GTiff $outFile.temp.nc $outFile.temp.tif
            gdal_translate -of PCRaster ${{outFile}}.temp.tif ${{outFile}}.temp.map
            gdal_translate -of NETCDF ${{outFile}}.temp.map $tempdir/average_gwRecharge_m_per_day.map.nc
            cdo -L -invertlat $tempdir/average_gwRecharge_m_per_day.map.nc $tempdir/average_gwRecharge_m_per_dayTemp.nc
            ncwa -O -a time $tempdir/average_gwRecharge_m_per_dayTemp.nc $tempdir/average_gwRecharge_m_per_day.nc
            mv $tempdir/average_gwRecharge_m_per_day.nc $saveFolder
            rm -r $tempdir
        }}

        process_totalRunoff_to_Discharge() {{
            # Process totalRunoff -> Discharge
            local tempdir=${{TMPDIR}}/discharge
            local inFile=$(find "$cmip6InputFolder" -maxdepth 1 -type f -name "*totalRunoff*")
            local outFile=$tempdir/average_totalRunoff_m_per_day
            local gridFile=$pcrglobInputFolder/cdo_gridarea_30sec.map
            mkdir -p $tempdir

            cp -v $inFile $tempdir & cp -v $gridFile $tempdir
            wait
            fileName=$(basename "$inFile")
            inFile=$tempdir/$fileName

            cdo -L -f nc4 -setunit,m.day-1 -divc,365.25 -timmean -yearsum -selyear,{STARTYEAR}/{ENDYEAR} $inFile $outFile.temp.nc
            local info=$(gdalinfo $gridFile)
            local xres=$(echo "$info" | grep "Pixel Size" | awk -F'=' '{{print $2}}' | awk -F',' '{{print $1}}' | tr -d '()')
            local yres=$(echo "$info" | grep "Pixel Size" | awk -F'=' '{{print $2}}' | awk -F',' '{{print $2}}' | tr -d '()')
            local ulx=$(echo "$info" | grep "Upper Left"  | awk '{{print $3}}' | tr -d ',' | tr -d '()')
            local uly=$(echo "$info" | grep "Upper Left"  | awk '{{print $4}}' | tr -d ',' | tr -d '()')
            local lrx=$(echo "$info" | grep "Lower Right" | awk '{{print $4}}' | tr -d ',' | tr -d '()')
            local lry=$(echo "$info" | grep "Lower Right" | awk '{{print $5}}' | tr -d ',' | tr -d '()')
            gdalwarp -tr $xres $yres -r bilinear -overwrite -te $ulx $lry $lrx $uly -of GTiff $outFile.temp.nc ${{outFile}}_30sec.tif
            gdal_translate -of PCRaster ${{outFile}}_30sec.tif ${{outFile}}.temp.map

            #Calculate discharge
            cd $tempdir
            cp -v $pcrglobInputFolder/cdo_gridarea_30sec.map . & cp -v $pcrglobInputFolder/lddsound_30sec_version_202005XX.map . & cp -v $pcrglobInputFolder/waterBodyIds_lakes_and_reservoirs_30sec_global_2019_version_202005XX.map .
            wait

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
        }}

        process_gwRecharge & process_totalRunoff_to_Discharge
        wait
        satAreaFile=$(find "$cmip6InputFolder" -type f -name "*sat_area_fraction_average*")
        satAreaFile_monthly=$(find "$cmip6InputFolder" -type f -name "*sat_area_fraction_monthly*")
        correctionFile=$(find "$data_dir/cmip6_input/$simulation/{PERIOD}" -type d -name "*gwRecharge_correction_factor.zarr*")
        precipFile=$(find "$data_dir/cmip6_input/$simulation/{PERIOD}" -type f -name "*precipitation*")
        cp -v $satAreaFile $saveFolder & \
        cp -v $satAreaFile_monthly $saveFolder & \
        cp -r $correctionFile $saveFolder & \
        cp -v $precipFile $saveFolder/precipitation.nc
        wait
        python -u $zarrScripts/createZarr.py $pcrglobInputFolder $saveFolder $start_year $end_year
        touch {output.outFile}
        '''
rule write_model_forcing_sub1:
    input:
        rules.write_model_forcing_setup.output.outFile
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_writeModels_forcing_subset1",
    params:
        subSet=1,
    resources:
        slurm_partition='fat_genoa', 
        runtime=7140,
        constraint='scratch-node',
        mem_mb=1440000,
        cpus_per_task=1,
        tasks=192,
        nodes=1,
        slurm_extra=f"--exclusive --output={SLURMDIR_TR}/2_write_model_input/_writeModels_forcing_subset1.out",
        mpi='mpirun'
    shell:
        '''
        set +u; source ${{HOME}}/.bashrc && mamba activate globgm_pcraster ; set -u

        modelRoot={MODELROOT_TR}
        start_year={STARTYEAR}
        end_year={ENDYEAR}
        data_dir={DATA_DIR}
        simulation={SIMULATION}
        PCR_GLOB_dir=$(realpath ../model_tools_src/python/pcr-globwb)
        cmip6InputFolder=$data_dir/cmip6_input/$simulation/{PERIOD}
        saveFolder=$modelRoot/forcing_input

        diff=$(($end_year - $start_year))
        if [ {params.subSet} -eq 1 ]; then
            start_year=$start_year
            if [ $diff -lt 50 ]; then
                end_year=$end_year
            else
                end_year=$(($start_year + 49))
            fi
        fi

        if [ {params.subSet} -eq 2 ]; then
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
            tempDir=$TMPDIR/temp_${{yearEnd}}
            mkdir -p $tempDir
            python deterministic_runner_for_calculating_discharge_from_runoff.py $tempDir $yearStart $yearEnd $saveFolder $monthly_runoff_file $monthly_recharge_file $monthly_abstraction_file \
                                                                                $clone_file $ldd_file $cell_area_file $lake_and_reservoir_file &
        done
        wait
        touch {output.outFile}
        '''

use rule write_model_forcing_sub1 as write_model_forcing_sub2 with:
    input:
        rules.write_model_forcing_setup.output.outFile
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_writeModels_forcing_subset2",
    params:
        subSet=2,
    resources:
        slurm_partition='fat_genoa', 
        runtime=7140,
        constraint='scratch-node',
        mem_mb=1440000,
        cpus_per_task=1,
        tasks=192,
        nodes=1,
        slurm_extra=f"--exclusive --output={SLURMDIR_TR}/2_write_model_input/_writeModels_forcing_subset2.out",
        mpi='mpirun'
rule setup_output:
    input:
        rules.write_model_forcing_sub1.output.outFile,
        rules.write_model_forcing_sub2.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_setup_output"

    shell:
        '''
        set +u; source ${{HOME}}/.bashrc && mamba activate globgm_pcraster ; set -u

        to_zarrFolder=$(realpath ../model_tools_src/python/to_zarr)
        postDir={MODELROOT_TR}/mf6_post
        mkdir -p $postDir
        python -u $to_zarrFolder/createZarr_tr.py {DATA_DIR} 1 $postDir {STARTYEAR} {ENDYEAR} wtd & 
        python -u $to_zarrFolder/createZarr_tr.py {DATA_DIR} 1 $postDir {STARTYEAR} {ENDYEAR} hds
        wait
        python -u $to_zarrFolder/createZarr_tr.py {DATA_DIR} 2 $postDir {STARTYEAR} {ENDYEAR} wtd & 
        python -u $to_zarrFolder/createZarr_tr.py {DATA_DIR} 2 $postDir {STARTYEAR} {ENDYEAR} hds
        wait
        python -u $to_zarrFolder/createZarr_tr.py {DATA_DIR} 3 $postDir {STARTYEAR} {ENDYEAR} wtd & 
        python -u $to_zarrFolder/createZarr_tr.py {DATA_DIR} 3 $postDir {STARTYEAR} {ENDYEAR} hds
        wait
        python -u $to_zarrFolder/createZarr_tr.py {DATA_DIR} 4 $postDir {STARTYEAR} {ENDYEAR} wtd & 
        python -u $to_zarrFolder/createZarr_tr.py {DATA_DIR} 4 $postDir {STARTYEAR} {ENDYEAR} hds
        wait
        touch {output.outFile}
        '''
rule _setup_subRun1:
    input:
        rules.setup_output.output.outFile,
    params:
        start_year=subRun1_start,
        end_year=subRun1_end,
        label=subRun1_label,
        iniStatesFolder=f"{DATA_DIR}/initial_states/ss/"
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_setup_{subRun1_label}",
    shell:
        '''
        modelRoot={MODELROOT_TR}
        start_year={params.start_year}
        end_year={params.end_year}
        nSpin={nSpin}
        dataDir={DATA_DIR}
        label={params.label}
        iniStatesFolder={params.iniStatesFolder}
        nMonths=$(((( $end_year - $start_year ) + 1) * 12))

        inpdir=$modelRoot/model_input/2_partition_and_write_model_input/transient
        exe=$dataDir/_bin/mf6ggm_181121
        inpmod=mf6_mod_tr.inp
        inpexe=mf6ggm_tr.inp
        moddir=$modelRoot/mf6_mod/mf6_mod_${{label}}
        parentDir=$(dirname $(realpath $modelRoot))
        ssFolder=${{iniStatesFolder}}
        yodaInput=$dataDir/globgm_input
        globgmDir=$modelRoot
        mkdir -p $moddir
        cp ${{inpdir}}/${{inpmod}} ${{moddir}}/${{inpmod}}
        cp ${{inpdir}}/${{inpexe}} ${{moddir}}/${{inpexe}}
        sed -i "s|{{yoda_input}}|${{yodaInput}}|g" ${{moddir}}/${{inpmod}}
        sed -i "s|{{globgm_dir}}|${{globgmDir}}|g" ${{moddir}}/${{inpmod}}
        sed -i "s|{{ssFolder}}|${{ssFolder}}|g" ${{moddir}}/${{inpmod}}
        sed -i "s|{{NUMBER_OF_MONTHS}}|${{nMonths}}|g" ${{moddir}}/${{inpmod}}
        sed -i "s|{{NUMBER_SPIN_YEARS}}|${{nSpin}}|g" ${{moddir}}/${{inpmod}}
        sed -i "s|{{START_DATE}}|${{start_year}}|g" ${{moddir}}/${{inpmod}}
        wait

        cd ${{moddir}}
        ${{exe}} ${{inpexe}} 0

        wait
        touch {output.outFile}
        '''
use rule _setup_subRun1 as _setup_subRun2 with:
    input:
        rules.setup_output.output.outFile,
    params:
        start_year=subRun2_start,
        end_year=subRun2_end,
        label=subRun2_label,
        iniStatesFolder=f"{DATA_DIR}/initial_states/ss/"
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_setup_{subRun2_label}",
use rule _setup_subRun1 as _setup_subRun3 with:
    input:
        rules.setup_output.output.outFile,
    params:
        start_year=subRun3_start,
        end_year=subRun3_end,
        label=subRun3_label,
        iniStatesFolder=f"{DATA_DIR}/initial_states/ss/"
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_setup_{subRun3_label}",
use rule _setup_subRun1 as _setup_subRun4 with:
    input:
        rules.setup_output.output.outFile,
    params:
        start_year=subRun4_start,
        end_year=subRun4_end,
        label=subRun4_label,
        iniStatesFolder=f"{DATA_DIR}/initial_states/ss/"
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_setup_{subRun4_label}",
use rule _setup_subRun1 as _setup_subRun5 with:
    input:
        rules.setup_output.output.outFile,
    params:
        start_year=subRun5_start,
        end_year=subRun5_end,
        label=subRun5_label,
        iniStatesFolder=f"{DATA_DIR}/initial_states/ss/"
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_setup_{subRun5_label}",
use rule _setup_subRun1 as _setup_subRun6 with:
    input:
        rules.setup_output.output.outFile,
    params:
        start_year=subRun6_start,
        end_year=subRun6_end,
        label=subRun6_label,
        iniStatesFolder=f"{DATA_DIR}/initial_states/ss/"
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_setup_{subRun6_label}",
###############################
#  Setup and Run SubRun 1     #
###############################
rule write_models_solution3_subRun1:
    input:
        rules._setup_subRun1.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_write_models_solution3_subRun{subRun1_label}",
    params:
        iniFileName="transient_config_with_pump.ini",
        solution=3,
        label=subRun1_label,
    resources:
        slurm_partition='fat_genoa', 
        runtime=1200,
        mem_mb=1440000,
        cpus_per_task=1,
        constraint='scratch-node',
        tasks=192,
        nodes=1,
        slurm_extra=f"--exclusive --output={SLURMDIR_TR}/2_write_model_input/_writeModels/_write_models_solution3_subRun{subRun1_label}.out",
        mpi='mpirun'
    shell:
        '''
        df -BG $TMPDIR

        set +u; source ${{HOME}}/.bashrc && mamba activate globgm_pcraster ; set -u

        modelRoot={MODELROOT_TR}
        id={params.label}
        solution={params.solution}
        dataDir={DATA_DIR}

        exe=$dataDir/_bin/mf6ggm_181121
        model_input=$modelRoot/model_input/2_partition_and_write_model_input/transient
        moddir=$modelRoot/mf6_mod/mf6_mod_${{id}}
        inpmod=mf6_mod_tr.inp
        inpexe=mf6ggm_tr.inp

        _tempDir=$TMPDIR/_temp
        mkdir -p $_tempDir

        module load 2023
        module load mpifileutils/0.11.1-gompi-2023a
        {resources.mpi} -np 160 dcp --progress 5 $dataDir/globgm_input $_tempDir
        wait
        {resources.mpi} -np 160 dcp --progress 5 $modelRoot/forcing_input $_tempDir
        wait
        ls -lah $_tempDir

        IN_DIR=$_tempDir/globgm_input
        globgmDir=$TMPDIR
        OUT_DIR=$TMPDIR/input_map/transient
        forcingDir=$_tempDir/forcing_input
        START_DATE=$(grep 'STARTDATE' ${{moddir}}/${{inpmod}} | awk '{{print $2}}')
        nMonths=$(grep 'NPER' ${{moddir}}/${{inpmod}} | awk '{{print $2}}')
        PCR_GLOB_dir=$(realpath ../model_tools_src/python/pcr-globwb)
        cd $PCR_GLOB_dir
        cp $model_input/{params.iniFileName} $TMPDIR/{params.iniFileName}
        wait 
        for ((i=1; i<=163; i+=1)); do
            num=$(printf "%03d" $((10#$i)))
            python deterministic_runner_for_monthly_offline_globgm.py $TMPDIR/{params.iniFileName} debug transient tile_${{num}}-163 $IN_DIR $OUT_DIR $forcingDir $START_DATE $nMonths &
        done
        wait
        cp ${{moddir}}/${{inpmod}} ${{moddir}}/${{inpmod}}_${{solution}}_${{id}}
        cp ${{moddir}}/${{inpexe}} ${{moddir}}/${{inpexe}}_${{solution}}_${{id}}

        inputStr=mf6_mod_tr.inp_${{solution}}_${{id}}
        sed -i "s|mf6_mod_tr.inp|${{inputStr}}|g" ${{moddir}}/${{inpexe}}_${{solution}}_${{id}}
        sed -i "s|INPUT_DIST_DIR ${{modelRoot}}|INPUT_DIST_DIR ${{globgmDir}}|g" ${{moddir}}/${{inpmod}}_${{solution}}_${{id}}
        wait 

        cd ${{moddir}}

        if [ $solution -eq 1 ]; then
            startMod=1
            endMod=224
        fi

        if [ $solution -eq 2 ]; then
            startMod=225
            endMod=320
        fi

        if [ $solution -eq 3 ]; then
            startMod=321
            endMod=352
        fi

        if [ $solution -eq 4 ]; then
            startMod=353
            endMod=384
        fi
        for ((i=$startMod; i<=$endMod; i+=2)); do
            ii=$((i + 1))
            if [ $ii -gt 384 ]; then
                ii=384
            fi
            ${{exe}} ${{inpexe}}_${{solution}}_${{id}} $i $ii &
        done
        wait

        if [ $solution -eq 3 ]; then
            for ((i=1; i<=163; i+=1));do
                tile=$(printf "%03d" $i)
                mkdir -p $modelRoot/input_map/transient/tile_${{tile}}-163/transient/maps && cp "${{OUT_DIR}}/tile_${{tile}}-163/transient/maps/top_uppermost_layer.map" "$modelRoot/input_map/transient/tile_${{tile}}-163/transient/maps" &
            done
        fi
        wait

        rm ${{moddir}}/${{inpexe}}_${{solution}}_${{id}}
        rm ${{moddir}}/${{inpmod}}_${{solution}}_${{id}}
        wait
        touch {output.outFile}
        df -BG $TMPDIR
        '''

use rule write_models_solution3_subRun1 as write_models_solution4_subRun1 with:
    input:
        rules._setup_subRun1.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_write_models_solution4_subRun{subRun1_label}",
    params:
        iniFileName="transient_config_with_pump.ini",
        solution=4,
        label=subRun1_label,
    resources:
        slurm_partition='fat_genoa', 
        runtime=1200,
        mem_mb=1440000,
        cpus_per_task=1,
        constraint='scratch-node',
        tasks=192,
        nodes=1,
        slurm_extra=f"--exclusive --output={SLURMDIR_TR}/2_write_model_input/_writeModels/_write_models_solution4_subRun{subRun1_label}.out",
        mpi='mpirun'
use rule write_models_solution3_subRun1 as write_models_solution2_subRun1 with:
    input:
        rules._setup_subRun1.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_write_models_solution2_subRun{subRun1_label}",
    params:
        iniFileName="transient_config_with_pump.ini",
        solution=2,
        label=subRun1_label,
    resources:
        slurm_partition='fat_genoa', 
        runtime=1200,
        mem_mb=1440000,
        cpus_per_task=1,
        constraint='scratch-node',
        tasks=192,
        nodes=1,
        slurm_extra=f"--exclusive --output={SLURMDIR_TR}/2_write_model_input/_writeModels/_write_models_solution2_subRun{subRun1_label}.out",
        mpi='mpirun'

use rule write_models_solution3_subRun1 as write_models_solution1_subRun1 with:
    input:
        rules._setup_subRun1.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_write_models_solution1_subRun{subRun1_label}",
    params:
        iniFileName="transient_config_with_pump.ini",
        solution=1,
        label=subRun1_label,
    resources:
        slurm_partition='fat_genoa', 
        runtime=1200,
        mem_mb=1440000,
        cpus_per_task=1,
        constraint='scratch-node',
        tasks=192,
        nodes=1,
        slurm_extra=f"--exclusive --output={SLURMDIR_TR}/2_write_model_input/_writeModels/_write_models_solution1_subRun{subRun1_label}.out",
        mpi='mpirun'

rule modify_ini_conditions_subRun1:
    input:
        rules.write_models_solution1_subRun1.output.outFile,
        rules.write_models_solution2_subRun1.output.outFile,
        rules.write_models_solution3_subRun1.output.outFile,
        rules.write_models_solution4_subRun1.output.outFile,

    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_modify_ini_conditions_subRun{subRun1_label}"

    params:
        run_script=f"{RUN_GLOBGM_DIR}/model_tools_src/python/initial_states/initial_statesModifyPath.py",
        iniStatesFolder=f"{DATA_DIR}/initial_states/tr/",
        label=f"{subRun1_label}",
    shell:
        '''
        mkdir -p {MODELROOT_TR}/mf6_mod/mf6_mod_{params.label}/glob_tr/models/run_output_bin/_ini_hds && \
        cp -r {params.iniStatesFolder}* {MODELROOT_TR}/mf6_mod/mf6_mod_{params.label}/glob_tr/models/run_output_bin/_ini_hds && \
        python {params.run_script} {MODELROOT_TR}/mf6_mod/mf6_mod_{params.label} && \
        touch {output.outFile}
        '''

rule run_model_solution3_subRun1:
    input:
        rules.modify_ini_conditions_subRun1.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/done_run_model_solution3_subRun{subRun1_label}",
    params:
        label=subRun1_label,
        solution=3,  
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=300,
        mem_mb=336000,
        tasks=32,
        cpus_per_task=1,
        mpi='srun',
        slurm_extra=f"--exclusive --ntasks-per-node=32 --gres=cpu:1 --output={SLURMDIR_TR}/3_run_model/_run_model_solution3_subRun{subRun1_label}.out",
    shell:
        '''
        module load 2023
        module load OpenMPI/4.1.5-GCC-12.3.0
        modelRoot={MODELROOT_TR}
        solution={params.solution}
        label={params.label}
        dataDir={DATA_DIR}

        exe=$dataDir/_bin/mf6_rel_openmpi-4.1.4-gcc-11.3.0
        nam2=s0${{solution}}.par.mfsim.ic_spu.nam

        dir_run=$modelRoot/mf6_mod/mf6_mod_${{label}}/glob_tr/solutions/run_output/
        cd ${{dir_run}}

        {resources.mpi} ${{exe}} -s ../run_input/${{nam2}}

        wait
        touch {output.outFile}
        '''

use rule run_model_solution3_subRun1 as run_model_solution4_subRun1 with:
    input:
        rules.modify_ini_conditions_subRun1.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/done_run_model_solution4_subRun{subRun1_label}",
    params:
        label=subRun1_label,
        solution=4,  
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=300,
        mem_mb=336000,
        tasks=32,
        cpus_per_task=1,
        mpi='srun',
        slurm_extra=f"--exclusive --ntasks-per-node=32 --gres=cpu:1 --output={SLURMDIR_TR}/3_run_model/_run_model_solution4_subRun{subRun1_label}.out",
use rule run_model_solution3_subRun1 as run_model_solution2_subRun1 with:
    input:
        rules.modify_ini_conditions_subRun1.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/done_run_model_solution2_subRun{subRun1_label}",
    params:
        label=subRun1_label,
        solution=2,  
    resources:
        slurm_partition='genoa', 
        nodes=3,
        runtime=300,
        mem_mb=336000,
        tasks=96,
        cpus_per_task=1,
        mpi='srun',
        slurm_extra=f"--exclusive --ntasks-per-node=32 --gres=cpu:1 --output={SLURMDIR_TR}/3_run_model/_run_model_solution2_subRun{subRun1_label}.out"
use rule run_model_solution3_subRun1 as run_model_solution1_subRun1 with:
    input:
        rules.modify_ini_conditions_subRun1.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/done_run_model_solution1_subRun{subRun1_label}",
    params:
        label=subRun1_label,
        solution=1,  
    resources:
        slurm_partition='genoa', 
        nodes=7,
        runtime=300,
        mem_mb=336000,
        tasks=224,
        cpus_per_task=1,
        mpi='srun',
        slurm_extra=f"--exclusive --ntasks-per-node=32 --gres=cpu:1 --output={SLURMDIR_TR}/3_run_model/_run_model_solution1_subRun{subRun1_label}.out"

rule post_model_solution3_wtd_subRun1:
    input:
        rules.run_model_solution3_subRun1.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution3_wtd_subRun{subRun1_label}",
    params:
        solution=3,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun1_label}/glob_tr",
        var="wtd",
        startYear=subRun1_start,
        endYear=subRun1_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=28000,
        tasks=16,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution3_wtd_subRun{subRun1_label}.out",
    shell:
        '''
        df -BG $TMPDIR
        modelRoot={MODELROOT_TR}
        var={params.var}
        solution={params.solution}
        startDate={params.startYear}
        endDate={params.endYear}
        modDir={params.modDir}
        dataDir={DATA_DIR}

        _merge_zarr=$(realpath ../model_tools_src/python/to_zarr/mergeZarr_tr.py)
        inpdir=$modelRoot/model_input/4_post-processing/transient
        inp_tr=mf6ggm_post_tr_$var.inp
        exe=$dataDir/_bin/mf6ggmpost_260624
        yodaInput=$dataDir/globgm_input
        dir=$modelRoot/mf6_post
        input_file=s0${{solution}}_${{inp_tr}}

        modFlowTemp=$TMPDIR/output
        mkdir -p $modFlowTemp
        cd $modFlowTemp
        mkdir -p ./mod_files_s0${{solution}}_${{endDate}} ./out
        cd ./mod_files_s0${{solution}}_${{endDate}}
        # #Convert output to .flt
        sub_input=${{input_file}}_${{endDate}}
        cp ${{inpdir}}/${{inp_tr}} ./$sub_input
        sed -i "s|{{yoda_input}}|${{yodaInput}}|g" $sub_input
        sed -i "s|{{globgm_dir}}|${{modelRoot}}|g" $sub_input
        sed -i "s|{{mod_dir}}|${{modDir}}|g" $sub_input
        sed -i "s|{{solution}}|${{solution}}|g" $sub_input
        sed -i "s|{{START_DATE}}|${{startDate}}|g" $sub_input
        sed -i "s|{{END_DATE}}|${{endDate}}|g" $sub_input
        sed -i "s|{{MOD_START_DATE}}|${{startDate}}|g" $sub_input
        ${{exe}} $sub_input & python -u $_merge_zarr $dir $modFlowTemp/out $solution $startDate $endDate $var
        wait
        df -BG $TMPDIR
        touch {output.outFile}
        '''
use rule post_model_solution3_wtd_subRun1 as post_model_solution3_hds_subRun1 with:
    input:
        rules.run_model_solution3_subRun1.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution3_hds_subRun{subRun1_label}",
    params:
        solution=3,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun1_label}/glob_tr",
        var="hds",
        startYear=subRun1_start,
        endYear=subRun1_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=28000,
        tasks=16,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution3_hds_subRun{subRun1_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution4_wtd_subRun1 with:
    input:
        rules.run_model_solution4_subRun1.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution4_wtd_subRun{subRun1_label}",
    params:
        solution=4,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun1_label}/glob_tr",
        var="wtd",
        startYear=subRun1_start,
        endYear=subRun1_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=56000,
        tasks=32,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution4_wtd_subRun{subRun1_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution4_hds_subRun1 with:
    input:
        rules.run_model_solution4_subRun1.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution4_hds_subRun{subRun1_label}",
    params:
        solution=4,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun1_label}/glob_tr",
        var="hds",
        startYear=subRun1_start,
        endYear=subRun1_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=56000,
        tasks=32,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution4_hds_subRun{subRun1_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution2_wtd_subRun1 with:
    input:
        rules.run_model_solution2_subRun1.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution2_wtd_subRun{subRun1_label}",
    params:
        solution=2,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun1_label}/glob_tr",
        var="wtd",
        startYear=subRun1_start,
        endYear=subRun1_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=28000,
        tasks=16,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution2_wtd_subRun{subRun1_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution2_hds_subRun1 with:
    input:
        rules.run_model_solution2_subRun1.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution2_hds_subRun{subRun1_label}",
    params:
        solution=2,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun1_label}/glob_tr",
        var="hds",
        startYear=subRun1_start,
        endYear=subRun1_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=28000,
        tasks=16,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution2_hds_subRun{subRun1_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution1_wtd_subRun1 with:
    input:
        rules.run_model_solution1_subRun1.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution1_wtd_subRun{subRun1_label}",
    params:
        solution=1,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun1_label}/glob_tr",
        var="wtd",
        startYear=subRun1_start,
        endYear=subRun1_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=28000,
        tasks=16,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution1_wtd_subRun{subRun1_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution1_hds_subRun1 with:
    input:
        rules.run_model_solution1_subRun1.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution1_hds_subRun{subRun1_label}",
    params:
        solution=1,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun1_label}/glob_tr",
        var="hds",
        startYear=subRun1_start,
        endYear=subRun1_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=28000,
        tasks=16,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution1_hds_subRun{subRun1_label}.out",



# ###############################
# #  Setup and Run SubRun 2     #
# ###############################
use rule write_models_solution3_subRun1 as write_models_solution3_subRun2 with:
    input:
        rules._setup_subRun2.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_write_models_solution3_subRun{subRun2_label}",
    params:
        iniFileName="transient_config_with_pump.ini",
        solution=3,
        label=subRun2_label,
    resources:
        slurm_partition='fat_genoa', 
        runtime=1200,
        mem_mb=1440000,
        cpus_per_task=1,
        constraint='scratch-node',
        tasks=192,
        nodes=1,
        slurm_extra=f"--exclusive --output={SLURMDIR_TR}/2_write_model_input/_writeModels/_write_models_solution3_subRun{subRun2_label}.out",
        mpi='mpirun'

use rule write_models_solution3_subRun1 as write_models_solution4_subRun2 with:
    input:
        rules._setup_subRun2.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_write_models_solution4_subRun{subRun2_label}",
    params:
        iniFileName="transient_config_with_pump.ini",
        solution=4,
        label=subRun2_label,
    resources:
        slurm_partition='fat_genoa', 
        runtime=1200,
        mem_mb=1440000,
        cpus_per_task=1,
        constraint='scratch-node',
        tasks=192,
        nodes=1,
        slurm_extra=f"--exclusive --output={SLURMDIR_TR}/2_write_model_input/_writeModels/_write_models_solution4_subRun{subRun2_label}.out",
        mpi='mpirun'
use rule write_models_solution3_subRun1 as write_models_solution2_subRun2 with:
    input:
        rules._setup_subRun2.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_write_models_solution2_subRun{subRun2_label}",
    params:
        iniFileName="transient_config_with_pump.ini",
        solution=2,
        label=subRun2_label,
    resources:
        slurm_partition='fat_genoa', 
        runtime=1200,
        mem_mb=1440000,
        cpus_per_task=1,
        constraint='scratch-node',
        tasks=192,
        nodes=1,
        slurm_extra=f"--exclusive --output={SLURMDIR_TR}/2_write_model_input/_writeModels/_write_models_solution2_subRun{subRun2_label}.out",
        mpi='mpirun'
use rule write_models_solution3_subRun1 as write_models_solution1_subRun2 with:
    input:
        rules._setup_subRun2.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_write_models_solution1_subRun{subRun2_label}",
    params:
        iniFileName="transient_config_with_pump.ini",
        solution=1,
        label=subRun2_label,
    resources:
        slurm_partition='fat_genoa', 
        runtime=1200,
        mem_mb=1440000,
        cpus_per_task=1,
        constraint='scratch-node',
        tasks=192,
        nodes=1,
        slurm_extra=f"--exclusive --output={SLURMDIR_TR}/2_write_model_input/_writeModels/_write_models_solution1_subRun{subRun2_label}.out",
        mpi='mpirun'
rule modify_ini_conditions_subRun2:
    input:
        rules.write_models_solution1_subRun2.output.outFile,
        rules.write_models_solution2_subRun2.output.outFile,
        rules.write_models_solution3_subRun2.output.outFile,
        rules.write_models_solution4_subRun2.output.outFile,
        
        rules.run_model_solution1_subRun1.output.outFile,
        rules.run_model_solution2_subRun1.output.outFile,
        rules.run_model_solution3_subRun1.output.outFile,
        rules.run_model_solution4_subRun1.output.outFile,

    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_modify_ini_conditions_subRun{subRun2_label}",
    params:
        createIniConditionsScript=f"{RUN_GLOBGM_DIR}/model_tools_src/python/initial_states/initial_states.py",
        modifyPathScript=f"{RUN_GLOBGM_DIR}/model_tools_src/python/initial_states/initial_statesModifyPath.py",
        previousRunModDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun1_label}/glob_tr/models/run_output_bin/",
        label=f"{subRun2_label}",
    shell:
        '''
        python {params.createIniConditionsScript} {params.previousRunModDir} {MODELROOT_TR}/mf6_mod/mf6_mod_{params.label}/glob_tr/models/run_output_bin/
        wait
        python {params.modifyPathScript} {MODELROOT_TR}/mf6_mod/mf6_mod_{params.label}
        wait
        touch {output.outFile}
        '''
use rule run_model_solution3_subRun1 as run_model_solution3_subRun2 with:
    input:
        rules.modify_ini_conditions_subRun2.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/done_run_model_solution3_subRun{subRun2_label}",
    params:
        label=subRun2_label,
        solution=3,  
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=300,
        mem_mb=336000,
        tasks=32,
        cpus_per_task=1,
        mpi='srun',
        slurm_extra=f"--exclusive --ntasks-per-node=32 --gres=cpu:1 --output={SLURMDIR_TR}/3_run_model/_run_model_solution3_subRun{subRun2_label}.out",
use rule run_model_solution3_subRun1 as run_model_solution4_subRun2 with:
    input:
        rules.modify_ini_conditions_subRun2.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/done_run_model_solution4_subRun{subRun2_label}",
    params:
        label=subRun2_label,
        solution=4,  
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=300,
        mem_mb=336000,
        tasks=32,
        cpus_per_task=1,
        mpi='srun',
        slurm_extra=f"--exclusive --ntasks-per-node=32 --gres=cpu:1 --output={SLURMDIR_TR}/3_run_model/_run_model_solution4_subRun{subRun2_label}.out",
use rule run_model_solution3_subRun1 as run_model_solution2_subRun2 with:
    input:
        rules.modify_ini_conditions_subRun2.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/done_run_model_solution2_subRun{subRun2_label}",
    params:
        label=subRun2_label,
        solution=2,  
    resources:
        slurm_partition='genoa', 
        nodes=3,
        runtime=300,
        mem_mb=336000,
        tasks=96,
        cpus_per_task=1,
        mpi='srun',
        slurm_extra=f"--exclusive --ntasks-per-node=32 --gres=cpu:1 --output={SLURMDIR_TR}/3_run_model/_run_model_solution2_subRun{subRun2_label}.out",
use rule run_model_solution3_subRun1 as run_model_solution1_subRun2 with:
    input:
        rules.modify_ini_conditions_subRun2.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/done_run_model_solution1_subRun{subRun2_label}",
    params:
        label=subRun2_label,
        solution=1,  
    resources:
        slurm_partition='genoa', 
        nodes=7,
        runtime=300,
        mem_mb=336000,
        tasks=224,
        cpus_per_task=1,
        mpi='srun',
        slurm_extra=f"--exclusive --ntasks-per-node=32 --gres=cpu:1 --output={SLURMDIR_TR}/3_run_model/_run_model_solution1_subRun{subRun2_label}.out",

use rule post_model_solution3_wtd_subRun1 as post_model_solution3_wtd_subRun2 with:
    input:
        rules.run_model_solution3_subRun2.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution3_wtd_subRun{subRun2_label}",
    params:
        solution=3,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun2_label}/glob_tr",
        var="wtd",
        startYear=subRun2_start,
        endYear=subRun2_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=28000,
        tasks=16,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution3_wtd_subRun{subRun2_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution3_hds_subRun2 with:
    input:
        rules.run_model_solution3_subRun2.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution3_hds_subRun{subRun2_label}",
    params:
        solution=3,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun2_label}/glob_tr",
        var="hds",
        startYear=subRun2_start,
        endYear=subRun2_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=28000,
        tasks=16,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution3_hds_subRun{subRun2_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution4_wtd_subRun2 with:
    input:
        rules.run_model_solution4_subRun2.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution4_wtd_subRun{subRun2_label}",
    params:
        solution=4,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun2_label}/glob_tr",
        var="wtd",
        startYear=subRun2_start,
        endYear=subRun2_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=56000,
        tasks=32,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution4_wtd_subRun{subRun2_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution4_hds_subRun2 with:
    input:
        rules.run_model_solution4_subRun2.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution4_hds_subRun{subRun2_label}",
    params:
        solution=4,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun2_label}/glob_tr",
        var="hds",
        startYear=subRun2_start,
        endYear=subRun2_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=56000,
        tasks=32,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution4_hds_subRun{subRun2_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution2_wtd_subRun2 with:
    input:
        rules.run_model_solution2_subRun2.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution2_wtd_subRun{subRun2_label}",
    params:
        solution=2,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun2_label}/glob_tr",
        var="wtd",
        startYear=subRun2_start,
        endYear=subRun2_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=28000,
        tasks=16,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution2_wtd_subRun{subRun2_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution2_hds_subRun2 with:
    input:
        rules.run_model_solution2_subRun2.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution2_hds_subRun{subRun2_label}",
    params:
        solution=2,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun2_label}/glob_tr",
        var="hds",
        startYear=subRun2_start,
        endYear=subRun2_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=28000,
        tasks=16,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution2_hds_subRun{subRun2_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution1_wtd_subRun2 with:
    input:
        rules.run_model_solution1_subRun2.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution1_wtd_subRun{subRun2_label}",
    params:
        solution=1,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun2_label}/glob_tr",
        var="wtd",
        startYear=subRun2_start,
        endYear=subRun2_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=28000,
        tasks=16,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution1_wtd_subRun{subRun2_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution1_hds_subRun2 with:
    input:
        rules.run_model_solution1_subRun2.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution1_hds_subRun{subRun2_label}",
    params:
        solution=1,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun2_label}/glob_tr",
        var="hds",
        startYear=subRun2_start,
        endYear=subRun2_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=28000,
        tasks=16,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution1_hds_subRun{subRun2_label}.out",


###############################
#  Setup and Run SubRun 3     #
###############################
use rule write_models_solution3_subRun1 as write_models_solution3_subRun3 with:
    input:
        rules._setup_subRun3.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_write_models_solution3_subRun{subRun3_label}",
    params:
        iniFileName="transient_config_with_pump.ini",
        solution=3,
        label=subRun3_label,
    resources:
        slurm_partition='fat_genoa', 
        runtime=1200,
        mem_mb=1440000,
        cpus_per_task=1,
        constraint='scratch-node',
        tasks=192,
        nodes=1,
        slurm_extra=f"--exclusive --output={SLURMDIR_TR}/2_write_model_input/_writeModels/_write_models_solution3_subRun{subRun3_label}.out",
        mpi='mpirun'
use rule write_models_solution3_subRun1 as write_models_solution4_subRun3 with:
    input:
        rules._setup_subRun3.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_write_models_solution4_subRun{subRun3_label}",
    params:
        iniFileName="transient_config_with_pump.ini",
        solution=4,
        label=subRun3_label,
    resources:
        slurm_partition='fat_genoa', 
        runtime=1200,
        mem_mb=1440000,
        cpus_per_task=1,
        constraint='scratch-node',
        tasks=192,
        nodes=1,
        slurm_extra=f"--exclusive --output={SLURMDIR_TR}/2_write_model_input/_writeModels/_write_models_solution4_subRun{subRun3_label}.out",
        mpi='mpirun'
use rule write_models_solution3_subRun1 as write_models_solution2_subRun3 with:
    input:
        rules._setup_subRun3.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_write_models_solution2_subRun{subRun3_label}",
    params:
        iniFileName="transient_config_with_pump.ini",
        solution=2,
        label=subRun3_label,
    resources:
        slurm_partition='fat_genoa', 
        runtime=1200,
        mem_mb=1440000,
        cpus_per_task=1,
        constraint='scratch-node',
        tasks=192,
        nodes=1,
        slurm_extra=f"--exclusive --output={SLURMDIR_TR}/2_write_model_input/_writeModels/_write_models_solution2_subRun{subRun3_label}.out",
        mpi='mpirun'
use rule write_models_solution3_subRun1 as write_models_solution1_subRun3 with:
    input:
        rules._setup_subRun3.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_write_models_solution1_subRun{subRun3_label}",
    params:
        iniFileName="transient_config_with_pump.ini",
        solution=1,
        label=subRun3_label,
    resources:
        slurm_partition='fat_genoa', 
        runtime=1200,
        mem_mb=1440000,
        cpus_per_task=1,
        constraint='scratch-node',
        tasks=192,
        nodes=1,
        slurm_extra=f"--exclusive --output={SLURMDIR_TR}/2_write_model_input/_writeModels/_write_models_solution1_subRun{subRun3_label}.out",
        mpi='mpirun'
use rule modify_ini_conditions_subRun2 as modify_ini_conditions_subRun3 with:
    input:
        rules.write_models_solution1_subRun3.output.outFile,
        rules.write_models_solution2_subRun3.output.outFile,
        rules.write_models_solution3_subRun3.output.outFile,
        rules.write_models_solution4_subRun3.output.outFile,
        
        rules.run_model_solution1_subRun2.output.outFile,
        rules.run_model_solution2_subRun2.output.outFile,
        rules.run_model_solution3_subRun2.output.outFile,
        rules.run_model_solution4_subRun2.output.outFile,

    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_modify_ini_conditions_subRun{subRun3_label}",
    params:
        createIniConditionsScript=f"{RUN_GLOBGM_DIR}/model_tools_src/python/initial_states/initial_states.py",
        modifyPathScript=f"{RUN_GLOBGM_DIR}/model_tools_src/python/initial_states/initial_statesModifyPath.py",
        previousRunModDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun2_label}/glob_tr/models/run_output_bin/",
        label=f"{subRun3_label}",
use rule run_model_solution3_subRun1 as run_model_solution3_subRun3 with:
    input:
        rules.modify_ini_conditions_subRun3.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/done_run_model_solution3_subRun{subRun3_label}",
    params:
        label=subRun3_label,
        solution=3,  
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=300,
        mem_mb=336000,
        tasks=32,
        cpus_per_task=1,
        mpi='srun',
        slurm_extra=f"--exclusive --ntasks-per-node=32 --gres=cpu:1 --output={SLURMDIR_TR}/3_run_model/_run_model_solution3_subRun{subRun3_label}.out",
use rule run_model_solution3_subRun1 as run_model_solution4_subRun3 with:
    input:
        rules.modify_ini_conditions_subRun3.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/done_run_model_solution4_subRun{subRun3_label}",
    params:
        label=subRun3_label,
        solution=4,  
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=300,
        mem_mb=336000,
        tasks=32,
        cpus_per_task=1,
        mpi='srun',
        slurm_extra=f"--exclusive --ntasks-per-node=32 --gres=cpu:1 --output={SLURMDIR_TR}/3_run_model/_run_model_solution4_subRun{subRun3_label}.out",
use rule run_model_solution3_subRun1 as run_model_solution2_subRun3 with:
    input:
        rules.modify_ini_conditions_subRun3.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/done_run_model_solution2_subRun{subRun3_label}",
    params:
        label=subRun3_label,
        solution=2,  
    resources:
        slurm_partition='genoa', 
        nodes=3,
        runtime=300,
        mem_mb=336000,
        tasks=96,
        cpus_per_task=1,
        mpi='srun',
        slurm_extra=f"--exclusive --ntasks-per-node=32 --gres=cpu:1 --output={SLURMDIR_TR}/3_run_model/_run_model_solution2_subRun{subRun3_label}.out",
use rule run_model_solution3_subRun1 as run_model_solution1_subRun3 with:
    input:
        rules.modify_ini_conditions_subRun3.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/done_run_model_solution1_subRun{subRun3_label}",
    params:
        label=subRun3_label,
        solution=1,  
    resources:
        slurm_partition='genoa', 
        nodes=7,
        runtime=300,
        mem_mb=336000,
        tasks=224,
        cpus_per_task=1,
        mpi='srun',
        slurm_extra=f"--exclusive --ntasks-per-node=32 --gres=cpu:1 --output={SLURMDIR_TR}/3_run_model/_run_model_solution1_subRun{subRun3_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution3_wtd_subRun3 with:
    input:
        rules.run_model_solution3_subRun3.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution3_wtd_subRun{subRun3_label}",
    params:
        solution=3,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun3_label}/glob_tr",
        var="wtd",
        startYear=subRun3_start,
        endYear=subRun3_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=28000,
        tasks=16,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution3_wtd_subRun{subRun3_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution3_hds_subRun3 with:
    input:
        rules.run_model_solution3_subRun3.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution3_hds_subRun{subRun3_label}",
    params:
        solution=3,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun3_label}/glob_tr",
        var="hds",
        startYear=subRun3_start,
        endYear=subRun3_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=28000,
        tasks=16,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution3_hds_subRun{subRun3_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution4_wtd_subRun3 with:
    input:
        rules.run_model_solution4_subRun3.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution4_wtd_subRun{subRun3_label}",
    params:
        solution=4,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun3_label}/glob_tr",
        var="wtd",
        startYear=subRun3_start,
        endYear=subRun3_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=56000,
        tasks=32,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution4_wtd_subRun{subRun3_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution4_hds_subRun3 with:
    input:
        rules.run_model_solution4_subRun3.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution4_hds_subRun{subRun3_label}",
    params:
        solution=4,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun3_label}/glob_tr",
        var="hds",
        startYear=subRun3_start,
        endYear=subRun3_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=56000,
        tasks=32,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution4_hds_subRun{subRun3_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution2_wtd_subRun3 with:
    input:
        rules.run_model_solution2_subRun3.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution2_wtd_subRun{subRun3_label}",
    params:
        solution=2,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun3_label}/glob_tr",
        var="wtd",
        startYear=subRun3_start,
        endYear=subRun3_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=28000,
        tasks=16,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution2_wtd_subRun{subRun3_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution2_hds_subRun3 with:
    input:
        rules.run_model_solution2_subRun3.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution2_hds_subRun{subRun3_label}",
    params:
        solution=2,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun3_label}/glob_tr",
        var="hds",
        startYear=subRun3_start,
        endYear=subRun3_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=28000,
        tasks=16,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution2_hds_subRun{subRun3_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution1_wtd_subRun3 with:
    input:
        rules.run_model_solution1_subRun3.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution1_wtd_subRun{subRun3_label}",
    params:
        solution=1,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun3_label}/glob_tr",
        var="wtd",
        startYear=subRun3_start,
        endYear=subRun3_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=28000,
        tasks=16,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution1_wtd_subRun{subRun3_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution1_hds_subRun3 with:
    input:
        rules.run_model_solution1_subRun3.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution1_hds_subRun{subRun3_label}",
    params:
        solution=1,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun3_label}/glob_tr",
        var="hds",
        startYear=subRun3_start,
        endYear=subRun3_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=28000,
        tasks=16,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution1_hds_subRun{subRun3_label}.out",
###############################
#  Setup and Run SubRun 4     #
###############################
use rule write_models_solution3_subRun1 as write_models_solution3_subRun4 with:
    input:
        rules._setup_subRun4.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_write_models_solution3_subRun{subRun4_label}",
    params:
        iniFileName="transient_config_with_pump.ini",
        solution=3,
        label=subRun4_label,
    resources:
        slurm_partition='fat_genoa', 
        runtime=1200,
        mem_mb=1440000,
        cpus_per_task=1,
        constraint='scratch-node',
        tasks=192,
        nodes=1,
        slurm_extra=f"--exclusive --output={SLURMDIR_TR}/2_write_model_input/_writeModels/_write_models_solution3_subRun{subRun4_label}.out",
        mpi='mpirun'
use rule write_models_solution3_subRun1 as write_models_solution4_subRun4 with:
    input:
        rules._setup_subRun4.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_write_models_solution4_subRun{subRun4_label}",
    params:
        iniFileName="transient_config_with_pump.ini",
        solution=4,
        label=subRun4_label,
    resources:
        slurm_partition='fat_genoa', 
        runtime=1200,
        mem_mb=1440000,
        cpus_per_task=1,
        constraint='scratch-node',
        tasks=192,
        nodes=1,
        slurm_extra=f"--exclusive --output={SLURMDIR_TR}/2_write_model_input/_writeModels/_write_models_solution4_subRun{subRun4_label}.out",
        mpi='mpirun'
use rule write_models_solution3_subRun1 as write_models_solution2_subRun4 with:
    input:
        rules._setup_subRun4.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_write_models_solution2_subRun{subRun4_label}",
    params:
        iniFileName="transient_config_with_pump.ini",
        solution=2,
        label=subRun4_label,
    resources:
        slurm_partition='fat_genoa', 
        runtime=1200,
        mem_mb=1440000,
        cpus_per_task=1,
        constraint='scratch-node',
        tasks=192,
        nodes=1,
        slurm_extra=f"--exclusive --output={SLURMDIR_TR}/2_write_model_input/_writeModels/_write_models_solution2_subRun{subRun4_label}.out",
        mpi='mpirun'
use rule write_models_solution3_subRun1 as write_models_solution1_subRun4 with:
    input:
        rules._setup_subRun4.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_write_models_solution1_subRun{subRun4_label}",
    params:
        iniFileName="transient_config_with_pump.ini",
        solution=1,
        label=subRun4_label,
    resources:
        slurm_partition='fat_genoa', 
        runtime=1200,
        mem_mb=1440000,
        cpus_per_task=1,
        constraint='scratch-node',
        tasks=192,
        nodes=1,
        slurm_extra=f"--exclusive --output={SLURMDIR_TR}/2_write_model_input/_writeModels/_write_models_solution1_subRun{subRun4_label}.out",
        mpi='mpirun'

use rule modify_ini_conditions_subRun2 as modify_ini_conditions_subRun4 with:
    input:
        rules.write_models_solution1_subRun4.output.outFile,
        rules.write_models_solution2_subRun4.output.outFile,
        rules.write_models_solution3_subRun4.output.outFile,
        rules.write_models_solution4_subRun4.output.outFile,
        
        rules.run_model_solution1_subRun3.output.outFile,
        rules.run_model_solution2_subRun3.output.outFile,
        rules.run_model_solution3_subRun3.output.outFile,
        rules.run_model_solution4_subRun3.output.outFile,

    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_modify_ini_conditions_subRun{subRun4_label}",
    params:
        createIniConditionsScript=f"{RUN_GLOBGM_DIR}/model_tools_src/python/initial_states/initial_states.py",
        modifyPathScript=f"{RUN_GLOBGM_DIR}/model_tools_src/python/initial_states/initial_statesModifyPath.py",
        previousRunModDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun3_label}/glob_tr/models/run_output_bin/",
        label=f"{subRun4_label}",
use rule run_model_solution3_subRun1 as run_model_solution3_subRun4 with:
    input:
        rules.modify_ini_conditions_subRun4.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/done_run_model_solution3_subRun{subRun4_label}",
    params:
        label=subRun4_label,
        solution=3,  
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=300,
        mem_mb=336000,
        tasks=32,
        cpus_per_task=1,
        mpi='srun',
        slurm_extra=f"--exclusive --ntasks-per-node=32 --gres=cpu:1 --output={SLURMDIR_TR}/3_run_model/_run_model_solution3_subRun{subRun4_label}.out",
use rule run_model_solution3_subRun1 as run_model_solution4_subRun4 with:
    input:
        rules.modify_ini_conditions_subRun4.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/done_run_model_solution4_subRun{subRun4_label}",
    params:
        label=subRun4_label,
        solution=4,  
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=300,
        mem_mb=336000,
        tasks=32,
        cpus_per_task=1,
        mpi='srun',
        slurm_extra=f"--exclusive --ntasks-per-node=32 --gres=cpu:1 --output={SLURMDIR_TR}/3_run_model/_run_model_solution4_subRun{subRun4_label}.out",
use rule run_model_solution3_subRun1 as run_model_solution2_subRun4 with:
    input:
        rules.modify_ini_conditions_subRun4.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/done_run_model_solution2_subRun{subRun4_label}",
    params:
        label=subRun4_label,
        solution=2,  
    resources:
        slurm_partition='genoa', 
        nodes=3,
        runtime=300,
        mem_mb=336000,
        tasks=96,
        cpus_per_task=1,
        mpi='srun',
        slurm_extra=f"--exclusive --ntasks-per-node=32 --gres=cpu:1 --output={SLURMDIR_TR}/3_run_model/_run_model_solution2_subRun{subRun4_label}.out",
use rule run_model_solution3_subRun1 as run_model_solution1_subRun4 with:
    input:
        rules.modify_ini_conditions_subRun4.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/done_run_model_solution1_subRun{subRun4_label}",
    params:
        label=subRun4_label,
        solution=1,  
    resources:
        slurm_partition='genoa', 
        nodes=7,
        runtime=300,
        mem_mb=336000,
        tasks=224,
        cpus_per_task=1,
        mpi='srun',
        slurm_extra=f"--exclusive --ntasks-per-node=32 --gres=cpu:1 --output={SLURMDIR_TR}/3_run_model/_run_model_solution1_subRun{subRun4_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution3_wtd_subRun4 with:
    input:
        rules.run_model_solution3_subRun4.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution3_wtd_subRun{subRun4_label}",
    params:
        solution=3,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun4_label}/glob_tr",
        var="wtd",
        startYear=subRun4_start,
        endYear=subRun4_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=28000,
        tasks=16,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution3_wtd_subRun{subRun4_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution3_hds_subRun4 with:
    input:
        rules.run_model_solution3_subRun4.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution3_hds_subRun{subRun4_label}",
    params:
        solution=3,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun4_label}/glob_tr",
        var="hds",
        startYear=subRun4_start,
        endYear=subRun4_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=28000,
        tasks=16,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution3_hds_subRun{subRun4_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution4_wtd_subRun4 with:
    input:
        rules.run_model_solution4_subRun4.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution4_wtd_subRun{subRun4_label}",
    params:
        solution=4,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun4_label}/glob_tr",
        var="wtd",
        startYear=subRun4_start,
        endYear=subRun4_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=56000,
        tasks=32,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution4_wtd_subRun{subRun4_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution4_hds_subRun4 with:
    input:
        rules.run_model_solution4_subRun4.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution4_hds_subRun{subRun4_label}",
    params:
        solution=4,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun4_label}/glob_tr",
        var="hds",
        startYear=subRun4_start,
        endYear=subRun4_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=56000,
        tasks=32,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution4_hds_subRun{subRun4_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution2_wtd_subRun4 with:
    input:
        rules.run_model_solution2_subRun4.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution2_wtd_subRun{subRun4_label}",
    params:
        solution=2,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun4_label}/glob_tr",
        var="wtd",
        startYear=subRun4_start,
        endYear=subRun4_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=28000,
        tasks=16,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution2_wtd_subRun{subRun4_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution2_hds_subRun4 with:
    input:
        rules.run_model_solution2_subRun4.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution2_hds_subRun{subRun4_label}",
    params:
        solution=2,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun4_label}/glob_tr",
        var="hds",
        startYear=subRun4_start,
        endYear=subRun4_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=28000,
        tasks=16,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution2_hds_subRun{subRun4_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution1_wtd_subRun4 with:
    input:
        rules.run_model_solution1_subRun4.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution1_wtd_subRun{subRun4_label}",
    params:
        solution=1,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun4_label}/glob_tr",
        var="wtd",
        startYear=subRun4_start,
        endYear=subRun4_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=28000,
        tasks=16,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution1_wtd_subRun{subRun4_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution1_hds_subRun4 with:
    input:
        rules.run_model_solution1_subRun4.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution1_hds_subRun{subRun4_label}",
    params:
        solution=1,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun4_label}/glob_tr",
        var="hds",
        startYear=subRun4_start,
        endYear=subRun4_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=28000,
        tasks=16,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution1_hds_subRun{subRun4_label}.out",
###############################
#  Setup and Run SubRun 5     #
###############################
use rule write_models_solution3_subRun1 as write_models_solution3_subRun5 with:
    input:
        rules._setup_subRun5.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_write_models_solution3_subRun{subRun5_label}",
    params:
        iniFileName="transient_config_with_pump.ini",
        solution=3,
        label=subRun5_label,
    resources:
        slurm_partition='fat_genoa', 
        runtime=1200,
        mem_mb=1440000,
        cpus_per_task=1,
        constraint='scratch-node',
        tasks=192,
        nodes=1,
        slurm_extra=f"--exclusive --output={SLURMDIR_TR}/2_write_model_input/_writeModels/_write_models_solution3_subRun{subRun5_label}.out",
        mpi='mpirun'
use rule write_models_solution3_subRun1 as write_models_solution4_subRun5 with:
    input:
        rules._setup_subRun5.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_write_models_solution4_subRun{subRun5_label}",
    params:
        iniFileName="transient_config_with_pump.ini",
        solution=4,
        label=subRun5_label,
    resources:
        slurm_partition='fat_genoa', 
        runtime=1200,
        mem_mb=1440000,
        cpus_per_task=1,
        constraint='scratch-node',
        tasks=192,
        nodes=1,
        slurm_extra=f"--exclusive --output={SLURMDIR_TR}/2_write_model_input/_writeModels/_write_models_solution4_subRun{subRun5_label}.out",
        mpi='mpirun'
use rule write_models_solution3_subRun1 as write_models_solution2_subRun5 with:
    input:
        rules._setup_subRun5.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_write_models_solution2_subRun{subRun5_label}",
    params:
        iniFileName="transient_config_with_pump.ini",
        solution=2,
        label=subRun5_label,
    resources:
        slurm_partition='fat_genoa', 
        runtime=1200,
        mem_mb=1440000,
        cpus_per_task=1,
        constraint='scratch-node',
        tasks=192,
        nodes=1,
        slurm_extra=f"--exclusive --output={SLURMDIR_TR}/2_write_model_input/_writeModels/_write_models_solution2_subRun{subRun5_label}.out",
        mpi='mpirun'
use rule write_models_solution3_subRun1 as write_models_solution1_subRun5 with:
    input:
        rules._setup_subRun5.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_write_models_solution1_subRun{subRun5_label}",
    params:
        iniFileName="transient_config_with_pump.ini",
        solution=1,
        label=subRun5_label,
    resources:
        slurm_partition='fat_genoa', 
        runtime=1200,
        mem_mb=1440000,
        cpus_per_task=1,
        constraint='scratch-node',
        tasks=192,
        nodes=1,
        slurm_extra=f"--exclusive --output={SLURMDIR_TR}/2_write_model_input/_writeModels/_write_models_solution1_subRun{subRun5_label}.out",
        mpi='mpirun'
use rule modify_ini_conditions_subRun2 as modify_ini_conditions_subRun5 with:
    input:
        rules.write_models_solution1_subRun5.output.outFile,
        rules.write_models_solution2_subRun5.output.outFile,
        rules.write_models_solution3_subRun5.output.outFile,
        rules.write_models_solution4_subRun5.output.outFile,
        
        rules.run_model_solution1_subRun4.output.outFile,
        rules.run_model_solution2_subRun4.output.outFile,
        rules.run_model_solution3_subRun4.output.outFile,
        rules.run_model_solution4_subRun4.output.outFile,

    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_modify_ini_conditions_subRun{subRun5_label}",
    params:
        createIniConditionsScript=f"{RUN_GLOBGM_DIR}/model_tools_src/python/initial_states/initial_states.py",
        modifyPathScript=f"{RUN_GLOBGM_DIR}/model_tools_src/python/initial_states/initial_statesModifyPath.py",
        previousRunModDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun4_label}/glob_tr/models/run_output_bin/",
        label=f"{subRun5_label}",
use rule run_model_solution3_subRun1 as run_model_solution3_subRun5 with:
    input:
        rules.modify_ini_conditions_subRun5.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/done_run_model_solution3_subRun{subRun5_label}",
    params:
        label=subRun5_label,
        solution=3,  
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=300,
        mem_mb=336000,
        tasks=32,
        cpus_per_task=1,
        mpi='srun',
        slurm_extra=f"--exclusive --ntasks-per-node=32 --gres=cpu:1 --output={SLURMDIR_TR}/3_run_model/_run_model_solution3_subRun{subRun5_label}.out",
use rule run_model_solution3_subRun1 as run_model_solution4_subRun5 with:
    input:
        rules.modify_ini_conditions_subRun5.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/done_run_model_solution4_subRun{subRun5_label}",
    params:
        label=subRun5_label,
        solution=4,  
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=300,
        mem_mb=336000,
        tasks=32,
        cpus_per_task=1,
        mpi='srun',
        slurm_extra=f"--exclusive --ntasks-per-node=32 --gres=cpu:1 --output={SLURMDIR_TR}/3_run_model/_run_model_solution4_subRun{subRun5_label}.out",
use rule run_model_solution3_subRun1 as run_model_solution2_subRun5 with:
    input:
        rules.modify_ini_conditions_subRun5.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/done_run_model_solution2_subRun{subRun5_label}",
    params:
        label=subRun5_label,
        solution=2,  
    resources:
        slurm_partition='genoa', 
        nodes=3,
        runtime=300,
        mem_mb=336000,
        tasks=96,
        cpus_per_task=1,
        mpi='srun',
        slurm_extra=f"--exclusive --ntasks-per-node=32 --gres=cpu:1 --output={SLURMDIR_TR}/3_run_model/_run_model_solution2_subRun{subRun5_label}.out",
use rule run_model_solution3_subRun1 as run_model_solution1_subRun5 with:
    input:
        rules.modify_ini_conditions_subRun5.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/done_run_model_solution1_subRun{subRun5_label}",
    params:
        label=subRun5_label,
        solution=1,  
    resources:
        slurm_partition='genoa', 
        nodes=7,
        runtime=300,
        mem_mb=336000,
        tasks=224,
        cpus_per_task=1,
        mpi='srun',
        slurm_extra=f"--exclusive --ntasks-per-node=32 --gres=cpu:1 --output={SLURMDIR_TR}/3_run_model/_run_model_solution1_subRun{subRun5_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution3_wtd_subRun5 with:
    input:
        rules.run_model_solution3_subRun5.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution3_wtd_subRun{subRun5_label}",
    params:
        solution=3,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun5_label}/glob_tr",
        var="wtd",
        startYear=subRun5_start,
        endYear=subRun5_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=28000,
        tasks=16,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution3_wtd_subRun{subRun5_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution3_hds_subRun5 with:
    input:
        rules.run_model_solution3_subRun5.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution3_hds_subRun{subRun5_label}",
    params:
        solution=3,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun5_label}/glob_tr",
        var="hds",
        startYear=subRun5_start,
        endYear=subRun5_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=28000,
        tasks=16,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution3_hds_subRun{subRun5_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution4_wtd_subRun5 with:
    input:
        rules.run_model_solution4_subRun5.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution4_wtd_subRun{subRun5_label}",
    params:
        solution=4,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun5_label}/glob_tr",
        var="wtd",
        startYear=subRun5_start,
        endYear=subRun5_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=56000,
        tasks=32,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution4_wtd_subRun{subRun5_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution4_hds_subRun5 with:
    input:
        rules.run_model_solution4_subRun5.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution4_hds_subRun{subRun5_label}",
    params:
        solution=4,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun5_label}/glob_tr",
        var="hds",
        startYear=subRun5_start,
        endYear=subRun5_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=56000,
        tasks=32,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution4_hds_subRun{subRun5_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution2_wtd_subRun5 with:
    input:
        rules.run_model_solution2_subRun5.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution2_wtd_subRun{subRun5_label}",
    params:
        solution=2,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun5_label}/glob_tr",
        var="wtd",
        startYear=subRun5_start,
        endYear=subRun5_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=28000,
        tasks=16,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution2_wtd_subRun{subRun5_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution2_hds_subRun5 with:
    input:
        rules.run_model_solution2_subRun5.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution2_hds_subRun{subRun5_label}",
    params:
        solution=2,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun5_label}/glob_tr",
        var="hds",
        startYear=subRun5_start,
        endYear=subRun5_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=28000,
        tasks=16,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution2_hds_subRun{subRun5_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution1_wtd_subRun5 with:
    input:
        rules.run_model_solution1_subRun5.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution1_wtd_subRun{subRun5_label}",
    params:
        solution=1,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun5_label}/glob_tr",
        var="wtd",
        startYear=subRun5_start,
        endYear=subRun5_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=28000,
        tasks=16,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution1_wtd_subRun{subRun5_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution1_hds_subRun5 with:
    input:
        rules.run_model_solution1_subRun5.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution1_hds_subRun{subRun5_label}",
    params:
        solution=1,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun5_label}/glob_tr",
        var="hds",
        startYear=subRun5_start,
        endYear=subRun5_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=28000,
        tasks=16,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution1_hds_subRun{subRun5_label}.out",

###############################
#  Setup and Run SubRun 6     #
###############################
use rule write_models_solution3_subRun1 as write_models_solution3_subRun6 with:
    input:
        rules._setup_subRun6.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_write_models_solution3_subRun{subRun6_label}",
    params:
        iniFileName="transient_config_with_pump.ini",
        solution=3,
        label=subRun6_label,
    resources:
        slurm_partition='fat_genoa', 
        runtime=1200,
        mem_mb=1440000,
        cpus_per_task=1,
        constraint='scratch-node',
        tasks=192,
        nodes=1,
        slurm_extra=f"--exclusive --output={SLURMDIR_TR}/2_write_model_input/_writeModels/_write_models_solution3_subRun{subRun6_label}.out",
        mpi='mpirun'
use rule write_models_solution3_subRun1 as write_models_solution4_subRun6 with:
    input:
        rules._setup_subRun6.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_write_models_solution4_subRun{subRun6_label}",
    params:
        iniFileName="transient_config_with_pump.ini",
        solution=4,
        label=subRun6_label,
    resources:
        slurm_partition='fat_genoa', 
        runtime=1200,
        mem_mb=1440000,
        cpus_per_task=1,
        constraint='scratch-node',
        tasks=192,
        nodes=1,
        slurm_extra=f"--exclusive --output={SLURMDIR_TR}/2_write_model_input/_writeModels/_write_models_solution4_subRun{subRun6_label}.out",
        mpi='mpirun'
use rule write_models_solution3_subRun1 as write_models_solution2_subRun6 with:
    input:
        rules._setup_subRun6.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_write_models_solution2_subRun{subRun6_label}",
    params:
        iniFileName="transient_config_with_pump.ini",
        solution=2,
        label=subRun6_label,
    resources:
        slurm_partition='fat_genoa', 
        runtime=1200,
        mem_mb=1440000,
        cpus_per_task=1,
        constraint='scratch-node',
        tasks=192,
        nodes=1,
        slurm_extra=f"--exclusive --output={SLURMDIR_TR}/2_write_model_input/_writeModels/_write_models_solution2_subRun{subRun6_label}.out",
        mpi='mpirun'
use rule write_models_solution3_subRun1 as write_models_solution1_subRun6 with:
    input:
        rules._setup_subRun6.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_write_models_solution1_subRun{subRun6_label}",
    params:
        iniFileName="transient_config_with_pump.ini",
        solution=1,
        label=subRun6_label,
    resources:
        slurm_partition='fat_genoa', 
        runtime=1200,
        mem_mb=1440000,
        cpus_per_task=1,
        constraint='scratch-node',
        tasks=192,
        nodes=1,
        slurm_extra=f"--exclusive --output={SLURMDIR_TR}/2_write_model_input/_writeModels/_write_models_solution1_subRun{subRun6_label}.out",
        mpi='mpirun'
use rule modify_ini_conditions_subRun2 as modify_ini_conditions_subRun6 with:
    input:
        rules.write_models_solution1_subRun6.output.outFile,
        rules.write_models_solution2_subRun6.output.outFile,
        rules.write_models_solution3_subRun6.output.outFile,
        rules.write_models_solution4_subRun6.output.outFile,
        
        rules.run_model_solution1_subRun5.output.outFile,
        rules.run_model_solution2_subRun5.output.outFile,
        rules.run_model_solution3_subRun5.output.outFile,
        rules.run_model_solution4_subRun5.output.outFile,

    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_modify_ini_conditions_subRun{subRun6_label}",
    params:
        createIniConditionsScript=f"{RUN_GLOBGM_DIR}/model_tools_src/python/initial_states/initial_states.py",
        modifyPathScript=f"{RUN_GLOBGM_DIR}/model_tools_src/python/initial_states/initial_statesModifyPath.py",
        previousRunModDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun5_label}/glob_tr/models/run_output_bin/",
        label=f"{subRun6_label}",
use rule run_model_solution3_subRun1 as run_model_solution3_subRun6 with:
    input:
        rules.modify_ini_conditions_subRun6.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/done_run_model_solution3_subRun{subRun6_label}",
    params:
        label=subRun6_label,
        solution=3,  
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=300,
        mem_mb=336000,
        tasks=32,
        cpus_per_task=1,
        mpi='srun',
        slurm_extra=f"--exclusive --ntasks-per-node=32 --gres=cpu:1 --output={SLURMDIR_TR}/3_run_model/_run_model_solution3_subRun{subRun6_label}.out",
use rule run_model_solution3_subRun1 as run_model_solution4_subRun6 with:
    input:
        rules.modify_ini_conditions_subRun6.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/done_run_model_solution4_subRun{subRun6_label}",
    params:
        label=subRun6_label,
        solution=4,  
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=300,
        mem_mb=336000,
        tasks=32,
        cpus_per_task=1,
        mpi='srun',
        slurm_extra=f"--exclusive --ntasks-per-node=32 --gres=cpu:1 --output={SLURMDIR_TR}/3_run_model/_run_model_solution4_subRun{subRun6_label}.out",
use rule run_model_solution3_subRun1 as run_model_solution2_subRun6 with:
    input:
        rules.modify_ini_conditions_subRun6.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/done_run_model_solution2_subRun{subRun6_label}",
    params:
        label=subRun6_label,
        solution=2,  
    resources:
        slurm_partition='genoa', 
        nodes=3,
        runtime=300,
        mem_mb=336000,
        tasks=96,
        cpus_per_task=1,
        mpi='srun',
        slurm_extra=f"--exclusive --ntasks-per-node=32 --gres=cpu:1 --output={SLURMDIR_TR}/3_run_model/_run_model_solution2_subRun{subRun6_label}.out",
use rule run_model_solution3_subRun1 as run_model_solution1_subRun6 with:    
    input:
        rules.modify_ini_conditions_subRun6.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/done_run_model_solution1_subRun{subRun6_label}",
    params:
        label=subRun6_label,
        solution=1,  
    resources:
        slurm_partition='genoa', 
        nodes=7,
        runtime=300,
        mem_mb=336000,
        tasks=224,
        cpus_per_task=1,
        mpi='srun',
        slurm_extra=f"--exclusive --ntasks-per-node=32 --gres=cpu:1 --output={SLURMDIR_TR}/3_run_model/_run_model_solution1_subRun{subRun6_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution3_wtd_subRun6 with:
    input:
        rules.run_model_solution3_subRun6.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution3_wtd_subRun{subRun6_label}",
    params:
        solution=3,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun6_label}/glob_tr",
        var="wtd",
        startYear=subRun6_start,
        endYear=subRun6_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=28000,
        tasks=16,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution3_wtd_subRun{subRun6_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution3_hds_subRun6 with:
    input:
        rules.run_model_solution3_subRun6.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution3_hds_subRun{subRun6_label}",
    params:
        solution=3,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun6_label}/glob_tr",
        var="hds",
        startYear=subRun6_start,
        endYear=subRun6_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=28000,
        tasks=16,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution3_hds_subRun{subRun6_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution4_wtd_subRun6 with:
    input:
        rules.run_model_solution4_subRun6.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution4_wtd_subRun{subRun6_label}",
    params:
        solution=4,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun6_label}/glob_tr",
        var="wtd",
        startYear=subRun6_start,
        endYear=subRun6_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=56000,
        tasks=32,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution4_wtd_subRun{subRun6_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution4_hds_subRun6 with:
    input:
        rules.run_model_solution4_subRun6.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution4_hds_subRun{subRun6_label}",
    params:
        solution=4,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun6_label}/glob_tr",
        var="hds",
        startYear=subRun6_start,
        endYear=subRun6_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=56000,
        tasks=32,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution4_hds_subRun{subRun6_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution2_wtd_subRun6 with:
    input:
        rules.run_model_solution2_subRun6.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution2_wtd_subRun{subRun6_label}",
    params:
        solution=2,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun6_label}/glob_tr",
        var="wtd",
        startYear=subRun6_start,
        endYear=subRun6_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=28000,
        tasks=16,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution2_wtd_subRun{subRun6_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution2_hds_subRun6 with:
    input:
        rules.run_model_solution2_subRun6.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution2_hds_subRun{subRun6_label}",
    params:
        solution=2,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun6_label}/glob_tr",
        var="hds",
        startYear=subRun6_start,
        endYear=subRun6_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=28000,
        tasks=16,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution2_hds_subRun{subRun6_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution1_wtd_subRun6 with:
    input:
        rules.run_model_solution1_subRun6.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution1_wtd_subRun{subRun6_label}",
    params:
        solution=1,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun6_label}/glob_tr",
        var="wtd",
        startYear=subRun6_start,
        endYear=subRun6_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=28000,
        tasks=16,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution1_wtd_subRun{subRun6_label}.out",
use rule post_model_solution3_wtd_subRun1 as post_model_solution1_hds_subRun6 with:
    input:
        rules.run_model_solution1_subRun6.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_model_solution1_hds_subRun{subRun6_label}",
    params:
        solution=1,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_{subRun6_label}/glob_tr",
        var="hds",
        startYear=subRun6_start,
        endYear=subRun6_end,
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=7140,
        constraint='scratch-node',
        mem_mb=28000,
        tasks=16,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution1_hds_subRun{subRun6_label}.out",