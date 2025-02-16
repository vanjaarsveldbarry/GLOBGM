#!/bin/bash -l

#Initialise an interactive session
module load 2023
module load mpifileutils/0.11.1-gompi-2023a 

GCM=ipsl-cm6a-lr
# for scenario in historical ssp126 ssp370 ssp585; do
for scenario in historical; do
    inDir=/projects/prjs1222/globgm_output/_backup/cmip6_runs/$GCM/$scenario/
    saveDir=/scratch-shared/globgm_scratch/cmip6_runs/$GCM/$scenario/ && mkdir -p $saveDir

    mpirun -np 190 dcp $inDir/mf6_post $saveDir
    wait
done

mpirun -np 190 dchmod --mode 777 /scratch-shared/globgm_scratch
wait 