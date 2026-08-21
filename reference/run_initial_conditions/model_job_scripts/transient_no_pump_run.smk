localrules: setup_simulation,prepare_model_partitioning,write_model_forcing_setup,write_model_input_setup
import os
SIMULATION = config["simulation"]
OUTPUTDIRECTORY = config["outputDirectory"]
RUN_GLOBGM_DIR = config["run_globgm_dir"]

MODELROOT_TR=f"{OUTPUTDIRECTORY}/{SIMULATION}/tr_no_pump"
SLURMDIR_TR=f"{MODELROOT_TR}/slurm_logs"
DATA_DIR = config["data_dir"]

STARTYEAR = 1960
ENDYEAR = 1960

rule all:
    input:
        f"{SLURMDIR_TR}/4_post-processing/done_validation_rep"

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
        
rule write_model_input_maps:
    input:
        rules.write_model_input_setup.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_writeModels_map"
    params:
        label=rules.write_model_input_setup.params.label1,
        runType="start",
        iniFileName="transient_config_no_pump.ini"
    resources:
        slurm_partition='fat_genoa', 
        runtime=720,
        constraint='scratch-node',
        mem_mb=336000,
        cpus_per_task=1,
        tasks=192,
        nodes=1,
        slurm_extra=f"--exclusive --output={SLURMDIR_TR}/2_write_model_input/_write_model_input_maps.out",
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
    resources:
        slurm_partition='fat_genoa', 
        runtime=720,
        mem_mb=108500,
        cpus_per_task=2,
        constraint='scratch-node',
        tasks=96,
        nodes=1,
        slurm_extra=f"--exclusive --output={SLURMDIR_TR}/2_write_model_input/_writeModels/3_wMod_1.out",
        mpi='mpirun'
    shell:
        '''
        module load 2023
        module load mpifileutils/0.11.1-gompi-2023a

        modelRoot={MODELROOT_TR}
        id={params.label}
        solution={params.solution}
        runType={params.runType}
        dataDir={DATA_DIR}

        exe=$dataDir/_bin/mf6ggm_181121
        model_input=$modelRoot/model_input/2_partition_and_write_model_input/transient
        moddir=$modelRoot/mf6_mod/mf6_mod_${{id}}
        inpmod=mf6_mod_tr.inp
        inpexe=mf6ggm_tr.inp
        modifyPathScript=$(realpath ../model_tools_src/python/initial_states/initial_statesModifyPath.py)
        wait

        globgmDir=$modelRoot
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

        rm ${{moddir}}/${{inpexe}}_${{solution}}_${{id}}
        rm ${{moddir}}/${{inpmod}}_${{solution}}_${{id}}
        wait

        if [ $runType == "subRun" ]; then
            python $modifyPathScript $moddir
        fi

        wait
        touch {output.outFile}
        '''

use rule write_model_input_solution3 as write_model_input_solution4 with:
    input:
        rules.write_model_input_maps.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_write_model_input_solution4"
    params:
        label=rules.write_model_input_setup.params.label1,
        solution=4,
        runType="start",
    resources:
        slurm_partition='fat_genoa', 
        runtime=720,
        mem_mb=108500,
        cpus_per_task=2,
        constraint='scratch-node',
        tasks=96,
        nodes=1,
        slurm_extra=f"--exclusive --output={SLURMDIR_TR}/2_write_model_input/_writeModels/4_wMod_1.out",
        mpi='mpirun'
use rule write_model_input_solution3 as write_model_input_solution2 with:
    input:
        rules.write_model_input_maps.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_write_model_input_solution2"
    params:
        label=rules.write_model_input_setup.params.label1,
        solution=2,
        runType="start",
    resources:
        slurm_partition='fat_genoa', 
        runtime=720,
        mem_mb=108500,
        cpus_per_task=2,
        constraint='scratch-node',
        tasks=96,
        nodes=1,
        slurm_extra=f"--exclusive --output={SLURMDIR_TR}/2_write_model_input/_writeModels/2_wMod_1.out",
        mpi='mpirun'
