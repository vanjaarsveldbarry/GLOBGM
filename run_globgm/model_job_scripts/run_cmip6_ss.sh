#!/bin/bash -l
#SBATCH -N 1
#SBATCH -J sn_ss_W5E5
#SBATCH -t 24:00:00
#SBATCH --partition=genoa
#SBATCH --output=sn_ss_W5E5.out

# create_environment() {
#     # Name of the environment
#     local ENV_NAME="globgm"

#     # Check if the environment exists
#     if mamba env list | grep -q "$ENV_NAME"; then
#         # Delete the existing environment
#         yes | mamba env remove -n "$ENV_NAME"
#     fi

#     # Create a new environment with the same name
#     yes | mamba create -c conda-forge -c bioconda -n "$ENV_NAME" python=3.10 pcraster=4.3.1 netcdf4 gdal cdo nco six xarray dask zarr bottleneck snakemake 
# }
# create_environment
# wait

source ${HOME}/.bashrc
mamba activate globgm

simulation=gswp3-w5e5
outputDirectory=/projects/0/einf4705/workflow/output
run_globgm_dir=$(realpath ../)

snakemake -R --cores 1 \
--snakefile Snakefile_W5E5_ss.smk \
--config simulation=$simulation \
         outputDirectory=$outputDirectory \
         run_globgm_dir=$run_globgm_dir