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

# mpirun -np 128 dcp $input_dir/forcing_input $saveDir
# wait
# mpirun -np 128 dcp $input_dir/mf6_post $saveDir
# wait
mpirun -np 128 dcp $input_dir/model_input $saveDir
wait
# mpirun -np 128 dcp $input_dir/slurm_logs $saveDir
# wait

tar_save_dir=/gpfs/scratch1/shared/globgm_scratch/historical_reference_gswp3-w5e5/$simName
# cd $saveDir/forcing_input

# forcing_files=("discharge.zarr" "gwAbstraction.zarr" "gwRecharge_correction_factor.zarr" "gwRecharge.zarr")
# for file in "${forcing_files[@]}"; do
#   mpirun -np 120 dtar --progress 3 -c -f "$tar_save_dir/forcing_input/${file}.tar" "$tar_save_dir/forcing_input/$file"
#   wait
#   mpirun -np 120 drm -v "$tar_save_dir/forcing_input/$file"
# done

# cd $saveDir/mf6_post
# for var in "hds" "wtd"; do
#     for i in {1..4}; do
    # mpirun -np 120 dtar --progress 3 -c -f  "$tar_save_dir/mf6_post/s0${i}_${var}.zarr.tar" "$tar_save_dir/mf6_post/s0${i}_${var}.zarr"
    # wait
#     mpirun -np 120 drm -v "$tar_save_dir/mf6_post/s0${i}_${var}.zarr"
#     wait
#     done
# done
cd $saveDir
# mpirun -np 120 dtar --progress 3 -c -f $tar_save_dir/slurm_logs.tar $tar_save_dir/slurm_logs
# wait
# mpirun -np 120 drm -v $tar_save_dir/slurm_logs
# wait
mpirun -np 120 dtar --progress 3 -c -f $tar_save_dir/model_input.tar $tar_save_dir/model_input
wait
# mpirun -np 120 drm -v $tar_save_dir/model_input
# wait

# cd /projects/prjs1222/GLOBGM/run_simulation/model_job_scripts/dataManagement
# irods_pass='d13JqlhwgWDoQCfWOuGcJCfmfVPf9CwF'
# sbatch --partition=staging --time=24:00:00 \
#        --job-name=dag_historical_with_pump \
#        --output=/projects/prjs1222/GLOBGM/run_simulation/model_job_scripts/dataManagement/slurmOut/historical_with_pump.out \
#        --export=ALL,irods_pass=$irods_pass --wrap="source ${HOME}/.bashrc && mamba activate globgm && python -u ./_dag.py $irods_pass $saveDir" 

############################################################################################################
#                   historical no pump
############################################################################################################
simName=historical_no_pump
input_dir=/projects/prjs1222/globgm_output/_backup/$simName/gswp3-w5e5
saveDir=/scratch-shared/globgm_scratch/historical_reference_gswp3-w5e5/$simName && mkdir -p $saveDir

# mpirun -np 190 dcp $input_dir/forcing_input $saveDir
# wait
# mpirun -np 190 dcp $input_dir/mf6_post $saveDir
# wait
# mpirun -np 190 dcp $input_dir/model_input $saveDir
# wait
# mpirun -np 190 dcp $input_dir/slurm_logs $saveDir
# wait

# tar_save_dir=/gpfs/scratch1/shared/globgm_scratch/historical_reference_gswp3-w5e5/$simName
# cd $saveDir/forcing_input

# forcing_files=("discharge.zarr" "gwAbstraction.zarr" "gwRecharge_correction_factor.zarr" "gwRecharge.zarr")
# for file in "${forcing_files[@]}"; do
#   mpirun -np 190 dtar --progress 3 -c -f "$tar_save_dir/forcing_input/${file}.tar" "$tar_save_dir/forcing_input/$file"
#   wait
#   mpirun -np 190 drm -v "$tar_save_dir/forcing_input/$file"
#   wait
# done
# wait

# cd $saveDir/mf6_post
# for var in "hds" "wtd"; do
#     for i in {1..4}; do
#     mpirun -np 190 dtar --progress 3 -c -f  "$tar_save_dir/mf6_post/s0${i}_${var}.zarr.tar" "$tar_save_dir/mf6_post/s0${i}_${var}.zarr"
#     wait
#     mpirun -np 190 drm -v "$tar_save_dir/mf6_post/s0${i}_${var}.zarr"
#     wait
#     done
# done
# wait
# cd $saveDir
# mpirun -np 190 dtar --progress 3 -c -f $tar_save_dir/slurm_logs.tar $tar_save_dir/slurm_logs
# wait
# mpirun -np 190 drm -v $tar_save_dir/slurm_logs
# wait
# mpirun -np 190 dtar --progress 3 -c -f $tar_save_dir/model_input.tar $tar_save_dir/model_input
# wait
# mpirun -np 190 drm -v $tar_save_dir/model_input
# wait

# cd /projects/prjs1222/GLOBGM/run_simulation/model_job_scripts/dataManagement
# irods_pass='d13JqlhwgWDoQCfWOuGcJCfmfVPf9CwF'
# sbatch --partition=staging --time=24:00:00 \
#        --job-name=dag_historical_no_pump \
#        --output=/projects/prjs1222/GLOBGM/run_simulation/model_job_scripts/dataManagement/slurmOut/historical_no_pump.out \
#        --export=ALL,irods_pass=$irods_pass --wrap="source ${HOME}/.bashrc && mamba activate globgm && python -u ./_dag.py $irods_pass $saveDir" 
