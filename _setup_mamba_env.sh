#!/bin/bash -l
create_environment() {
    # Name of the environment
    local ENV_NAME="globgm"

    # Check if the environment exists
    if mamba env list | grep -q "$ENV_NAME"; then
        # Delete the existing environment
        yes | mamba env remove -n "$ENV_NAME"
    fi

    # Create a new environment with the same name
    yes | mamba create -c conda-forge -c bioconda -n "$ENV_NAME" python=3.10 pcraster=4.3.1 netcdf4 gdal cdo nco six xarray dask zarr bottleneck snakemake pyinterp flopy
}
create_environment
wait