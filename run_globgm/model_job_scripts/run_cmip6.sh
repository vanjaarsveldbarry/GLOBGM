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
simulations=("gfdl-esm4")
# period=("historical")
# solution=("3")
outputDirectory=/projects/0/einf4705/workflow/output

# if [[ $period == *"historical"* ]]; then

#     if [[ $simulations == *"gswp3-w5e5"* ]]; then
#         start_year=1960
#         end_year=1961
#     else
#         start_year=2013
#         end_year=2014
#     fi
# else
#         start_year=2015
#         end_year=2100
# fi

#TODO seperate the preprocessing according to tiles that match the solution spaces, do tis by changing the model folder input names 
#TODO do I really need two ini files for the 1_wite_tiled_parameter_data step?
#TODO drop the islands with no data by seeing if they have a value of 0 or nan i n the steady state results
for simulation in "${simulations[@]}"; do
    model_job_scripts=$(realpath ./)
    mkdir -p $outputDirectory/$simulation
    modelRoot=$outputDirectory/$simulation

    #copy input data from eejit 
    #TODO replace this with a static location on snellius when it is available
    # bash $model_job_scripts/_1_download_input/copyFiles.sh $outputDirectory


    ####################
    # RUN STEADY STATE #
    ####################
    #TODO this shoud be using naturalised data but we dont have that
    ssModelRoot=$modelRoot/ss
    slurmDir_ss=$ssModelRoot/slurm_logs
    mkdir -p $ssModelRoot

    # #copy globgm input files ino simulation folder
    # cp -r $(realpath ../model_input/) $ssModelRoot

    # # Step 0: Preprocess steady state data pcrglobwb data
    # mkdir -p $slurmDir_ss/_2_preprocess_pcrglobwb
    # ss_preprocess_script=$model_job_scripts/_2_preprocess_pcrglobwb/2_preprocess_pcrglobwb_ss.slurm
    # sbatch -o $slurmDir_ss/_2_preprocess_pcrglobwb/_2_preprocess_pcrglobwb.out $ss_preprocess_script $ssModelRoot
    
    # # Step 1: 1_write_tiled_parameter_data
    # mkdir -p $slurmDir_ss/1_write_tiled_parameter_data
    # ss_writeTiled_script=$model_job_scripts/1_write_tiled_parameter_data/steady-state/ss.slurm
    # sbatch -o $slurmDir_ss/1_write_tiled_parameter_data/ss_write_tiles_%a.out --array=1-163:3 $ss_writeTiled_script $ssModelRoot

    # # Step 2: 2_prep_model_part
    # mkdir -p $slurmDir_ss/2_prepare_model_partitioning
    # ss_prep_mod_part_script=$model_job_scripts/2_prepare_model_partitioning/02_prep_model_part.slurm
    # sbatch -o $slurmDir_ss/2_prepare_model_partitioning/02_prep_model_part.out $ss_prep_mod_part_script $ssModelRoot
    
    # # Step 3: 03_part_write_mod_input
    # mkdir -p $slurmDir_ss/3_partition_and_write_model_input
    # ss_write_input_script=$model_job_scripts/3_partition_and_write_model_input/steady-state/03_part_write_mod_input.slurm
    # sbatch -o $slurmDir_ss/3_partition_and_write_model_input/3_partition_and_write_model_input.out $ss_write_input_script $ssModelRoot

    #Step 4: 04_run_globgm
    # mkdir -p $slurmDir_ss/4_run_model
    # run_script_ss1=$model_job_scripts/4_run_model/steady-state/mf6_s01_ss.slurm
    # sbatch -o $slurmDir_ss/4_run_model/4_run_globgm_s01.out $run_script_ss1 $ssModelRoot
    # run_script_ss2=$model_job_scripts/4_run_model/steady-state/mf6_s02_ss.slurm
    # sbatch -o $slurmDir_ss/4_run_model/4_run_globgm_s02.out $run_script_ss2 $ssModelRoot
    # run_script_ss3=$model_job_scripts/4_run_model/steady-state/mf6_s03_ss.slurm
    # sbatch -o $slurmDir_ss/4_run_model/4_run_globgm_s03.out $run_script_ss3 $ssModelRoot
    # run_script_ss4=$model_job_scripts/4_run_model/steady-state/mf6_s04_ss.slurm
    # sbatch -o $slurmDir_ss/4_run_model/4_run_globgm_s04.out $run_script_ss4 $ssModelRoot

    # Step 5: post-process
    # mkdir -p $slurmDir_ss/5_post-processing
    # run_script_post_ss=$model_job_scripts/5_post-processing/steady-state/05_post_globgm_ss.slurm
    # sbatch -o $slurmDir_ss/5_post-processing/5_post_globgm_1.out $run_script_post_ss $ssModelRoot 1
    # sbatch -o $slurmDir_ss/5_post-processing/5_post_globgm_2.out $run_script_post_ss $ssModelRoot 2
    # sbatch -o $slurmDir_ss/5_post-processing/5_post_globgm_3.out $run_script_post_ss $ssModelRoot 3
    # sbatch -o $slurmDir_ss/5_post-processing/5_post_globgm_4.out $run_script_post_ss $ssModelRoot 4


    #Step 6: Create Zarr
    # mkdir -p $slurmDir_ss/6_create_zarr
    # run_create_zarr_ss=$model_job_scripts/6_create_zarr/06_create_zarr_ss.slurm
    # sbatch -o $slurmDir_ss/6_create_zarr/6_create_zarr_ss_1.out $run_create_zarr_ss $ssModelRoot 1
    # sbatch -o $slurmDir_ss/6_create_zarr/6_create_zarr_ss_2.out $run_create_zarr_ss $ssModelRoot 2
    # sbatch -o $slurmDir_ss/6_create_zarr/6_create_zarr_ss_3.out $run_create_zarr_ss $ssModelRoot 3
    # sbatch -o $slurmDir_ss/6_create_zarr/6_create_zarr_ss_4.out $run_create_zarr_ss $ssModelRoot 4

    ###############################
    # Run transient historical    #
    ###############################
    start_year=2013
    end_year=2014
    trModelRoot=$modelRoot/tr_historical

    slurmDir_tr=$trModelRoot/slurm_logs
    mkdir -p $slurmDir_tr

    # # copy globgm input files ino simulation folder
    cp -r $(realpath ../model_input/) $trModelRoot 

    # # Step 0: Preprocess steady state data pcrglobwb data
    # mkdir -p $slurmDir_tr/_2_preprocess_pcrglobwb
    # tr_preprocess_script=$model_job_scripts/_2_preprocess_pcrglobwb/2_preprocess_pcrglobwb_tr.slurm
    # bash $tr_preprocess_script $trModelRoot $slurmDir_tr/_2_preprocess_pcrglobwb $start_year $end_year

    # Step 1: 1_write_tiled_parameter_data
    # TODO check the ini file dos it even need the steady state netcdf's?
    # mkdir -p $slurmDir_tr/1_write_tiled_parameter_data
    # tr_writeTiled_script=$model_job_scripts/1_write_tiled_parameter_data/transient/tr.slurm
    # sbatch -o $slurmDir_tr/1_write_tiled_parameter_data/tr_write_tiles_%a.out --array=1-163:4 $tr_writeTiled_script $trModelRoot $start_year $end_year

    # Step 2: 2_prep_model_part
    # mkdir -p $slurmDir_tr/2_prepare_model_partitioning
    # tr_prep_mod_part_script=$model_job_scripts/2_prepare_model_partitioning/02_prep_model_part.slurm
    # sbatch -o $slurmDir_tr/2_prepare_model_partitioning/02_prep_model_part.out $tr_prep_mod_part_script $trModelRoot

    # Step 3: 03_part_write_mod_input
    # mkdir -p $slurmDir_tr/3_partition_and_write_model_input
    # tr_write_input_script=$model_job_scripts/3_partition_and_write_model_input/transient/03_part_write_mod_input.slurm
    # bash $tr_write_input_script $trModelRoot $start_year $end_year
    # sbatch -o $slurmDir_tr/3_partition_and_write_model_input/3_partition_and_write_model_input.out $tr_write_input_script $trModelRoot $start_year $end_year

    #Step 4: 04_run_globgm
    # mkdir -p $slurmDir_tr/4_run_model
    # run_script_tr1=$model_job_scripts/4_run_model/transient/mf6_s01_tr.slurm
    # sbatch -o $slurmDir_tr/4_run_model/4_run_globgm_1.out $run_script_tr1 $trModelRoot
    # run_script_tr2=$model_job_scripts/4_run_model/transient/mf6_s02_tr.slurm
    # sbatch -o $slurmDir_tr/4_run_model/4_run_globgm_2.out $run_script_tr2 $trModelRoot
    # run_script_tr3=$model_job_scripts/4_run_model/transient/mf6_s03_tr.slurm
    # sbatch -o $slurmDir_tr/4_run_model/4_run_globgm_3.out $run_script_tr3 $trModelRoot
    # run_script_tr4=$model_job_scripts/4_run_model/transient/mf6_s04_tr.slurm
    # sbatch -o $slurmDir_tr/4_run_model/4_run_globgm_4.out $run_script_tr4 $trModelRoot

    # Step 5: post-process
    # TODO this is slow maybe excluisve will help
    # #TODO  you could also split the jobs to do one variabel per job this cutting the run times here in half
    # mkdir -p $slurmDir_tr/5_post-processing
    # run_script_post_tr=$model_job_scripts/5_post-processing/transient/05_post_globgm_tr.slurm
    # sbatch -o $slurmDir_tr/5_post-processing/5_post_globgm_1.out $run_script_post_tr $trModelRoot 1 $start_year $end_year
    # sbatch -o $slurmDir_tr/5_post-processing/5_post_globgm_2.out $run_script_post_tr $trModelRoot 2 $start_year $end_year
    # sbatch -o $slurmDir_tr/5_post-processing/5_post_globgm_3.out $run_script_post_tr $trModelRoot 3 $start_year $end_year
    # sbatch -o $slurmDir_tr/5_post-processing/5_post_globgm_4.out $run_script_post_tr $trModelRoot 4 $start_year $end_year

    #Step 6: Create Zarr
    #TODO its only working for one year now so watch out, how do I make it flexible?
    mkdir -p $slurmDir_tr/6_create_zarr
    run_create_zarr_tr=$model_job_scripts/6_create_zarr/06_create_zarr_tr.slurm
    # sbatch -o $slurmDir_tr/6_create_zarr/6_create_zarr_tr_1.out $run_create_zarr_tr $trModelRoot 1 $start_year $end_year
    # sbatch -o $slurmDir_tr/6_create_zarr/6_create_zarr_tr_2.out $run_create_zarr_tr $trModelRoot 2 $start_year $end_year
    # sbatch -o $slurmDir_tr/6_create_zarr/6_create_zarr_tr_3.out $run_create_zarr_tr $trModelRoot 3 $start_year $end_year
    # sbatch -o $slurmDir_tr/6_create_zarr/6_create_zarr_tr_4.out $run_create_zarr_tr $trModelRoot 4 $start_year $end_year
done