use rule write_model_input_solution3 as write_model_input_solution1 with:
    input:
        rules.write_model_input_maps.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/done_write_model_input_solution1"
    params:
        label=rules.write_model_input_setup.params.label1,
        solution=1,
        runType="start",
    resources:
        slurm_partition='fat_genoa', 
        runtime=720,
        mem_mb=108500,
        cpus_per_task=2,
        constraint='scratch-node',
        tasks=96,
        nodes=1,
        slurm_extra=f"--exclusive --output={SLURMDIR_TR}/2_write_model_input/_writeModels/1_wMod_1.out",
        mpi='mpirun'

rule run_model_solution3:
    input:
        rules.write_model_input_solution1.output.outFile,
        rules.write_model_input_solution2.output.outFile,
        rules.write_model_input_solution3.output.outFile,
        rules.write_model_input_solution4.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/done_runModels_complete3_1",
    params:
        label=rules.write_model_input_setup.params.label1,
        runType="start",
        solution=3,  
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=120,
        mem_mb=336000,
        tasks=32,
        cpus_per_task=1,
        mpi='srun',
        slurm_extra=f"--exclusive --ntasks-per-node=32 --gres=cpu:1 --output={SLURMDIR_TR}/3_run_model/_run_solution_3.out",
    shell:
        '''
        module load 2023
        module load OpenMPI/4.1.5-GCC-12.3.0
        modelRoot={MODELROOT_TR}
        runType={params.runType}
        solution={params.solution}
        simStart={STARTYEAR}
        simEnd={ENDYEAR}
        label={params.label}
        dataDir={DATA_DIR}

        to_zarrFolder=$(realpath ../model_tools_src/python/to_zarr)
        postDir=$modelRoot/mf6_post
        mkdir -p $postDir
        python -u $to_zarrFolder/createZarr_tr.py $dataDir $solution $postDir $simStart $simEnd wtd & 
        python -u $to_zarrFolder/createZarr_tr.py $dataDir $solution $postDir $simStart $simEnd hds
        wait

        iniConditionsScript=$(realpath ../model_tools_src/python/initial_states/initial_states.py)
        modifyPathScript=$(realpath ../model_tools_src/python/initial_states/initial_statesModifyPath.py)
        exe=$dataDir/_bin/mf6_rel_openmpi-4.1.4-gcc-11.3.0
        nam1=s0${{solution}}.par.mfsim.spu.nam
        nam2=s0${{solution}}.par.mfsim.ic_spu.nam

        dir_run=$modelRoot/mf6_mod/mf6_mod_${{label}}/glob_tr/solutions/run_output/
        cd ${{dir_run}}

        if [ "$runType" = "start" ]; then
            {resources.mpi} ${{exe}} -s ../run_input/${{nam1}}
            {resources.mpi} ${{exe}} -s ../run_input/${{nam2}}

            if [ $solution -eq 1 ]; then
                python $modifyPathScript $modelRoot/mf6_mod/mf6_mod_${{label}}
                python $iniConditionsScript $dir_run
            fi
        fi
        wait

        if [ "$runType" = "subRun" ]; then
            {resources.mpi} ${{exe}} -s ../run_input/${{nam2}}
            if [ $solution -eq 1 ]; then
                python $iniConditionsScript $dir_run
            fi
        fi


        wait
        touch {output.outFile}
        '''

use rule run_model_solution3 as run_model_solution4 with:
    input:
        rules.write_model_input_solution1.output.outFile,
        rules.write_model_input_solution2.output.outFile,
        rules.write_model_input_solution3.output.outFile,
        rules.write_model_input_solution4.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/done_runModels_complete4_1",
    params:
        label=rules.write_model_input_setup.params.label1,
        runType="start",
        solution=4,  
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=120,
        mem_mb=336000,
        tasks=32,
        cpus_per_task=1,
        mpi='srun',
        slurm_extra=f"--exclusive --ntasks-per-node=32 --gres=cpu:1 --output={SLURMDIR_TR}/3_run_model/_run_solution_4.out",
