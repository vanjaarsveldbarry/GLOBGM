#!/bin/bash -l
#SBATCH -N 1
#SBATCH -J _backup
#SBATCH -t 24:00:00
#SBATCH --partition=thin
#SBATCH --tasks-per-node=120
#SBATCH --cpus-per-task=1
#SBATCH --output=/projects/prjs1222/GLOBGM/run_simulation/model_job_scripts/dataManagement/slurmOut/historical.out


module load 2023
module load mpifileutils/0.11.1-gompi-2023a 

scenario=ssp126
for GCM in gfdl-esm4 mpi-esm1-2-hr mri-esm2-0 ukesm1-0-ll; do
    echo $GCM
    #Copy to backup on project space
    saveDir=/projects/prjs1222/globgm_output/_backup/cmip6_runs/$GCM/$scenario/ && mkdir -p $saveDir
    mpirun -np 120 dcp /projects/prjs1222/globgm_output/$GCM/${scenario}/forcing_input $saveDir
    wait
    mpirun -np 120 dcp /projects/prjs1222/globgm_output/$GCM/${scenario}/mf6_post $saveDir
    wait
    mpirun -np 120 dcp /projects/prjs1222/globgm_output/$GCM/${scenario}/model_input $saveDir
    wait
    mpirun -np 120 dcp /projects/prjs1222/globgm_output/$GCM/${scenario}/slurm_logs $saveDir
    wait
done

#copy to scratch to backup on dag
# for scenario in historical ssp126 ssp370 ssp585; do
# for scenario in ssp585; do
    # saveDir=/scratch-shared/globgm_scratch/cmip6_backup/$GCM && mkdir -p $saveDir
    # input_dir=/projects/prjs1222/globgm_output/_backup/cmip6_runs/$GCM/$scenario
    # tar_save_dir=/gpfs/scratch1/shared/globgm_scratch/cmip6_backup/$GCM

    # mpirun -np 190 dcp $input_dir $saveDir
    # wait
    # cd $saveDir/$scenario/forcing_input
    # forcing_files=("discharge.zarr" "gwAbstraction.zarr" "gwRecharge_correction_factor.zarr" "gwRecharge.zarr")
    # for file in "${forcing_files[@]}"; do
    #     mpirun -np 190 dtar --progress 3 -c -f "$tar_save_dir/$scenario/forcing_input/${file}.tar" "$tar_save_dir/$scenario/forcing_input/$file"
    #     wait
    #     mpirun -np 190 drm -v "$tar_save_dir/$scenario/forcing_input/$file"
    #     wait
    # done

    # cd $saveDir/$scenario/mf6_post
    # for var in "hds" "wtd"; do
    #     for i in {1..4}; do
    #     mpirun -np 190 dtar --progress 3 -c -f  "$tar_save_dir/$scenario/mf6_post/s0${i}_${var}.zarr.tar" "$tar_save_dir/$scenario/mf6_post/s0${i}_${var}.zarr"
    #     wait
    #     mpirun -np 190 drm -v "$tar_save_dir/$scenario/mf6_post/s0${i}_${var}.zarr"
    #     wait
    #     done
    # done
    # cd $saveDir/$scenario
    # mpirun -np 190 dtar --progress 3 -c -f $tar_save_dir/$scenario/slurm_logs.tar $tar_save_dir/$scenario/slurm_logs
    # wait
    # mpirun -np 190 drm -v $tar_save_dir/$scenario/slurm_logs
    # wait
    # mpirun -np 190 dtar --progress 3 -c -f $tar_save_dir/$scenario/model_input.tar $tar_save_dir/$scenario/model_input
    # wait
    # mpirun -np 190 drm -v $tar_save_dir/$scenario/model_input
    # wait
#     cd /projects/prjs1222/GLOBGM/run_simulation/model_job_scripts/dataManagement
#     irods_pass='d13JqlhwgWDoQCfWOuGcJCfmfVPf9CwF'
#     logName=${GCM}_${scenario}
#     irodsPath="/nluu14p/home/deposit-pilot/globgm/globgm_output/cmip6_runs/${GCM}" 
#     sbatch --partition=staging --time=24:00:00 \
#            --job-name="${logName}" \
#            --output="/projects/prjs1222/GLOBGM/run_simulation/model_job_scripts/dataManagement/slurmOut/${logName}.out" \
#            --export=ALL,irods_pass=$irods_pass,irodsPath=$irodsPath --wrap="source ${HOME}/.bashrc && mamba activate globgm && python -u ./_dag.py $irods_pass $saveDir/$scenario $irodsPath" 
# done