localrules: setup_simulation,prepare_model_partitioning,write_model_input_setup,all

import os
SIMULATION = config["simulation"]
OUTPUTDIRECTORY = config["outputDirectory"]
RUN_GLOBGM_DIR = config["run_globgm_dir"]
DATA_DIR = config["data_dir"]
CALIB_STR = config["calib_str"]

MODELROOT_SS=f"{OUTPUTDIRECTORY}/{SIMULATION}/ss"
SLURMDIR_SS=f"{MODELROOT_SS}/slurm_logs"

rule all:
    input:
        f"{SLURMDIR_SS}/4_post-processing/done_post_process_solution_1",
        f"{SLURMDIR_SS}/4_post-processing/done_post_process_solution_2",
        f"{SLURMDIR_SS}/4_post-processing/done_post_process_solution_3",
        f"{SLURMDIR_SS}/4_post-processing/done_post_process_solution_4",


rule setup_simulation:
    output:
        outFile=f"{SLURMDIR_SS}/1_prepare_model_partitioning/done_setup_simulation"
    params:
        dir1 = MODELROOT_SS,
        dir2 = f"{SLURMDIR_SS}/1_prepare_model_partitioning",
        dir3 = f"{SLURMDIR_SS}/2_write_model_input",
        dir4 = f"{SLURMDIR_SS}/3_run_model",
        dir5 = f"{SLURMDIR_SS}/4_post-processing",

        model_input_dir = f"{RUN_GLOBGM_DIR}/model_input",
        modelroot_ss = MODELROOT_SS,
    shell:
        '''
        mkdir -p {params.dir1} {params.dir2} {params.dir3} {params.dir4} {params.dir5}
        touch {output.outFile}
        '''

rule prepare_model_partitioning:
    input:
        rules.setup_simulation.output.outFile
    output:
        outFile=f"{SLURMDIR_SS}/1_prepare_model_partitioning/done_prepare_model_partitioning"
    shell:
        '''
        top={DATA_DIR}/globgm_input/clonemap_tiles/tile_163.txt
        til={DATA_DIR}/globgm_input/clonemap_tiles/idf/tile_
        exe={DATA_DIR}/_bin/datamap_070224

        cat={DATA_DIR}/globgm_input/inp_idf/hybas_lake_lev08_v1c_filt.idf
        d={DATA_DIR}/globgm_input/inp_idf/d_top_2.idf

        cd {MODELROOT_SS}

        mkdir -p ./mf6_map/
        cd ./mf6_map/

        ${{exe}} 1 './map_glob' ${{cat}} ${{d}} ${{top}} ${{til}}
        wait 
        touch {output.outFile}
        '''

rule write_model_input_setup:
    input:
        rules.prepare_model_partitioning.output.outFile
    output:
        outFile=f"{SLURMDIR_SS}/2_write_model_input/done_write_model_input_setup"
    shell:
        '''
        modelRoot={MODELROOT_SS}
        data_dir={DATA_DIR}
        run_globgm_dir={RUN_GLOBGM_DIR}

        mkdir -p $modelRoot/model_input
        cp -r $run_globgm_dir/model_input $modelRoot

        inpdir=$modelRoot/model_input/2_partition_and_write_model_input/steady-state
        inpmod=mf6_mod_ss.inp
        inpexe=mf6ggm_ss.inp

        moddir=$modelRoot/mf6_mod
        mkdir -p $moddir

        cp ${{inpdir}}/${{inpmod}} ${{moddir}}/${{inpmod}}
        cp ${{inpdir}}/${{inpexe}} ${{moddir}}/${{inpexe}}

        yodaInput=$data_dir/globgm_input
        globgm_dir=$modelRoot
        sed -i "s|{{yoda_input}}|${{yodaInput}}|g" ${{moddir}}/${{inpmod}}
        sed -i "s|{{globgm_dir}}|${{moddir}}|g" ${{moddir}}/${{inpmod}}
        wait

        exe=$data_dir/_bin/mf6ggm_181121
        cd ${{moddir}}
        ${{exe}} ${{inpexe}} 0 
        wait 

        touch {output.outFile}
        '''

