localrules: setup_simulation,prepare_model_partitioning,write_model_forcing_setup,write_model_input_setup,modify_ini_conditions
import os
SIMULATION = config["simulation"]
OUTPUTDIRECTORY = config["outputDirectory"]
RUN_GLOBGM_DIR = config["run_globgm_dir"]

MODELROOT_TR=f"{OUTPUTDIRECTORY}/{SIMULATION}/tr_with_pump"
SLURMDIR_TR=f"{MODELROOT_TR}/slurm_logs"
DATA_DIR = config["data_dir"]

STARTYEAR = 1960
ENDYEAR = 1963

rule all:
    input:
        f"{SLURMDIR_TR}/2_write_model_input/done_writeModels_forcing_subset1",
        f"{SLURMDIR_TR}/2_write_model_input/done_writeModels_forcing_subset2",

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
        simulation=$(basename $(dirname $modelRoot))
        cmip6InputFolder=$data_dir/cmip6_input/$simulation/historical
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
            cdo -L -f nc4 -setrtoc,-inf,0,0 -setunit,m.day-1 -divc,365.25 -timmean -yearsum -selyear,1960/2014 $inFile $outFile.temp.nc
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

            cdo -L -f nc4 -setunit,m.day-1 -divc,365.25 -timmean -yearsum -selyear,1960/2014 $inFile $outFile.temp.nc
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
        correctionFile=$(find "$data_dir/cmip6_input/$simulation/historical" -type d -name "*gwRecharge_correction_factor.zarr*")
        precipFile=$(find "$data_dir/cmip6_input/$simulation/historical" -type f -name "*precipitation*")
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
        slurm_partition='genoa', 
        runtime=720,
        constraint='scratch-node',
        mem_mb=336000,
        cpus_per_task=1,
        tasks=192,
        nodes=1,
        slurm_extra=f"--exclusive --output={SLURMDIR_TR}/2_write_model_input/_writeModels_forcing_subset1.out",
    shell:
        '''
        set +u; source ${{HOME}}/.bashrc && mamba activate globgm_pcraster ; set -u

        modelRoot={MODELROOT_TR}
        start_year={STARTYEAR}
        end_year={ENDYEAR}
        data_dir={DATA_DIR}
        simulation=$(basename $(dirname $modelRoot))
        cmip6InputFolder=$data_dir/cmip6_input/$simulation/historical
        saveFolder=$modelRoot/forcing_input
        PCR_GLOB_dir=$(realpath ../model_tools_src/python/pcr-globwb)

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
        slurm_partition='genoa', 
        runtime=720,
        constraint='scratch-node',
        mem_mb=336000,
        cpus_per_task=1,
        tasks=192,
        nodes=1,
        slurm_extra=f"--exclusive --output={SLURMDIR_TR}/2_write_model_input/_writeModels_forcing_subset2.out",
rule write_model_input_setup:
    input:
        rules.write_model_forcing_sub1.output.outFile,
        rules.write_model_forcing_sub2.output.outFile
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_writeModels_tr_setup_1",
    params:
        nSpin=1,
        label1=1,
        iniStatesFolder=f"{OUTPUTDIRECTORY}/{SIMULATION}/ss/mf6_mod/glob_ss/models/run_output_bin/",
    shell:
        '''
        modelRoot={MODELROOT_TR}
        start_year={STARTYEAR}
        end_year={ENDYEAR}
        nSpin={params.nSpin}
        dataDir={DATA_DIR}
        label={params.label1}
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

