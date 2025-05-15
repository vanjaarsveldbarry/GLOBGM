#!/bin/bash -l
#SBATCH -N 1
#SBATCH -J _backup
#SBATCH -t 24:00:00
#SBATCH --partition=thin
#SBATCH --tasks-per-node=192
#SBATCH --cpus-per-task=1
#SBATCH --exclusive
#SBATCH --output=/projects/prjs1222/GLOBGM/run_simulation/model_job_scripts/dataManagement/slurmOut/ssp126.out

module load 2023
module load mpifileutils/0.11.1-gompi-2023a 

scenario=ssp585
for GCM in mri-esm2-0 ukesm1-0-ll; do
    echo $GCM
    #Copy to backup on project space
    # saveDir_proj=/projects/prjs1222/globgm_output/_backup/cmip6_runs/$GCM/$scenario/ && mkdir -p $saveDir_proj
    # mpirun -np 120 dcp /projects/prjs1222/globgm_output/$GCM/${scenario}/forcing_input $saveDir_proj
    # wait
    # mpirun -np 120 dcp /projects/prjs1222/globgm_output/$GCM/${scenario}/mf6_post $saveDir_proj
    # wait
    # mpirun -np 120 dcp /projects/prjs1222/globgm_output/$GCM/${scenario}/model_input $saveDir_proj
    # wait
    # mpirun -np 120 dcp /projects/prjs1222/globgm_output/$GCM/${scenario}/slurm_logs $saveDir_proj
    # wait

    saveDir=/scratch-shared/globgm_scratch/cmip6_backup/$GCM/$scenario && mkdir -p $saveDir
    input_dir=/projects/prjs1222/globgm_output/_backup/cmip6_runs/$GCM/$scenario
    tar_save_dir=/gpfs/scratch1/shared/globgm_scratch/cmip6_backup/$GCM/$scenario
    # Copy to backup on project space
    mpirun -np 120 dcp $input_dir/forcing_input $saveDir
    wait
    mpirun -np 120 dcp $input_dir/mf6_post $saveDir
    wait
    mpirun -np 120 dcp $input_dir/model_input $saveDir
    wait
    mpirun -np 120 dcp $input_dir/slurm_logs $saveDir
    wait

    cd $saveDir/forcing_input
    forcing_files=("discharge.zarr" "gwAbstraction.zarr" "gwRecharge_correction_factor.zarr" "gwRecharge.zarr")
    for file in "${forcing_files[@]}"; do
        mpirun -np 120 dtar --progress 3 -c -f "$tar_save_dir/forcing_input/${file}.tar" "$tar_save_dir/forcing_input/$file"
        wait
        mpirun -np 120 drm -v "$tar_save_dir/forcing_input/$file"
        wait
    done

    cd $saveDir/mf6_post
    for var in "hds" "wtd"; do
        for i in {1..4}; do
        mpirun -np 120 dtar --progress 3 -c -f  "$tar_save_dir/mf6_post/s0${i}_${var}.zarr.tar" "$tar_save_dir/mf6_post/s0${i}_${var}.zarr"
        wait
        mpirun -np 120 drm -v "$tar_save_dir/mf6_post/s0${i}_${var}.zarr"
        wait
        done
    done
    cd $saveDir
    mpirun -np 120 dtar --progress 3 -c -f $tar_save_dir/slurm_logs.tar $tar_save_dir/slurm_logs
    wait
    mpirun -np 120 drm -v $tar_save_dir/slurm_logs
    wait
    mpirun -np 120 dtar --progress 3 -c -f $tar_save_dir/model_input.tar $tar_save_dir/model_input
    wait
    mpirun -np 120 drm -v $tar_save_dir/model_input
    wait

    cd /projects/prjs1222/GLOBGM/run_simulation/model_job_scripts/dataManagement
    irods_pass='_xPMAN5IDltAA5bC58_nhIcPV40BUt1I'
    logName=${GCM}_${scenario}
    irodsPath="/nluu14p/home/deposit-pilot/globgm/globgm_output/cmip6_runs/${GCM}" 
    sbatch --partition=staging --time=24:00:00 \
           --job-name="${logName}" \
           --output="/projects/prjs1222/GLOBGM/run_simulation/model_job_scripts/dataManagement/slurmOut/${logName}.out" \
           --export=ALL,irods_pass=$irods_pass,irodsPath=$irodsPath --wrap="source ${HOME}/.bashrc && mamba activate globgm && python -u ./_dag.py $irods_pass $saveDir $irodsPath" 
    wait
done