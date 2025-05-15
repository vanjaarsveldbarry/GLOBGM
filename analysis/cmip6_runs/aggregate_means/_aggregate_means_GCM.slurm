#!/bin/bash -l
#SBATCH --partition=fat_genoa
#SBATCH -N 1
#SBATCH -t 12:00:00
#SBATCH -J aggMeans
#SBATCH --ntasks=192
#SBATCH --cpus-per-task=1
#SBATCH --output=/projects/prjs1222/GLOBGM/analysis/cmip6_runs/aggregate_means/slurmOut/aggMeans_%a.out
#SBATCH --array=2-5

source ${HOME}/.bashrc
mamba activate globgm

cd /projects/prjs1222/GLOBGM/analysis/cmip6_runs/aggregate_means

counter=1
core_start=0
core_end=47
core_increment=48

models=("gfdl-esm4" "mpi-esm1-2-hr" "mri-esm2-0" "ukesm1-0-ll" "ipsl-cm6a-lr")
for model in "${models[@]}"; do
    if [ $counter -eq $SLURM_ARRAY_TASK_ID ]; then
        _counter=1
        scenarios=("ssp126" "ssp370" "ssp585" "historical")
        for scenario in "${scenarios[@]}"; do
            echo $core_start $core_end
            taskset -c $core_start-$core_end python -u ./aggregate_means_GCM.py $model $scenario &
            core_start=$(($core_start + $core_increment))
            core_end=$(($core_end + $core_increment))
        done
    fi
    ((counter++))
done
wait

counter=1
for model in "${models[@]}"; do
    if [ $counter -eq $SLURM_ARRAY_TASK_ID ]; then
        scenarios=("ssp126" "ssp370" "ssp585" "historical")
        for scenario in "${scenarios[@]}"; do
            taskset -c 0-191 python -u ./_rechunk.py $model $scenario
            echo $model $scenario
            wait
        done
    fi
    ((counter++))
done
wait