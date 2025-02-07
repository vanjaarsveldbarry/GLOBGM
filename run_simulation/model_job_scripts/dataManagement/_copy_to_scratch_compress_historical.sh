#!/bin/bash -l

#Initialise an interactive session
module load 2023
module load mpifileutils/0.11.1-gompi-2023a 

############################################################################################################
#                   historical with pump
############################################################################################################

# saveDir=/scratch-shared/globgm_scratch/historical_reference_gswp3-w5e5/historical_with_pump && mkdir -p $saveDir

# mpirun -np 128 dcp /projects/prjs1222/globgm_output/historical_with_pump/gswp3-w5e5/forcing_input $saveDir
# wait
# mpirun -np 128 dcp /projects/prjs1222/globgm_output/historical_with_pump/gswp3-w5e5/mf6_post $saveDir
# wait
# mpirun -np 128 dcp /projects/prjs1222/globgm_output/historical_with_pump/gswp3-w5e5/model_input $saveDir
# wait
# mpirun -np 128 dcp /projects/prjs1222/globgm_output/historical_with_pump/gswp3-w5e5/slurm_logs $saveDir
# wait

# cd /scratch-shared/globgm_scratch/historical_reference_gswp3-w5e5
# mpirun -np 120 dtar --progress 3 -c -f /gpfs/scratch1/shared/globgm_scratch/historical_reference_gswp3-w5e5/historical_no_pump.tar /gpfs/scratch1/shared/globgm_scratch/historical_reference_gswp3-w5e5/historical_no_pump



############################################################################################################
#                   historical no pump
############################################################################################################

# saveDir=/scratch-shared/globgm_scratch/historical_reference_gswp3-w5e5/historical_no_pump && mkdir -p $saveDir

# mpirun -np 128 dcp /projects/prjs1222/globgm_output/historical_no_pump_natural/gswp3-w5e5/forcing_input $saveDir
# wait
# mpirun -np 128 dcp /projects/prjs1222/globgm_output/historical_no_pump_natural/gswp3-w5e5/mf6_post $saveDir
# wait
# mpirun -np 128 dcp /projects/prjs1222/globgm_output/historical_no_pump_natural/gswp3-w5e5/model_input $saveDir
# wait
# mpirun -np 128 dcp /projects/prjs1222/globgm_output/historical_no_pump_natural/gswp3-w5e5/slurm_logs $saveDir
# wait

# cd /scratch-shared/globgm_scratch/historical_reference_gswp3-w5e5
# mpirun -np 120 dtar --progress 3 -c -f /gpfs/scratch1/shared/globgm_scratch/historical_reference_gswp3-w5e5/historical_with_pump.tar /gpfs/scratch1/shared/globgm_scratch/historical_reference_gswp3-w5e5/historical_with_pump
