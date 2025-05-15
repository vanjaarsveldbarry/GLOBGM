#!/bin/bash -l

#Initialise an interactive session
module load 2023
module load mpifileutils/0.11.1-gompi-2023a 

############################################################################################################
#                   historical with pump
############################################################################################################

simName=historical_with_pump
input_dir=/projects/prjs1222/globgm_output/_backup/$simName/gswp3-w5e5
saveDir=/scratch-shared/globgm_scratch/historical_reference_gswp3-w5e5/$simName && mkdir -p $saveDir

mpirun -np 128 dtar -x -f historical_with_pump.tar historical_with_pump_input