rule write_model_input:
    input:
        rules.write_model_input_setup.output.outFile
    output:
        outFile=f"{SLURMDIR_SS}/2_write_model_input/done_write_model_input"
    resources:
        slurm_partition='genoa', 
        runtime=720,
        constraint='scratch-node',
        mem_mb=336000,
        cpus_per_task=1,
        tasks=192,
        nodes=1,
        slurm_extra=f"--exclusive --output={SLURMDIR_SS}/2_write_model_input/_writeModels_ss.out",
        mpi='mpirun'
    shell:
        '''
        set +u; source ${{HOME}}/.bashrc && mamba activate globgm_pcraster ; set -u

        #Write tiles input
        modelRoot={MODELROOT_SS}
        data_dir={DATA_DIR}
        calib_str={CALIB_STR}

        module load 2023
        module load mpifileutils/0.11.1-gompi-2023a
        {resources.mpi} -np 160 dcp --progress 5 $data_dir/globgm_input $TMPDIR
        wait
        ls -lah $TMPDIR

        simulation=$(basename $(dirname $modelRoot))

        cmip6InputFolder=$data_dir/cmip6_input/$simulation/historical_natural
        forcingDir=$TMPDIR/forcing_input
        _pcr_calc_files=$TMPDIR/globgm_input/_pcrcalc_files
        mkdir -p $forcingDir

        model_input=$(realpath $modelRoot/model_input/2_partition_and_write_model_input)
        OUT_DIR=$TMPDIR/input_map/steady-state
        IN_DIR=$TMPDIR/globgm_input
        pcrlobwbDir=$(realpath ../model_tools_src/python/pcr-globwb)

        #SUBMODELS INPUT
        exe=$data_dir/_bin/mf6ggm_181121
        inpmod=mf6_mod_ss.inp
        inpexe=mf6ggm_ss.inp
        moddir=$modelRoot/mf6_mod
        yodaInput=$TMPDIR/globgm_input
        inpdir=$(realpath $modelRoot/model_input/2_partition_and_write_model_input/steady-state)
        globgmDir=$TMPDIR

        # Step 1 preprocess the 5 arcmin netcdf data to 30 arcseconds
        process_gwRecharge(){{
            local tempdir=${{TMPDIR}}/gwRecharge
            local inFile=$(find "$cmip6InputFolder" -type f -name "*gwRecharge*")
            local outFile=$tempdir/average_gwRecharge_m_per_day
            mkdir -p $tempdir

            # Capture the output of cdo showyear
            years_array=($(cdo showyear $inFile))
            first_year=${{years_array[0]}}
            last_year=${{years_array[-1]}}
            cdo -L -f nc4 -setrtoc,-inf,0,0 -setunit,m.day-1 -divc,365.25 -timmean -yearsum -selyear,$first_year/$last_year $inFile $outFile.temp.nc    
            gdal_translate -of GTiff $outFile.temp.nc $outFile.temp.tif
            gdal_translate -of PCRaster ${{outFile}}.temp.tif ${{outFile}}.temp.map
            gdal_translate -of NETCDF ${{outFile}}.temp.map $tempdir/average_gwRecharge_m_per_day.map.nc
            cdo -L -invertlat $tempdir/average_gwRecharge_m_per_day.map.nc $tempdir/average_gwRecharge_m_per_dayTemp.nc
            ncwa -O -a time $tempdir/average_gwRecharge_m_per_dayTemp.nc $tempdir/average_gwRecharge_m_per_day.nc
            mv $tempdir/average_gwRecharge_m_per_day.nc $forcingDir
            rm -r $tempdir
            }}

        process_totalRunoff_to_Discharge() {{
            # Process totalRunoff -> Discharge
            local tempdir=${{TMPDIR}}/discharge
            local inFile=$(find "$cmip6InputFolder" -type f -name "*totalRunoff*")
            local outFile=$tempdir/average_totalRunoff_m_per_day
            mkdir -p $tempdir
            years_array=($(cdo showyear $inFile))
            first_year=${{years_array[0]}}
            last_year=${{years_array[-1]}}
            cdo -L -f nc4 -setunit,m.day-1 -divc,365.25 -timmean -yearsum -selyear,$first_year/$last_year $inFile $outFile.temp.nc
            local info=$(gdalinfo $_pcr_calc_files/cdo_gridarea_30sec.map)
            local xres=$(echo "$info" | grep "Pixel Size" | awk -F'=' '{{print $2}}' | awk -F',' '{{print $1}}' | tr -d '()')
            local yres=$(echo "$info" | grep "Pixel Size" | awk -F'=' '{{print $2}}' | awk -F',' '{{print $2}}' | tr -d '()')
            local ulx=$(echo "$info" | grep "Upper Left"  | awk '{{print $3}}' | tr -d ',' | tr -d '()')
            local uly=$(echo "$info" | grep "Upper Left"  | awk '{{print $4}}' | tr -d ',' | tr -d '()')
            local lrx=$(echo "$info" | grep "Lower Right" | awk '{{print $4}}' | tr -d ',' | tr -d '()')
            local lry=$(echo "$info" | grep "Lower Right" | awk '{{print $5}}' | tr -d ',' | tr -d '()')
            gdalwarp -tr $xres $yres -r bilinear -overwrite -te $ulx $lry $lrx $uly -of GTiff $outFile.temp.nc ${{outFile}}_30sec.tif
            gdal_translate -of PCRaster ${{outFile}}_30sec.tif ${{outFile}}.temp.map

            # Calculate discharge
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
            }}
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
            python deterministic_runner_for_monthly_offline_globgm.py $model_input/steady-state/steady-state_config.ini debug steady-state-only tile_${{num}}-163 $IN_DIR $OUT_DIR $forcingDir $calib_str &
            counter=$((counter+1))
            if [ $counter -eq 29 ]; then
                wait
                counter=0
            fi
        done
        wait
        
        # Copy for post-processing
        for ((i=1; i<=163; i+=1));do
            tile=$(printf "%03d" $i)
            mkdir -p $modelRoot/input_map/steady-state/tile_${{tile}}-163/steady-state_only/maps && cp "${{OUT_DIR}}/tile_${{tile}}-163/steady-state_only/maps/top_uppermost_layer.map" "$modelRoot/input_map/steady-state/tile_${{tile}}-163/steady-state_only/maps" &
        done
        wait

        mkdir -p $moddir
        cp ${{inpdir}}/${{inpmod}} ${{moddir}}/${{inpmod}}
        cp ${{inpdir}}/${{inpexe}} ${{moddir}}/${{inpexe}}

        #REPLACE NECESSARY STRINGS
        sed -i "s|{{yoda_input}}|${{yodaInput}}|g" ${{moddir}}/${{inpmod}}
        sed -i "s|{{globgm_dir}}|${{globgmDir}}|g" ${{moddir}}/${{inpmod}}
        wait

        cd ${{moddir}}

        for ((i=1; i<=384; i+=12)); do
            ii=$((i + 11))
            if [ $ii -gt 384 ]; then
                ii=384
            fi
            ${{exe}} ${{inpexe}} $i $ii &
        done
        wait

        cd $moddir/glob_ss/log
        num_files=$(ls | wc -l)
        [ $num_files -eq 384 ] || {{ echo "Some models are missing"; exit 1; }}
        wait 
        touch {output.outFile}
        '''