use rule run_model_solution3 as run_model_solution2 with:
    input:
        rules.write_model_input_solution1.output.outFile,
        rules.write_model_input_solution2.output.outFile,
        rules.write_model_input_solution3.output.outFile,
        rules.write_model_input_solution4.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/done_runModels_complete2_1",
    params:
        label=rules.write_model_input_setup.params.label1,
        runType="start",
        solution=2,  
    resources:
        slurm_partition='genoa', 
        nodes=3,
        runtime=120,
        mem_mb=336000,
        tasks=96,
        cpus_per_task=1,
        mpi='srun',
        slurm_extra=f"--exclusive --ntasks-per-node=32 --gres=cpu:1 --output={SLURMDIR_TR}/3_run_model/_run_solution_2.out",
use rule run_model_solution3 as run_model_solution1 with:
    input:
        rules.write_model_input_solution1.output.outFile,
        rules.write_model_input_solution2.output.outFile,
        rules.write_model_input_solution3.output.outFile,
        rules.write_model_input_solution4.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/done_runModels_complete1_1",
    params:
        label=rules.write_model_input_setup.params.label1,
        runType="start",
        solution=1,  
    resources:
        slurm_partition='genoa', 
        nodes=7,
        runtime=120,
        mem_mb=336000,
        tasks=224,
        cpus_per_task=1,
        mpi='srun',
        slurm_extra=f"--exclusive --ntasks-per-node=32 --gres=cpu:1 --output={SLURMDIR_TR}/3_run_model/_run_solution_1.out",

rule post_model_solution3_wtd:
    input:
        rules.run_model_solution3.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_3_1_wtd",
    params:
        solution=3,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_1/glob_tr",
        var="wtd",
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=120,
        constraint='scratch-node',
        mem_mb=112000,
        tasks=64,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution3_wtd.out",
    shell:
        '''
        modelRoot={MODELROOT_TR}
        var={params.var}
        solution={params.solution}
        startDate={STARTYEAR}
        endDate={ENDYEAR}
        modDir={params.modDir}
        dataDir={DATA_DIR}

        _merge_zarr=$(realpath ../model_tools_src/python/to_zarr/mergeZarr_tr.py)
        _plot_script=$(realpath ../model_tools_src/python/to_zarr/mean_plot.py)
        inpdir=$modelRoot/model_input/4_post-processing/transient
        inp_tr=mf6ggm_post_tr_$var.inp
        exe=$dataDir/_bin/mf6ggmpost_260624
        yodaInput=$dataDir/globgm_input
        dir=$modelRoot/mf6_post
        input_file=s0${{solution}}_${{inp_tr}}

        counter=0
        for ((year=$startDate; year<=$endDate; year++));do
            counter=$((counter+1))
            modFlowTemp=$TMPDIR/output
            mkdir -p $modFlowTemp
            cd $modFlowTemp
            mkdir -p ./mod_files_s0${{solution}}_${{year}} ./out
            cd ./mod_files_s0${{solution}}_${{year}}
            # #Convert output to .flt
            sub_input=${{input_file}}_${{year}}
            cp ${{inpdir}}/${{inp_tr}} ./$sub_input
            sed -i "s|{{yoda_input}}|${{yodaInput}}|g" $sub_input
            sed -i "s|{{globgm_dir}}|${{modelRoot}}|g" $sub_input
            sed -i "s|{{mod_dir}}|${{modDir}}|g" $sub_input
            sed -i "s|{{solution}}|${{solution}}|g" $sub_input
            sed -i "s|{{START_DATE}}|${{year}}|g" $sub_input
            sed -i "s|{{END_DATE}}|${{year}}|g" $sub_input
            sed -i "s|{{MOD_START_DATE}}|${{startDate}}|g" $sub_input
            ${{exe}} $sub_input &
            if [ $counter -eq 6 ]; then
                wait
                counter=0
            fi
        done
        wait

        counter=0
        for ((year=$startDate; year<=$endDate; year++));do
            counter=$((counter+1))
            # python -u $_merge_zarr $dir $modFlowTemp/out $solution $year 01 $var &
            # python -u $_merge_zarr $dir $modFlowTemp/out $solution $year 02 $var &
            # python -u $_merge_zarr $dir $modFlowTemp/out $solution $year 03 $var &
            # python -u $_merge_zarr $dir $modFlowTemp/out $solution $year 04 $var &
            # python -u $_merge_zarr $dir $modFlowTemp/out $solution $year 05 $var &
            # python -u $_merge_zarr $dir $modFlowTemp/out $solution $year 06 $var &
            # python -u $_merge_zarr $dir $modFlowTemp/out $solution $year 07 $var &
            # python -u $_merge_zarr $dir $modFlowTemp/out $solution $year 08 $var &
            # python -u $_merge_zarr $dir $modFlowTemp/out $solution $year 09 $var &
            # python -u $_merge_zarr $dir $modFlowTemp/out $solution $year 10 $var &
            # python -u $_merge_zarr $dir $modFlowTemp/out $solution $year 11 $var &
            python -u $_merge_zarr $dir $modFlowTemp/out $solution $year 12 $var
            if [ $counter -eq 3 ]; then
                wait
                counter=0
            fi
        done
        wait

        python -u $_plot_script $dir $solution $var
        wait
        touch {output.outFile}
        '''

