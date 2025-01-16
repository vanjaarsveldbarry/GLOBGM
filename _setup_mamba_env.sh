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
#     yes | mamba create -c conda-forge -c bioconda -n "$ENV_NAME" tqdm python pcraster netcdf4 gdal cdo nco six xarray dask zarr=2.18.4 bottleneck snakemake=8.26.0 pyinterp flopy geopandas snakemake-executor-plugin-slurm seaborn
# }
# create_environment
# wait

create_environment() {
    # Name of the environment
    local ENV_NAME="globgm_pcraster"

    # Check if the environment exists
    if mamba env list | grep -q "$ENV_NAME"; then
        # Delete the existing environment
        yes | mamba env remove -n "$ENV_NAME"
    fi

    # Create a new environment with the same name
    yes | mamba create -c conda-forge -c bioconda -n "$ENV_NAME" tqdm python pcraster=4.3.3 netcdf4 gdal cdo nco six xarray dask zarr=2.18.3 bottleneck pyinterp flopy geopandas seaborn
}
create_environment
wait