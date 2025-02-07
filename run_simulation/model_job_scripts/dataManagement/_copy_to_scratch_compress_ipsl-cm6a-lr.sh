#!/bin/bash -l

#Initialise an interactive session
module load 2023
module load mpifileutils/0.11.1-gompi-2023a 

GCM=ipsl-cm6a-lr
for scenario in ssp126 ssp370 ssp585; do
    saveDir=/projects/prjs1222/globgm_output/_backup/cmip6_runs/$GCM/$scenario/ && mkdir -p $saveDir
    mpirun -np 180 dcp /projects/prjs1222/globgm_output/$GCM/${scenario}/forcing_input $saveDir
    wait
    mpirun -np 180 dcp /projects/prjs1222/globgm_output/$GCM/${scenario}/mf6_post $saveDir
    wait
    mpirun -np 180 dcp /projects/prjs1222/globgm_output/$GCM/${scenario}/model_input $saveDir
    wait
    mpirun -np 180 dcp /projects/prjs1222/globgm_output/$GCM/${scenario}/slurm_logs $saveDir
    wait
done