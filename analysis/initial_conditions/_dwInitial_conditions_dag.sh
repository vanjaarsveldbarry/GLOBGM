#!/bin/bash -l
module load 2023
module load iRODS-iCommands/4.3.0 

password=Ng24id6K5VndWWs7ZJ58XGnrZGLa8GuD
saveDir=/scratch-shared/globgm_scratch/initial_conditions

mkdir -p $saveDir
# echo $password | iinit
# iget -vPf /nluu14p/home/deposit-pilot/globgm/globgm_output/initial_conditions/output_initial_conditions.tar $saveDir

# wait
module load 2023
module load mpifileutils/0.11.1-gompi-2023a

cd $saveDir
mpirun -np 100 dtar -x -f output_initial_conditions.tar