rule write_model_input_solution3:
    input:
        rules.write_model_input_maps.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_write_model_input_solution3"
    params:
        label=rules.write_model_input_setup.params.label1,
        solution=3,
        runType="start",
        iniFileName="transient_config_with_pump.ini"
    resources:
        slurm_partition='fat_genoa', 
        runtime=720,
        constraint='scratch-node',
        mem_mb=336000,
        cpus_per_task=1,
        tasks=192,
        nodes=1,
        slurm_extra=f"--exclusive --output={SLURMDIR_TR}/2_write_model_input/_writeModels/3_wMod_1.out",
        mpi='mpirun'
    shell:
        '''
        set +u; source ${{HOME}}/.bashrc && mamba activate globgm_pcraster ; set -u

        modelRoot={MODELROOT_TR}
        id={params.label}
        runType={params.runType}
        dataDir={DATA_DIR}
        iniFileName={params.iniFileName}

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
        forcingDir=$_tempDir/forcing_input
        globgmDir=$modelRoot

        OUT_DIR=$modelRoot/input_map/transient

        START_DATE=$(grep 'STARTDATE' ${{moddir}}/${{inpmod}} | awk '{{print $2}}')
        nMonths=$(grep 'NPER' ${{moddir}}/${{inpmod}} | awk '{{print $2}}')
        PCR_GLOB_dir=$(realpath ../model_tools_src/python/pcr-globwb)
        cd $PCR_GLOB_dir
        cp $model_input/${{iniFileName}} $TMPDIR/${{iniFileName}}
        wait 
        counter=0
        for ((i=1; i<=163; i+=1)); do
            num=$(printf "%03d" $((10#$i)))
            python deterministic_runner_for_monthly_offline_globgm.py $TMPDIR/${{iniFileName}} debug transient tile_${{num}}-163 $IN_DIR $OUT_DIR $forcingDir $START_DATE $nMonths &
            counter=$((counter+1))
            if [ $counter -eq 33 ]; then
                wait
                counter=0
            fi
        done

        wait
        '''


        # '''




        # module load 2023
        # module load mpifileutils/0.11.1-gompi-2023a

        # modelRoot={MODELROOT_TR}
        # id={params.label}
        # solution={params.solution}
        # runType={params.runType}
        # dataDir={DATA_DIR}

        # exe=$dataDir/_bin/mf6ggm_181121
        # model_input=$modelRoot/model_input/2_partition_and_write_model_input/transient
        # moddir=$modelRoot/mf6_mod/mf6_mod_${{id}}
        # inpmod=mf6_mod_tr.inp
        # inpexe=mf6ggm_tr.inp
        # modifyPathScript=$(realpath ../model_tools_src/python/initial_states/initial_statesModifyPath.py)
        # wait

        # globgmDir=$modelRoot
        # cp ${{moddir}}/${{inpmod}} ${{moddir}}/${{inpmod}}_${{solution}}_${{id}}
        # cp ${{moddir}}/${{inpexe}} ${{moddir}}/${{inpexe}}_${{solution}}_${{id}}
        # inputStr=mf6_mod_tr.inp_${{solution}}_${{id}}

        # sed -i "s|mf6_mod_tr.inp|${{inputStr}}|g" ${{moddir}}/${{inpexe}}_${{solution}}_${{id}}
        # sed -i "s|INPUT_DIST_DIR ${{modelRoot}}|INPUT_DIST_DIR ${{globgmDir}}|g" ${{moddir}}/${{inpmod}}_${{solution}}_${{id}}
        # wait 

        # cd ${{moddir}}

        # if [ $solution -eq 1 ]; then
        #     startMod=1
        #     endMod=224
        # fi

        # if [ $solution -eq 2 ]; then
        #     startMod=225
        #     endMod=320
        # fi

        # if [ $solution -eq 3 ]; then
        #     startMod=321
        #     endMod=352
        # fi

        # if [ $solution -eq 4 ]; then
        #     startMod=353
        #     endMod=384
        # fi
        # for ((i=$startMod; i<=$endMod; i+=2)); do
        #     ii=$((i + 1))
        #     if [ $ii -gt 384 ]; then
        #         ii=384
        #     fi
        #     ${{exe}} ${{inpexe}}_${{solution}}_${{id}} $i $ii &
        # done
        # wait

        # rm ${{moddir}}/${{inpexe}}_${{solution}}_${{id}}
        # rm ${{moddir}}/${{inpmod}}_${{solution}}_${{id}}
        # wait

        # if [ $runType == "subRun" ]; then
        #     python $modifyPathScript $moddir
        # fi

        # wait
        # touch {output.outFile}
        # '''

