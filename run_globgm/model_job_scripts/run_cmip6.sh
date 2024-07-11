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
scratchDirectory=/scratch-shared/bvjaarsv

#TODO chnage names in model input to relfect your changes
#TODO Test and see how many spinuop years you want and this must be modified in the ini file
#Ground water rechareg correction
    #It now nearest neighbour interps but we need linear
    #We also need to add the correction factor. 
    #For now i'm turning it off because that is laters problem
#TODO for the steady simulation I must use natural runs
#TODO add dependincies
for simulation in "${simulations[@]}"; do
    model_job_scripts=$(realpath ./)
    modelRoot=$outputDirectory/$simulation
    mkdir -p $modelRoot

    ####################
    # RUN STEADY STATE #
    ####################

    ssModelRoot=$modelRoot/ss
    slurmDir_ss=$ssModelRoot/slurm_logs 
    mkdir -p $ssModelRoot

    #copy globgm input files ino simulation folder
    cp -r $(realpath ../model_input) $ssModelRoot

    # Step 0: Preprocess steady state pcrglobwb data
    # mkdir -p $slurmDir_ss/0_preprocess_pcrglobwb
    # ss_preprocess_script=$model_job_scripts/0_preprocess_pcrglobwb/0_preprocess_pcrglobwb_ss.slurm
    # sbatch -o $slurmDir_ss/0_preprocess_pcrglobwb/0_preprocess_pcrglobwb.out $ss_preprocess_script $ssModelRoot

    # Step 1: prepare_model_partitioning
    # mkdir -p $slurmDir_ss/1_prepare_model_partitioning
    # prep_mod_part_script=$model_job_scripts/1_prepare_model_partitioning/01_prep_model_part.slurm
    # sbatch -o $slurmDir_ss/1_prepare_model_partitioning/1_prep_model_part.out $prep_mod_part_script $ssModelRoot

    # Step 2: 2_write_model_input
    # mkdir -p $slurmDir_ss/2_write_model_input
    # ss_writeInput_script=$model_job_scripts/2_write_model_input/ss.slurm
    # bash $ss_writeInput_script $model_job_scripts $slurmDir_ss $ssModelRoot

    # Step 3: 3_run_modeld
    # mkdir -p $slurmDir_ss/3_run_model
    # sbatch -o $slurmDir_ss/3_run_model/3_run_globgm_s01.out $model_job_scripts/3_run_model/steady-state/mf6_s01_ss.slurm $ssModelRoot
    # sbatch -o $slurmDir_ss/3_run_model/3_run_globgm_s02.out $model_job_scripts/3_run_model/steady-state/mf6_s02_ss.slurm $ssModelRoot
    # sbatch -o $slurmDir_ss/3_run_model/3_run_globgm_s03.out $model_job_scripts/3_run_model/steady-state/mf6_s03_ss.slurm $ssModelRoot
    # sbatch -o $slurmDir_ss/3_run_model/3_run_globgm_s04.out $model_job_scripts/3_run_model/steady-state/mf6_s04_ss.slurm $ssModelRoot

    # Step 4: 4_post-processing
    # mkdir -p $slurmDir_ss/4_post-processing
    # run_script_post_ss=$model_job_scripts/4_post-processing/steady-state/04_post_globgm_ss.slurm
    # sbatch -o $slurmDir_ss/4_post-processing/4_post_globgm_1.out $run_script_post_ss $ssModelRoot 1
    # sbatch -o $slurmDir_ss/4_post-processing/4_post_globgm_2.out $run_script_post_ss $ssModelRoot 2
    # sbatch -o $slurmDir_ss/4_post-processing/4_post_globgm_3.out $run_script_post_ss $ssModelRoot 3
    # sbatch -o $slurmDir_ss/4_post-processing/4_post_globgm_4.out $run_script_post_ss $ssModelRoot 4

    ###############################
    # Run transient historical    #
    ###############################
    #TODO impliment the gwRecharge correction step
    start_year=2012
    end_year=2014
    trModelRoot=$modelRoot/tr_historical
    slurmDir_tr=$trModelRoot/slurm_logs
    mkdir -p $slurmDir_tr
    
    # # # copy globgm input files ino simulation folder
    cp -r $(realpath ../model_input) $trModelRoot

    # Step 0: Preprocess transient pcrglobwb data
    # mkdir -p $slurmDir_tr/0_preprocess_pcrglobwb
    # tr_preprocess_script=$model_job_scripts/0_preprocess_pcrglobwb/0_preprocess_pcrglobwb_tr.slurm
    # sbatch -o $slurmDir_tr/0_preprocess_pcrglobwb/main.out  $tr_preprocess_script $trModelRoot $slurmDir_tr $start_year $end_year

    # Step 1: prepare_model_partitioning
    # mkdir -p $slurmDir_tr/1_prepare_model_partitioning
    # tr_prep_mod_part_script=$model_job_scripts/1_prepare_model_partitioning/01_prep_model_part.slurm
    # sbatch -o $slurmDir_tr/1_prepare_model_partitioning/01prep_model_part.out $tr_prep_mod_part_script $trModelRoot

    # Step 2: 2_write_model_input (Setup model and write tiles)
    # mkdir -p $slurmDir_tr/2_write_model_input
    # tr_writeInput_script=$model_job_scripts/2_write_model_input/tr.slurm
    # bash $tr_writeInput_script $model_job_scripts $slurmDir_tr $trModelRoot $start_year $end_year

    # # Step 3: 3_run_model
    # mkdir -p $slurmDir_tr/3_run_model
    # sbatch -o $slurmDir_tr/3_run_model/3_run_globgm_1.out $model_job_scripts/3_run_model/transient/mf6_s01_tr.slurm $trModelRoot
    # sbatch -o $slurmDir_tr/3_run_model/3_run_globgm_2.out $model_job_scripts/3_run_model/transient/mf6_s02_tr.slurm $trModelRoot
    # sbatch -o $slurmDir_tr/3_run_model/3_run_globgm_3.out $model_job_scripts/3_run_model/transient/mf6_s03_tr.slurm $trModelRoot $model_job_scripts
    # bash $model_job_scripts/3_run_model/transient/mf6_s03_tr.slurm $trModelRoot $model_job_scripts
    # sbatch -o $slurmDir_tr/3_run_model/3_run_globgm_4.out $model_job_scripts/3_run_model/transient/mf6_s04_tr.slurm $trModelRoot

    # Step 4: post-process
    # mkdir -p $slurmDir_tr/4_post-processing
    # run_script_post_tr=$model_job_scripts/4_post-processing/transient/04_post_globgm_tr.slurm
    # sbatch -o $slurmDir_tr/4_post-processing/4_post_globgm_1.out $run_script_post_tr $trModelRoot 1 $start_year $end_year
    # sbatch -o $slurmDir_tr/4_post-processing/4_post_globgm_2.out $run_script_post_tr $trModelRoot 2 $start_year $end_year
    # sbatch -o $slurmDir_tr/4_post-processing/4_post_globgm_3.out $run_script_post_tr $trModelRoot 3 $start_year $end_year
    # sbatch -o $slurmDir_tr/4_post-processing/4_post_globgm_4.out $run_script_post_tr $trModelRoot 4 $start_year $end_year
done