rule run_solution_3:
    params:
        solution=3
    input:
        rules.write_model_input.output.outFile
    output:
        outFile=f"{SLURMDIR_SS}/3_run_model/done_run_solution_3"
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=120,
        mem_mb=336000,
        tasks=32,
        cpus_per_task=1,
        mpi='srun',
        slurm_extra=f"--exclusive --ntasks-per-node=32 --gres=cpu:1 --output={SLURMDIR_SS}/3_run_model/_run_solution_3.out",
    shell:
        '''
        module load 2023
        module load OpenMPI/4.1.5-GCC-12.3.0

        modelRoot={MODELROOT_SS}
        data_dir={DATA_DIR}

        dir=$modelRoot/mf6_mod/glob_ss/solutions/run_output/
        exe=$data_dir/_bin/mf6_rel_openmpi-4.1.4-gcc-11.3.0
        nam=s0{params.solution}.par.mfsim.ic_sh0.nam
        startDir=$(pwd)

        cd ${{dir}}
        {resources.mpi} ${{exe}} -s ../run_input/${{nam}}

        wait
        touch {output.outFile}
        '''

rule post_process_solution_3:
    params:
        solution=3
    input:
        rules.run_solution_3.output.outFile
    output:
        outFile=f"{SLURMDIR_SS}/4_post-processing/done_post_process_solution_3"
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=20,
        mem_mb=28000,
        tasks=16,
        slurm_extra=f"--output={SLURMDIR_SS}/4_post-processing/_post_process_solution_3.out",
    shell:
        '''
        modelRoot={MODELROOT_SS}
        solution={params.solution}
        data_dir={DATA_DIR}
        saveDir=$TMPDIR/mf6_post/temp_s0${{solution}}
        mkdir -p $saveDir $modelRoot/mf6_post

        inpdir=$modelRoot/model_input/4_post-processing/steady-state
        zarrScripts=$(realpath ../model_tools_src/python/to_zarr)
        inp_ss=mf6ggm_post_ss.inp
        yodaInput=$data_dir/globgm_input
        exe=$data_dir/_bin/mf6ggmpost_260624

        cp ${{inpdir}}/${{inp_ss}} $saveDir/s0${{solution}}_${{inp_ss}}
        sed -i "s|{{yoda_input}}|${{yodaInput}}|g" $saveDir/s0${{solution}}_${{inp_ss}}
        sed -i "s|{{globgm_dir}}|${{modelRoot}}|g" $saveDir/s0${{solution}}_${{inp_ss}}
        sed -i "s|{{solution}}|${{solution}}|g" $saveDir/s0${{solution}}_${{inp_ss}}
        wait

        cd $saveDir
        ${{exe}} "s0${{solution}}_${{inp_ss}}"
        wait 

        python -u $zarrScripts/createZarr_ss.py $saveDir s0$solution $modelRoot/mf6_post 
        wait
        touch {output.outFile}
        '''

