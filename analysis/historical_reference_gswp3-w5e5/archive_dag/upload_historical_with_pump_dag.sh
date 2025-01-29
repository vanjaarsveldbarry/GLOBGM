#!/bin/bash -l

################ UPLOAD TO DAG ##############
# Start interactive session
# srun --partition=genoa --exclusive --nodes=1 --ntasks-per-node=192 --job-name="interact" --time=03:00:00 --pty bash -i

# module load 2023
# module load mpifileutils/0.11.1-gompi-2023a

#To compress the calibration folder
# cd /scratch-shared/globgm_scratch/historical_reference_gswp3-w5e5
# mpirun -np 120 dtar --progress 3 -c -f /gpfs/scratch1/shared/globgm_scratch/historical_reference_gswp3-w5e5/historical_with_pump.tar /gpfs/scratch1/shared/globgm_scratch/historical_reference_gswp3-w5e5/historical_with_pump

iput -PvK /scratch-shared/globgm_scratch/historical_reference_gswp3-w5e5/historical_with_pump.tar /nluu14p/home/deposit-pilot/globgm/globgm_output/historical_reference_gswp3-w5e5

