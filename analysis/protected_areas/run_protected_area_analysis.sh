#!/bin/bash

dataDirectory=/scratch-shared/globgm_scratch/historical_reference_gswp3-w5e5/protected_areas
slurmDir=/home/bvjaarsveld1/projects/workflow/GLOBGM/analysis/historical_reference_gswp3-w5e5/protected_areas/slurmOut
mkdir -p $dataDirectory

cd /home/bvjaarsveld1/projects/workflow/GLOBGM/analysis/historical_reference_gswp3-w5e5/protected_areas

# python /home/bvjaarsveld1/projects/workflow/GLOBGM/analysis/historical_reference_gswp3-w5e5/protected_areas/preprocess.py

sbatch -o $slurmDir/extract_data.out --exclusive --partition=genoa -N 1 -n 192 --time=120:00:00 \
       --job-name=extract_data_job \
       --wrap="source ${HOME}/.bashrc && mamba activate globgm && python -u extract_data.py"


 