#!/bin/bash -l

create_environment() {
    # Name of the environment
    local ENV_NAME="globgm"

    # Check if the environment exists
    if mamba env list | grep -q "$ENV_NAME"; then
        # Delete the existing environment
        yes | mamba env remove -n "$ENV_NAME"
    fi

    Create a new environment with the same name
    yes | mamba create -c conda-forge -c bioconda -n "$ENV_NAME" python=3.10 pcraster=4.3.1 netcdf4 cdo nco six xarray dask zarr bottleneck \
                                                 tqdm six nco python-wget xarray dask zarr bottleneck \
                                                 pyinterp snakemake
}
create_environment
wait

# simulations=("gswp3-w5e5")
# outputDirectory=/projects/0/einf4705/workflow/output
# for simulation in "${simulations[@]}"; do
#     model_job_scripts=$(realpath ./)
#     modelRoot=$outputDirectory/$simulation
#     ssModelRoot=$modelRoot/ss
#     slurmDir_ss=$ssModelRoot/slurm_logs 
#     mkdir -p $ssModelRoot $slurmDir_ss/1_prepare_model_partitioning $slurmDir_ss/2_write_model_input $slurmDir_ss/3_run_model $slurmDir_ss/4_post-processing

#     ####################
#     # RUN STEADY STATE #
#     ####################
#     #TODO ADD JOB DEPENDENCY# jobid=$(sbatch -o $slurmDir_ss/1_prepare_model_partitioning/1_prep_model_part.out $prep_mod_part_script $ssModelRoot | awk '{print $4}')

#     #copy globgm input files into simulation folder
#     cp -r $(realpath ../model_input) $ssModelRoot

#     # Step 1: 1_prepare_model_partitioning
#     # prep_mod_ss=$model_job_scripts/1_prepare_model_partitioning/01_prep_model_part.slurm
#     # sbatch -o $slurmDir_ss/1_prepare_model_partitioning/1_prep_model_part.out $prep_mod_ss $ssModelRoot

#     # Step 2: 2_write_model_input
#     # sbatch -o $slurmDir_ss/2_write_model_input/_setup_ss.out $model_job_scripts/2_write_model_input/ss/_setup_ss.slurm $ssModelRoot
#     sbatch -o $slurmDir_ss/2_write_model_input/_writeModels_ss.out $model_job_scripts/2_write_model_input/ss/_writeModels_ss.slurm $ssModelRoot
#     # bash $model_job_scripts/2_write_model_input/ss/_writeModels_ss.slurm $ssModelRoot
    
#     # Step 3: 3_run_model
#     # sbatch -o $slurmDir_ss/3_run_model/3_run_globgm_s01.out $model_job_scripts/3_run_model/steady-state/mf6_s01_ss.slurm $ssModelRoot $model_job_scripts $slurmDir_ss
#     # sbatch -o $slurmDir_ss/3_run_model/3_run_globgm_s02.out $model_job_scripts/3_run_model/steady-state/mf6_s02_ss.slurm $ssModelRoot $model_job_scripts $slurmDir_ss
#     # sbatch -o $slurmDir_ss/3_run_model/3_run_globgm_s03.out $model_job_scripts/3_run_model/steady-state/mf6_s03_ss.slurm $ssModelRoot $model_job_scripts $slurmDir_ss
#     # sbatch -o $slurmDir_ss/3_run_model/3_run_globgm_s04.out $model_job_scripts/3_run_model/steady-state/mf6_s04_ss.slurm $ssModelRoot $model_job_scripts $slurmDir_ss
# done