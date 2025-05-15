#!/bin/bash -l
#SBATCH --partition=fat_genoa
#SBATCH -N 1
#SBATCH -t 12:00:00
#SBATCH --cpus-per-task=1
#SBATCH --ntasks-per-node=192
#SBATCH --output=/projects/prjs1222/GLOBGM/analysis/cmip6_runs/thiel_sen_slope/slurmOut/thiel_sen_gcm_%a.out
#SBATCH --array=1-4

source ${HOME}/.bashrc
mamba activate globgm

cd /projects/prjs1222/GLOBGM/analysis/cmip6_runs/thiel_sen_slope
export NUMBA_NUM_THREADS=191

input_dir=/projects/prjs1222/globgm_output/cmip6_runs/ensemble_means
scenarios=("ssp126" "ssp370" "ssp585" "historical")
counter=1
for scenario in "${scenarios[@]}"; do
    if [ $counter -eq $SLURM_ARRAY_TASK_ID ]; then
        input_dir_scenario="${input_dir}/${scenario}"
        echo $input_dir_scenario
        taskset -c 0-191 python -u ./calc_thiel_sen_slope.py $input_dir_scenario "hds" "${scenario}"
        wait
        # taskset -c 0-191 python -u ./calc_thiel_sen_slope.py $input_dir_scenario "wtd" "${scenario}"
        # wait
    fi
    counter=$((counter+1))
done