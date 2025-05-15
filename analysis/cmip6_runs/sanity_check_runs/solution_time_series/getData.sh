#!/bin/bash -l

#Initialise an interactive session
module load 2023
module load mpifileutils/0.11.1-gompi-2023a 

#Historical with pump

saveDir=/scratch-shared/globgm_scratch/analysis/cmip6_runs/sanity_check_runs/solution_time_series/data/sim_data
inDir=/projects/prjs1222/globgm_output/_backup

mkdir -p $saveDir
mkdir -p $saveDir/historical_with_pump/forcing_input
mkdir -p $saveDir/historical_with_pump/mf6_post
wait

# mpirun -np 180 dcp $inDir/historical_with_pump/gswp3-w5e5/forcing_input/gwRecharge.zarr $saveDir/historical_with_pump/forcing_input
# wait

# mpirun -np 180 dcp $inDir/historical_with_pump/gswp3-w5e5/forcing_input/gwAbstraction.zarr $saveDir/historical_with_pump/forcing_input
# wait

# mpirun -np 180 dcp $inDir/historical_with_pump/gswp3-w5e5/mf6_post/s03_hds.zarr $saveDir/historical_with_pump/mf6_post
# wait
mpirun -np 180 dchmod --mode 777 $saveDir
wait 


GCM=ipsl-cm6a-lr
for scenario in ssp126 ssp370 ssp585; do
    inDir=$inDir/cmip6_runs/$GCM/$scenario/
    _saveDir=$saveDir/$GCM/$scenario/ #&& mkdir -p $saveDir
    echo $_saveDir
    # mpirun -np 180 dcp $inDir/mf6_post $saveDir
    wait
done

# mpirun -np 128 dchmod --mode 777 /scratch-shared/globgm_scratch
# wait 