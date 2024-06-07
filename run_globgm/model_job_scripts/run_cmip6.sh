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
    # yes | mamba create -n "$ENV_NAME" python=3.10 requests pcraster netcdf4 cdo beautifulsoup4 \
                                                #  tqdm six nco python-wget xarray dask zarr bottleneck \
                                                #  pyinterp 
# }
# create_environment
# wait

####################################################################################################
# USER DEFINED OPTIONS #                                                                           # 
# simulations=("gfdl-esm4" "gswp3-w5e5" "ipsl-cm6a-lr" "mpi-esm1-2-hr" "mri-esm2-0" "ukesm1-0-ll") #
####################################################################################################
simulations=("gswp3-w5e5")
outputDirectory=/projects/0/einf4705/workflow/output

#TODO is this till needed
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

#TODO chnage names in model input to relfect your changes
#TODO drop the islands with no data by seeing if they have a value of 0 or nan i n the steady state results
#TODO Test and see how many spinuop years you want and this must be modified in the ini file
#Ground water rechareg correction
    #It now nearest neighbour interps but we need linear
    #We also need to add the correction factor. 
    #For now i'm turning it off because that is laters problem

for simulation in "${simulations[@]}"; do
    model_job_scripts=$(realpath ./)
    modelRoot=$outputDirectory/$simulation
    modelScratch=/scratch-shared/bvjaarsv/$simulation
    mkdir -p $modelRoot

    # #copy input data from source directory
    # bash $model_job_scripts/_1_fetch_input/copyFiles.sh $modelRoot

    ####################
    # RUN STEADY STATE #
    ####################

    #TODO HIGH PRIORITY: use natural simulations once they are complete on eejit
    ssModelRoot=${modelRoot}/ss
    slurmDir_ss=$ssModelRoot/slurm_logs 
    mkdir -p $ssModelRoot

    #copy globgm input files ino simulation folder
    # cp -r $(realpath ../model_input/) $ssModelRoot

    # # Step 0: Preprocess steady state data pcrglobwb data
    # mkdir -p $slurmDir_ss/0_preprocess_pcrglobwb
    # ss_preprocess_script=$model_job_scripts/0_preprocess_pcrglobwb/0_preprocess_pcrglobwb_ss.slurm
    # sbatch -o $slurmDir_ss/0_preprocess_pcrglobwb/0_preprocess_pcrglobwb.out $ss_preprocess_script $ssModelRoot

    # Step 1: prepare_model_partitioning
    # mkdir -p $slurmDir_ss/1_prepare_model_partitioning
    # prep_mod_part_script=$model_job_scripts/1_prepare_model_partitioning/01_prep_model_part.slurm
    # sbatch -o $slurmDir_ss/1_prepare_model_partitioning/1_prep_model_part.out $prep_mod_part_script $ssModelRoot

    #TODO writ eto scratch
    # Step 2: 2_write_model_input
    # mkdir -p $slurmDir_ss/2_write_model_input/
    # ss_writeInput_setup_script=$model_job_scripts/2_write_model_input/_setup_ss.slurm
    # sbatch -o $slurmDir_ss/2_write_model_input/2_write_model_input_setup.out $ss_writeInput_setup_script $ssModelRoot
    # ss_writeInput_script=$model_job_scripts/2_write_model_input/ss.slurm
    # sbatch -o $slurmDir_ss/2_write_model_input/2_write_model_input%a.out --array=1-163:10 --constraint=scratch-node --exclusive $ss_writeInput_script $ssModelRoot

    # Step 3: 3_run_model
    # mkdir -p $slurmDir_ss/3_run_model
    # run_script_ss1=$model_job_scripts/3_run_model/steady-state/mf6_s01_ss.slurm
    # sbatch -o $slurmDir_ss/3_run_model/3_run_globgm_s01.out $run_script_ss1 $ssModelRoot
    # run_script_ss2=$model_job_scripts/3_run_model/steady-state/mf6_s02_ss.slurm
    # sbatch -o $slurmDir_ss/3_run_model/3_run_globgm_s02.out $run_script_ss2 $ssModelRoot
    # run_script_ss3=$model_job_scripts/3_run_model/steady-state/mf6_s03_ss.slurm
    # sbatch -o $slurmDir_ss/3_run_model/3_run_globgm_s03.out $run_script_ss3 $ssModelRoot
    # run_script_ss4=$model_job_scripts/3_run_model/steady-state/mf6_s04_ss.slurm
    # sbatch -o $slurmDir_ss/3_run_model/3_run_globgm_s04.out $run_script_ss4 $ssModelRoot

    # Step 4: 4_post-processing
    #TODO LOW PRIORITY: I could move some of this to node-local.
    #TODO HIGH PRIORITY: make it much transinet runs make this work for the so that the variables are split up into differnet datasets. 
    # mkdir -p $slurmDir_ss/4_post-processing
    # run_script_post_ss=$model_job_scripts/4_post-processing/steady-state/04_post_globgm_ss.slurm
    # sbatch -o $slurmDir_ss/4_post-processing/4_post_globgm_1.out $run_script_post_ss $ssModelRoot 1
    # sbatch -o $slurmDir_ss/4_post-processing/4_post_globgm_2.out $run_script_post_ss $ssModelRoot 2
    # sbatch -o $slurmDir_ss/4_post-processing/4_post_globgm_3.out $run_script_post_ss $ssModelRoot 3
    # sbatch -o $slurmDir_ss/4_post-processing/4_post_globgm_4.out $run_script_post_ss $ssModelRoot 4

    ###############################
    # Run transient historical    #
    ###############################
    #TODO where you have have implimented zarr read an writes speed it up and check latlon order
    #TODO you need the upper layer pcraster map for post processing 
    #TODO copy what you did in the steady state using node-local storage
    # start_year=2013
    # end_year=2013
    # trModelRoot=$modelRoot/tr_historical

    # slurmDir_tr=$trModelRoot/slurm_logs
    # mkdir -p $slurmDir_tr

    # # copy globgm input files ino simulation folder
    # cp -r $(realpath ../model_input/) $trModelRoot 

    # Step 0: Preprocess steady state data pcrglobwb data
    # mkdir -p $slurmDir_tr/0_preprocess_pcrglobwb
    # tr_preprocess_script=$model_job_scripts/0_preprocess_pcrglobwb/0_preprocess_pcrglobwb_tr.slurm
    # sbatch -o $slurmDir_tr/0_preprocess_pcrglobwb/main.out  $tr_preprocess_script $trModelRoot $slurmDir_tr/0_preprocess_pcrglobwb $start_year $end_year

    # Step 1: prepare_model_partitioning
    #TODO: thsi is limiting in terms of number of jibs maybe to one job per year 
    # mkdir -p $slurmDir_tr/1_prepare_model_partitioning
    # tr_prep_mod_part_script=$model_job_scripts/1_prepare_model_partitioning/01_prep_model_part.slurm
    # sbatch -o $slurmDir_tr/1_prepare_model_partitioning/01prep_model_part.out $tr_prep_mod_part_script $trModelRoot

    # Step 2: 2_write_model_input
    # mkdir -p $slurmDir_tr/2_write_model_input/
    # tr_writeInput_setup_script=$model_job_scripts/2_write_model_input/_setup_tr.slurm
    # sbatch -o $slurmDir_tr/2_write_model_input/2_write_model_input_setup.out $tr_writeInput_setup_script $trModelRoot $start_year $end_year
    # tr_writeInput_script=$model_job_scripts/2_write_model_input/tr.slurm
    # sbatch -o $slurmDir_tr/2_write_model_input/2_write_model_input%a.out --array=1-163:10 --constraint=scratch-node --exclusive $tr_writeInput_script $trModelRoot $start_year $end_year

    # Step 3: 3_run_model
    # mkdir -p $slurmDir_tr/3_run_model
    # run_script_tr1=$model_job_scripts/3_run_model/transient/mf6_s01_tr.slurm
    # sbatch -o $slurmDir_tr/3_run_model/3_run_globgm_1.out $run_script_tr1 $trModelRoot
    # run_script_tr2=$model_job_scripts/3_run_model/transient/mf6_s02_tr.slurm
    # sbatch -o $slurmDir_tr/3_run_model/3_run_globgm_2.out $run_script_tr2 $trModelRoot
    # run_script_tr3=$model_job_scripts/3_run_model/transient/mf6_s03_tr.slurm
    # sbatch -o $slurmDir_tr/3_run_model/3_run_globgm_3.out $run_script_tr3 $trModelRoot
    # run_script_tr4=$model_job_scripts/3_run_model/transient/mf6_s04_tr.slurm
    # sbatch -o $slurmDir_tr/3_run_model/3_run_globgm_4.out $run_script_tr4 $trModelRoot

    # Step 4: post-process
    # # TODO this will not wokr for the 85 year simululation, you need to but a break on it
    # # given that you are looping over years it might actually work
    # #TODO do this for hds variable too
    # #TODO make the script go:
    # #1 write initial zarr store
    # #2 Then for each month file
    # #3 convert to asc
    # #4 convert to zarr and append to the initial zarr store. So you inut is essentially solution year and month.
    #TODO if I slap it with an exclusive in genoa how mmuch faster will it be 
    # mkdir -p $slurmDir_tr/4_post-processing
    # run_script_post_tr=$model_job_scripts/4_post-processing/transient/04_post_globgm_tr.slurm
    # sbatch -o $slurmDir_tr/4_post-processing/4_post_globgm_1_wtd.out $run_script_post_tr $trModelRoot 1 $start_year $end_year wtd
    # sbatch -o $slurmDir_tr/4_post-processing/4_post_globgm_2_wtd.out $run_script_post_tr $trModelRoot 2 $start_year $end_year wtd
    # sbatch -o $slurmDir_tr/4_post-processing/4_post_globgm_3_wtd.out $run_script_post_tr $trModelRoot 3 $start_year $end_year wtd
    # sbatch -o $slurmDir_tr/4_post-processing/4_post_globgm_4_wtd.out $run_script_post_tr $trModelRoot 4 $start_year $end_year wtd
done