use rule run_solution_3 as run_solution_4 with:
    params:
        solution=4
    input:
        rules.write_model_input.output.outFile
    output:
        outFile=f"{SLURMDIR_SS}/3_run_model/done_run_solution_4"
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=120,
        mem_mb=336000,
        tasks=32,
        cpus_per_task=1,
        mpi='srun',
        slurm_extra=f"--exclusive --ntasks-per-node=32 --gres=cpu:1 --output={SLURMDIR_SS}/3_run_model/_run_solution_4.out",

use rule post_process_solution_3 as post_process_solution_4 with:
    params:
        solution=4
    input:
        rules.run_solution_4.output.outFile
    output:
        outFile=f"{SLURMDIR_SS}/4_post-processing/done_post_process_solution_4"
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=20,
        mem_mb=28000,
        tasks=16,
        slurm_extra=f"--output={SLURMDIR_SS}/4_post-processing/_post_process_solution_4.out",

use rule run_solution_3 as run_solution_2 with:
    params:
        solution=2
    input:
        rules.write_model_input.output.outFile
    output:
        outFile=f"{SLURMDIR_SS}/3_run_model/done_run_solution_2"
    resources:
        slurm_partition='genoa', 
        nodes=3,
        runtime=120,
        mem_mb=336000,
        tasks=96,
        cpus_per_task=1,
        mpi='srun',
        slurm_extra=f"--exclusive --ntasks-per-node=32 --gres=cpu:1 --output={SLURMDIR_SS}/3_run_model/_run_solution_2.out",

use rule post_process_solution_3 as post_process_solution_2 with:
    params:
        solution=2
    input:
        rules.run_solution_2.output.outFile
    output:
        outFile=f"{SLURMDIR_SS}/4_post-processing/done_post_process_solution_2"
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=20,
        mem_mb=28000,
        tasks=16,
        slurm_extra=f"--output={SLURMDIR_SS}/4_post-processing/_post_process_solution_2.out",

use rule run_solution_3 as run_solution_1 with:
    params:
        solution=1
    input:
        rules.write_model_input.output.outFile
    output:
        outFile=f"{SLURMDIR_SS}/3_run_model/done_run_solution_1"
    resources:
        slurm_partition='genoa', 
        nodes=7,
        runtime=120,
        mem_mb=336000,
        tasks=224,
        cpus_per_task=1,
        mpi='srun',
        slurm_extra=f"--exclusive --ntasks-per-node=32 --gres=cpu:1 --output={SLURMDIR_SS}/3_run_model/_run_solution_1.out",

use rule post_process_solution_3 as post_process_solution_1 with:
    params:
        solution=1
    input:
        rules.run_solution_1.output.outFile
    output:
        outFile=f"{SLURMDIR_SS}/4_post-processing/done_post_process_solution_1"
    resources:
        slurm_partition='genoa', 
        nodes=1,
        runtime=20,
        mem_mb=28000,
        tasks=16,
        slurm_extra=f"--output={SLURMDIR_SS}/4_post-processing/_post_process_solution_1.out",


