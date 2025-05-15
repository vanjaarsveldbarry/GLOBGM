#!/bin/bash -l
#SBATCH --partition=fat_genoa
#SBATCH -N 1
#SBATCH -t 03:00:00
#SBATCH -J aggMeans
#SBATCH --cpus-per-task 1 
#SBATCH --ntasks-per-node=192
#SBATCH --exclusive
#SBATCH --output=/projects/prjs1222/GLOBGM/analysis/cmip6_runs/aggregate_means/slurmOut/aggMeans_reference%a.out
#SBATCH --array=1-2

source ${HOME}/.bashrc
mamba activate globgm

cd /projects/prjs1222/GLOBGM/analysis/cmip6_runs/aggregate_means
echo $SLURM_ARRAY_TASK_ID
models=("historical_no_pump" "historical_with_pump")
counter=1
for model in "${models[@]}"; do
    if [ $counter -eq $SLURM_ARRAY_TASK_ID ]; then
        echo "Processing model: $model"
        taskset -c 0-63 python -u ./aggregate_means_reference.py $model
    fi
    ((counter++))
done
