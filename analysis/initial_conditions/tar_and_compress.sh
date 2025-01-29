#!/bin/bash -l

#Start interactive job
# run --partition=genoa --exclusive --nodes=1 --ntasks-per-node=192 --job-name="interact" --time=03:00:00 --pty bash -i

#Move to target directory
# cd /scratch-shared/globgm_scratch/output_initial_conditions/

#Start compres and tar 

# module load 2023
# module load mpifileutils/0.11.1-gompi-2023a

#Run once to get actual file path, this will throw an error
# mpirun -np 120 dtar -c -f /scratch-shared/globgm_scratch/output_initial_conditions/output_initial_conditions.tar /scratch-shared/globgm_scratch/output_initial_conditions

# #Update code to conatin actual file path
# mpirun -np 120 dtar -c -f /gpfs/scratch1/shared/globgm_scratch/output_initial_conditions.tar /gpfs/scratch1/shared/globgm_scratch/output_initial_conditions

#Upload to iRods 
# iput -Pv /scratch-shared/globgm_scratch/output_initial_conditions.tar /nluu14p/home/deposit-pilot/globgm/globgm_output/initial_states