#!/bin/bash -l
# create_environment() {
#     # Name of the environment
#     local ENV_NAME="globgm"

#     # Check if the environment exists
#     if mamba env list | grep -q "$ENV_NAME"; then
#         # Delete the existing environment
#         yes | mamba env remove -n "$ENV_NAME"
#     fi

#     # Create a new environment with the same name
#     yes | mamba create -n "$ENV_NAME" python=3.10 requests pcraster netcdf4 cdo beautifulsoup4 \
#                                                  tqdm six nco python-wget xarray dask zarr bottleneck
#     pip install zappend
# }
# create_environment &
# wait && mamba activate globgm

####################################################################################################
# USER DEFINED OPTIONS #                                                                           # 
# simulations=("gfdl-esm4" "gswp3-w5e5" "ipsl-cm6a-lr" "mpi-esm1-2-hr" "mri-esm2-0" "ukesm1-0-ll") #
####################################################################################################
simulations=("gswp3-w5e5")
period=("historical")
solution=("3")

for simulation in "${simulations[@]}"; do
    model_job_scripts=$(realpath ./globgm/model_job_scripts)
    mkdir -p ./output

    ####################
    # RUN STEADY STATE #
    ####################
    modelRoot=./output/$simulation/$period/ss
    slurmDir_ss=$modelRoot/slurm_logs/ss

    mkdir -p $modelRoot
    modelRoot=$(realpath ./output/$simulation/$period/ss)

    #copy globgm input files ino simulation folder
    # cp -r $(realpath ./globgm/) $modelRoot 

    # copy input data from eejit 
    # bash $model_job_scripts/_1_download_input/copyFiles.sh $modelRoot

    # # Step 0: Preprocess steady state data pcrglobwb data
    # mkdir -p $slurmDir_ss/_2_preprocess_pcrglobwb
    # ss_preprocess_script=$model_job_scripts/_2_preprocess_pcrglobwb/2_preprocess_pcrglobwb_ss.slurm
    # sbatch -o $slurmDir_ss/_2_preprocess_pcrglobwb/_2_preprocess_pcrglobwb.out $ss_preprocess_script $modelRoot
    
    # Step 1: 1_write_tiled_parameter_data
    # mkdir -p $slurmDir_ss/1_write_tiled_parameter_data
    # ss_writeTiled_script=$model_job_scripts/1_write_tiled_parameter_data/steady-state/ss.slurm
    # sbatch -o $slurmDir_ss/1_write_tiled_parameter_data/ss_write_tiles_%a.out --array=1-163:3 $ss_writeTiled_script $modelRoot

    # # Step 2: 2_prep_model_part
    # mkdir -p $slurmDir_ss/2_prepare_model_partitioning
    # ss_prep_mod_part_script=$model_job_scripts/2_prepare_model_partitioning/02_prep_model_part.slurm
    # sbatch -o $slurmDir_ss/2_prepare_model_partitioning/02_prep_model_part.out $ss_prep_mod_part_script $modelRoot
    
    # # Step 3: 03_part_write_mod_input
    # mkdir -p $slurmDir_ss/3_partition_and_write_model_input
    # ss_write_input_script=$model_job_scripts/3_partition_and_write_model_input/steady-state/03_part_write_mod_input.slurm
    # sbatch -o $slurmDir_ss/3_partition_and_write_model_input/3_partition_and_write_model_input.out $ss_write_input_script $modelRoot

    #Step 4: 04_run_globgm
    # mkdir -p $slurmDir_ss/4_run_model
    # run_script_ss=$model_job_scripts/4_run_model/steady-state/mf6_s0${solution}_ss.slurm
    # sbatch -o $slurmDir_ss/4_run_model/4_run_globgm${solution}.out $run_script_ss $modelRoot

    # Step 5: post-process
    # mkdir -p $slurmDir_ss/5_post-processing
    # run_script_post_ss=$model_job_scripts/5_post-processing/steady-state/05_post_globgm_ss.slurm
    # sbatch -o $slurmDir_ss/5_post-processing/5_post_globgm_${solution}.out $run_script_post_ss $modelRoot $solution

    #Step 6: Create Zarr
    # mkdir -p $slurmDir_ss/6_create_zarr
    # run_create_zarr_ss=$model_job_scripts/6_create_zarr/06_create_zarr_ss.slurm
    # sbatch -o $slurmDir_ss/6_create_zarr/6_create_zarr_ss_${solution}.out $run_create_zarr_ss $modelRoot $solution

    ###################
    # Run transient   #
    ###################
    # modelRoot=$(realpath ./output/$simulation/$period/tr)

    # slurmDir_tr=$modelRoot/slurm_logs/tr
    # mkdir -p $slurmDir_tr

    #copy input data from eejit 
    # bash $model_job_scripts/_1_download_input/copyFiles.sh $modelRoot

    # Step 0: Preprocess steady state data pcrglobwb data
    # mkdir -p $slurmDir_tr/_2_preprocess_pcrglobwb
    # tr_preprocess_script=$model_job_scripts/_2_preprocess_pcrglobwb/2_preprocess_pcrglobwb_tr.slurm
    # bash $tr_preprocess_script $modelRoot $slurmDir_tr/_2_preprocess_pcrglobwb

    # Step 1: 1_write_tiled_parameter_data
    #TODO watchout for the steady state discharge and recharge file is hard coded and wont be flexible between simulations
    # mkdir -p $slurmDir_tr/1_write_tiled_parameter_data
    # tr_writeTiled_script=$model_job_scripts/1_write_tiled_parameter_data/transient/tr.slurm
    # sbatch -o $slurmDir_tr/1_write_tiled_parameter_data/tr_write_tiles_%a.out --array=1-163:3 $tr_writeTiled_script $modelRoot

    # Step 2: 2_prep_model_part
    # mkdir -p $slurmDir_tr/2_prepare_model_partitioning
    # tr_prep_mod_part_script=$model_job_scripts/2_prepare_model_partitioning/02_prep_model_part.slurm
    # sbatch -o $slurmDir_tr/2_prepare_model_partitioning/02_prep_model_part.out $tr_prep_mod_part_script $modelRoot

    # Step 3: 03_part_write_mod_input
    # mkdir -p $slurmDir_tr/3_partition_and_write_model_input
    # tr_write_input_script=$model_job_scripts/3_partition_and_write_model_input/transient/03_part_write_mod_input.slurm
    # sbatch -o $slurmDir_tr/3_partition_and_write_model_input/3_partition_and_write_model_input.out $tr_write_input_script $modelRoot

    #Step 4: 04_run_globgm
    # mkdir -p $slurmDir_tr/4_run_model
    # run_script_tr=$model_job_scripts/4_run_model/transient/mf6_s0${solution}_tr.slurm
    # sbatch -o $slurmDir_tr/4_run_model/4_run_globgm_${solution}.out $run_script_tr $modelRoot

    # Step 5: post-process
    # mkdir -p $slurmDir_tr/5_post-processing
    # run_script_post_tr=$model_job_scripts/5_post-processing/transient/05_post_globgm_tr.slurm
    # sbatch -o $slurmDir_tr/5_post-processing/5_post_globgm_${solution}.out $run_script_post_tr $modelRoot $solution

    #Step 6: Create Zarr
    # mkdir -p $slurmDir_tr/6_create_zarr
    # run_create_zarr_tr=$model_job_scripts/6_create_zarr/06_create_zarr_tr.slurm
    # # bash $run_create_zarr_tr $modelRoot $solution
    # sbatch -o $slurmDir_tr/6_create_zarr/6_create_zarr_tr_${solution}.out $run_create_zarr_tr $modelRoot $solution

#TODO add the zarr for tranisnet form eejit 
#TODO add the new zarr stuff into the steady-state pre-processing 
done