use rule post_model_solution3_wtd as post_model_solution3_hds with:
    input:
        rules.run_model_solution3.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_3_1_hds",
    params:
        solution=3,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_1/glob_tr",
        var="hds",
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=120,
        constraint='scratch-node',
        mem_mb=112000,
        tasks=64,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution3_hds.out",
use rule post_model_solution3_wtd as post_model_solution4_wtd with:
    input:
        rules.run_model_solution4.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_4_1_wtd",
    params:
        solution=4,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_1/glob_tr",
        var="wtd",
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=120,
        constraint='scratch-node',
        mem_mb=112000,
        tasks=64,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution4_wtd.out",

use rule post_model_solution3_hds as post_model_solution4_hds with:
    input:
        rules.run_model_solution4.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_4_1_hds",
    params:
        solution=4,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_1/glob_tr",
        var="hds",
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=120,
        constraint='scratch-node',
        mem_mb=112000,
        tasks=64,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution4_hds.out",
use rule post_model_solution3_wtd as post_model_solution2_wtd with:
    input:
        rules.run_model_solution2.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_2_1_wtd",
    params:
        solution=2,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_1/glob_tr",
        var="wtd",
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=120,
        constraint='scratch-node',
        mem_mb=112000,
        tasks=64,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution2_wtd.out",

use rule post_model_solution3_hds as post_model_solution2_hds with:
    input:
        rules.run_model_solution2.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_2_1_hds",
    params:
        solution=2,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_1/glob_tr",
        var="hds",
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=120,
        constraint='scratch-node',
        mem_mb=112000,
        tasks=64,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution2_hds.out",
use rule post_model_solution3_wtd as post_model_solution1_wtd with:
    input:
        rules.run_model_solution1.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_1_1_wtd",
    params:
        solution=1,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_1/glob_tr",
        var="wtd",
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=120,
        constraint='scratch-node',
        mem_mb=112000,
        tasks=64,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution1_wtd.out",

use rule post_model_solution3_hds as post_model_solution1_hds with:
    input:
        rules.run_model_solution1.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_1_1_hds",
    params:
        solution=1,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_1/glob_tr",
        var="hds",
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=120,
        constraint='scratch-node',
        mem_mb=112000,
        tasks=64,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution1_hds.out",

