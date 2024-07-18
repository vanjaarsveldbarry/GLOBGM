#!/bin/bash -l

# create_environment() {
    # # Name of the environment
    # local ENV_NAME="globgm"

    # # Check if the environment exists
    # if mamba env list | grep -q "$ENV_NAME"; then
    #     # Delete the existing environment
    #     yes | mamba env remove -n "$ENV_NAME"
    # fi

    # Create a new environment with the same name
    # yes | mamba create -n "$ENV_NAME" python=3.10 pcraster netcdf4 cdo nco six xarray dask zarr bottleneck
                                                #  tqdm six nco python-wget xarray dask zarr bottleneck \
                                                #  pyinterp 
# }
# create_environment
# wait

####################################################################################################
# USER DEFINED OPTIONS #                                                                           # 
# simulations=("gfdl-esm4" "gswp3-w5e5" "ipsl-cm6a-lr" "mpi-esm1-2-hr" "mri-esm2-0" "ukesm1-0-ll") #
####################################################################################################
simulations=("gfdl-esm4")
outputDirectory=/projects/0/einf4705/workflow/output

for simulation in "${simulations[@]}"; do
    model_job_scripts=$(realpath ./)
    modelRoot=$outputDirectory/$simulation
    ssModelRoot=$modelRoot/ss
    slurmDir_ss=$ssModelRoot/slurm_logs 
    mkdir -p $ssModelRoot $slurmDir_ss/1_prepare_model_partitioning $slurmDir_ss/2_write_model_input $slurmDir_ss/3_run_model $slurmDir_ss/4_post-processing

    ####################
    # RUN STEADY STATE #
    ####################
    #TODO ADD JOB DEPENDENCY# jobid=$(sbatch -o $slurmDir_ss/1_prepare_model_partitioning/1_prep_model_part.out $prep_mod_part_script $ssModelRoot | awk '{print $4}')

    #copy globgm input files into simulation folder
    # cp -r $(realpath ../model_input) $ssModelRoot

    # Step 1: 1_prepare_model_partitioning
    # prep_mod_ss=$model_job_scripts/1_prepare_model_partitioning/01_prep_model_part.slurm
    # sbatch -o $slurmDir_ss/1_prepare_model_partitioning/1_prep_model_part.out $prep_mod_ss $ssModelRoot

    # Step 2: 2_write_model_input
    # sbatch -o $slurmDir_ss/2_write_model_input/_setup_ss.out $model_job_scripts/2_write_model_input/ss/_setup_ss.slurm $ssModelRoot
    # sbatch -o $slurmDir_ss/2_write_model_input/_writeModels_ss.out $model_job_scripts/2_write_model_input/ss/_writeModels_ss.slurm $ssModelRoot
    
    # Step 3: 3_run_model
    # sbatch -o $slurmDir_ss/3_run_model/3_run_globgm_s01.out $model_job_scripts/3_run_model/steady-state/mf6_s01_ss.slurm $ssModelRoot $model_job_scripts $slurmDir_ss
    # sbatch -o $slurmDir_ss/3_run_model/3_run_globgm_s02.out $model_job_scripts/3_run_model/steady-state/mf6_s02_ss.slurm $ssModelRoot $model_job_scripts $slurmDir_ss
    # sbatch -o $slurmDir_ss/3_run_model/3_run_globgm_s03.out $model_job_scripts/3_run_model/steady-state/mf6_s03_ss.slurm $ssModelRoot $model_job_scripts $slurmDir_ss
    # sbatch -o $slurmDir_ss/3_run_model/3_run_globgm_s04.out $model_job_scripts/3_run_model/steady-state/mf6_s04_ss.slurm $ssModelRoot $model_job_scripts $slurmDir_ss

    ###############################
    # Run transient historical    #
    ###############################
    start_year=2012
    end_year=2014
    trModelRoot=$modelRoot/tr_historical
    slurmDir_tr=$trModelRoot/slurm_logs
    steps=1
    nSpin=1
    mkdir -p $slurmDir_tr/1_prepare_model_partitioning $slurmDir_tr/2_write_model_input $slurmDir_tr/3_run_model $slurmDir_tr/4_post-processing
    
    # copy globgm input files ino simulation folder
    cp -r $(realpath ../model_input) $trModelRoot

    # Step 1: prepare_model_partitioning
    # sbatch -o $slurmDir_tr/1_prepare_model_partitioning/1_prep_model_part.out $model_job_scripts/1_prepare_model_partitioning/01_prep_model_part.slurm $trModelRoot

    # Step 2: 2_write_model_input (Setup model and write tiles)
    # sbatch -o $slurmDir_tr/2_write_model_input/_writeInput.out $model_job_scripts/2_write_model_input/tr/_writeInput.slurm $trModelRoot $slurmDir_tr $start_year $end_year

    _writeModels_tr=$model_job_scripts/2_write_model_input/tr/_writeModels_tr.slurm
    for ((year=start_year; year<=end_year; year+=steps)); do
        yearStart=$year
        yearEnd=$((year+steps-1))
        if [ $yearEnd -gt $end_year ]; then
            yearEnd=$end_year
        fi
        #   jobid=$(sbatch -o $slurmDir_tr/2_write_model_input/_setup${yearEnd}.out $model_job_scripts/2_write_model_input/tr/_setup_tr.slurm $trModelRoot $yearStart $yearEnd $nSpin| awk '{print $4}')
        #   sbatch --dependency=afterok:$jobid -o $slurmDir_tr/2_write_model_input/_${yearEnd}wMod_1_%a.out --array=1 $_writeModels_tr $trModelRoot $yearStart $yearEnd 1
        #   sbatch --dependency=afterok:$jobid -o $slurmDir_tr/2_write_model_input/_${yearEnd}wMod_2_%a.out --array=1 $_writeModels_tr $trModelRoot $yearStart $yearEnd 2
        #   sbatch --dependency=afterok:$jobid -o $slurmDir_tr/2_write_model_input/_${yearEnd}wMod_3_%a.out --array=1 $_writeModels_tr $trModelRoot $yearStart $yearEnd 3
        #   sbatch --dependency=afterok:$jobid -o $slurmDir_tr/2_write_model_input/_${yearEnd}wMod_4_%a.out --array=1 $_writeModels_tr $trModelRoot $yearStart $yearEnd 4
        
        
        #   jobid=$(sbatch -o $slurmDir_tr/2_write_model_input/_setup${yearEnd}.out $model_job_scripts/2_write_model_input/tr/_setup_tr.slurm $trModelRoot $yearStart $yearEnd $nSpin| awk '{print $4}')
        #   wait
        #   sbatch -o $slurmDir_tr/2_write_model_input/_${yearEnd}wMod_1_%a.out --array=1 $_writeModels_tr $trModelRoot $yearStart $yearEnd 1
        #   sbatch -o $slurmDir_tr/2_write_model_input/_${yearEnd}wMod_2_%a.out --array=1 $_writeModels_tr $trModelRoot $yearStart $yearEnd 2
        #   sbatch -o $slurmDir_tr/2_write_model_input/_${yearEnd}wMod_3_%a.out --array=1 $_writeModels_tr $trModelRoot $yearStart $yearEnd 3
        #   sbatch -o $slurmDir_tr/2_write_model_input/_${yearEnd}wMod_4_%a.out --array=1 $_writeModels_tr $trModelRoot $yearStart $yearEnd 4
    done

    # # Step 3: 3_run_model
    # sbatch -o $slurmDir_tr/3_run_model/3_run_globgm_1.out $model_job_scripts/3_run_model/transient/mf6_s01_tr.slurm $trModelRoot $model_job_scripts $slurmDir_tr $start_year $end_year
    # sbatch -o $slurmDir_tr/3_run_model/3_run_globgm_2.out $model_job_scripts/3_run_model/transient/mf6_s02_tr.slurm $trModelRoot $model_job_scripts $slurmDir_tr $start_year $end_year
    # sbatch -o $slurmDir_tr/3_run_model/3_run_globgm_3.out $model_job_scripts/3_run_model/transient/mf6_s03_tr.slurm $trModelRoot $model_job_scripts $slurmDir_tr $start_year $end_year
    bash $model_job_scripts/3_run_model/transient/mf6_s03_tr.slurm $trModelRoot $model_job_scripts $slurmDir_tr $start_year $end_year
    # sbatch -o $slurmDir_tr/3_run_model/3_run_globgm_4.out $model_job_scripts/3_run_model/transient/mf6_s04_tr.slurm $trModelRoot $model_job_scripts $slurmDir_tr $start_year $end_year
done