rule validation:
    input:
        rules.post_model_solution1_wtd.output.outFile,
        rules.post_model_solution1_hds.output.outFile,
        rules.post_model_solution2_wtd.output.outFile,
        rules.post_model_solution2_hds.output.outFile,
        rules.post_model_solution3_wtd.output.outFile,
        rules.post_model_solution3_hds.output.outFile,
        rules.post_model_solution4_wtd.output.outFile,
        rules.post_model_solution4_hds.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_validation"
    resources:
        slurm_partition='fat_genoa', 
        nodes=1,
        runtime=120,
        mem_mb=112000,
        tasks=32,
        cpus_per_task=1,
        slurm_extra=f"--output={SLURMDIR_TR}/4_post-processing/_validation.out",
    params:
        py_script=f"{RUN_GLOBGM_DIR}/model_tools_src/python/validation/scripts/validation_globgm.py",
        obs_file=f"{RUN_GLOBGM_DIR}/model_tools_src/python/validation/data/observed_gwh_for_ss_val_1960.gpkg",
    shell:
        '''
        sim_dir={MODELROOT_TR}
        _python_script={params.py_script}
        osbserved_shapefile={params.obs_file}

        output_dir=$sim_dir/mf6_post/output_validation
        python $_python_script $output_dir $sim_dir $osbserved_shapefile
        wait
        touch {output.outFile}
        '''
# ################################################################################################
# # RUN REPEATS
# ################################################################################################

use rule run_model_solution3 as run_model_solution3_rep with:
    input:
        rules.validation.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/done_runModels_complete3_1_rep",
    params:
        label=rules.write_model_input_setup.params.label1,
        runType="subRun",
        solution=3,  
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=120,
        mem_mb=336000,
        tasks=32,
        cpus_per_task=1,
        mpi='srun',
        slurm_extra=f"--exclusive --ntasks-per-node=32 --gres=cpu:1 --output={SLURMDIR_TR}/3_run_model/_run_solution_3_rep.out",

use rule run_model_solution4 as run_model_solution4_rep with:
    input:
        rules.validation.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/done_runModels_complete4_1_rep",
    params:
        label=rules.write_model_input_setup.params.label1,
        runType="subRun",
        solution=4,  
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=120,
        mem_mb=336000,
        tasks=32,
        cpus_per_task=1,
        mpi='srun',
        slurm_extra=f"--exclusive --ntasks-per-node=32 --gres=cpu:1 --output={SLURMDIR_TR}/3_run_model/_run_solution_4_rep.out",

use rule run_model_solution2 as run_model_solution2_rep with:
    input:
        rules.validation.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/done_runModels_complete2_1_rep",
    params:
        label=rules.write_model_input_setup.params.label1,
        runType="subRun",
        solution=2,  
    resources:
        slurm_partition='genoa', 
        nodes=3,
        runtime=120,
        mem_mb=336000,
        tasks=96,
        cpus_per_task=1,
        mpi='srun',
        slurm_extra=f"--exclusive --ntasks-per-node=32 --gres=cpu:1 --output={SLURMDIR_TR}/3_run_model/_run_solution_2_rep.out",

use rule run_model_solution1 as run_model_solution1_rep with:
    input:
        rules.validation.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/done_runModels_complete1_1_rep",
    params:
        label=rules.write_model_input_setup.params.label1,
        runType="subRun",
        solution=1,  
    resources:
        slurm_partition='genoa', 
        nodes=7,
        runtime=120,
        mem_mb=336000,
        tasks=224,
        cpus_per_task=1,
        mpi='srun',
        slurm_extra=f"--exclusive --ntasks-per-node=32 --gres=cpu:1 --output={SLURMDIR_TR}/3_run_model/_run_solution_1_rep.out",

use rule post_model_solution3_wtd as post_model_solution3_wtd_rep with:
    input:
        rules.run_model_solution3_rep.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_3_1_wtd_rep",
    params:
        solution=3,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_1/glob_tr",
        var="wtd",
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=120,
        constraint='scratch-node',
        mem_mb=112000,
        tasks=64,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution3_wtd_rep.out",

use rule post_model_solution3_hds as post_model_solution3_hds_rep with:
    input:
        rules.run_model_solution3_rep.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_3_1_hds_rep",
    params:
        solution=3,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_1/glob_tr",
        var="hds",
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=120,
        constraint='scratch-node',
        mem_mb=112000,
        tasks=64,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution3_hds_rep.out",

use rule post_model_solution4_wtd as post_model_solution4_wtd_rep with:
    input:
        rules.run_model_solution4_rep.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_4_1_wtd_rep",
    params:
        solution=4,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_1/glob_tr",
        var="wtd",
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=120,
        constraint='scratch-node',
        mem_mb=112000,
        tasks=64,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution4_wtd_rep.out",

use rule post_model_solution4_hds as post_model_solution4_hds_rep with:
    input:
        rules.run_model_solution4_rep.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_4_1_hds_rep",
    params:
        solution=4,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_1/glob_tr",
        var="hds",
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=120,
        constraint='scratch-node',
        mem_mb=112000,
        tasks=64,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution4_hds_rep.out",
use rule post_model_solution2_wtd as post_model_solution2_wtd_rep with:
    input:
        rules.run_model_solution2_rep.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_2_1_wtd_rep",
    params:
        solution=2,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_1/glob_tr",
        var="wtd",
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=120,
        constraint='scratch-node',
        mem_mb=112000,
        tasks=64,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution2_wtd_rep.out",
use rule post_model_solution2_hds as post_model_solution2_hds_rep with:
    input:
        rules.run_model_solution2_rep.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_2_1_hds_rep",
    params:
        solution=2,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_1/glob_tr",
        var="hds",
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=120,
        constraint='scratch-node',
        mem_mb=112000,
        tasks=64,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution2_hds_rep.out",
use rule post_model_solution1_wtd as post_model_solution1_wtd_rep with:
    input:
        rules.run_model_solution1_rep.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_1_1_wtd_rep",
    params:
        solution=1,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_1/glob_tr",
        var="wtd",
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=120,
        constraint='scratch-node',
        mem_mb=112000,
        tasks=64,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution1_wtd_rep.out",
use rule post_model_solution1_hds as post_model_solution1_hds_rep with:
    input:
        rules.run_model_solution1_rep.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_post_1_1_hds_rep",
    params:
        solution=1,
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_1/glob_tr",
        var="hds",
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=120,
        constraint='scratch-node',
        mem_mb=112000,
        tasks=64,
        cpus_per_task=1,
        slurm_extra=f" --output={SLURMDIR_TR}/4_post-processing/_post_model_solution1_hds_rep.out",

use rule validation as validation_rep with:
    input:
        rules.post_model_solution1_wtd_rep.output.outFile,
        rules.post_model_solution1_hds_rep.output.outFile,
        rules.post_model_solution2_wtd_rep.output.outFile,
        rules.post_model_solution2_hds_rep.output.outFile,
        rules.post_model_solution3_wtd_rep.output.outFile,
        rules.post_model_solution3_hds_rep.output.outFile,
        rules.post_model_solution4_wtd_rep.output.outFile,
        rules.post_model_solution4_hds_rep.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/4_post-processing/done_validation_rep"
    resources:
        slurm_partition='fat_genoa', 
        nodes=1,
        runtime=120,
        mem_mb=112000,
        tasks=32,
        cpus_per_task=1,
        slurm_extra=f"--output={SLURMDIR_TR}/4_post-processing/_validation_rep.out",
    params:
        py_script=f"{RUN_GLOBGM_DIR}/model_tools_src/python/validation/scripts/validation_globgm.py",
        obs_file=f"{RUN_GLOBGM_DIR}/model_tools_src/python/validation/data/observed_gwh_for_ss_val_1960.gpkg",