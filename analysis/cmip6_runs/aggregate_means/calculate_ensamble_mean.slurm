#!/bin/bash -l
#SBATCH --partition=fat_genoa
#SBATCH -N 1
#SBATCH -t 32:00:00
#SBATCH -J ensemble
#SBATCH --cpus-per-task 1 
#SBATCH --ntasks-per-node=192
#SBATCH --exclusive
#SBATCH --output=/projects/prjs1222/GLOBGM/analysis/cmip6_runs/aggregate_means/slurmOut/ensamble_mean.out

source ${HOME}/.bashrc
mamba activate globgm

cd /projects/prjs1222/GLOBGM/analysis/cmip6_runs/aggregate_means


#Calculate annual ensamble mean 
# taskset -c 0-15 python -u ./ensamble_mean.py "historical" "hds" & \
# taskset -c 16-31 python -u ./ensamble_mean.py "historical" "wtd" & \
# taskset -c 32-47 python -u ./ensamble_mean.py "ssp126" "hds" & \
# taskset -c 48-63 python -u ./ensamble_mean.py "ssp126" "wtd" & \
# taskset -c 64-79 python -u ./ensamble_mean.py "ssp370" "hds" & \
# taskset -c 80-95 python -u ./ensamble_mean.py "ssp370" "wtd" & \
# taskset -c 96-111 python -u ./ensamble_mean.py "ssp585" "hds" & \
# taskset -c 112-127 python -u ./ensamble_mean.py "ssp585" "wtd"
# wait
# scenarios=("historical" "ssp126" "ssp370" "ssp585")
# for scenario in "${scenarios[@]}"; do
#     taskset -c 0-191 python -u ./_rechunk_ensamble.py "${scenario}" "hds"
#     echo "Rechunking done for ${scenario} hds"
#     wait

#     taskset -c 0-191 python -u ./_rechunk_ensamble.py "${scenario}" "wtd"
#     wait
#     echo "Rechunking done for ${scenario} wtd"
# done
# wait
#calculate the longterm mean
# taskset -c 0-191 python -u /projects/prjs1222/GLOBGM/analysis/cmip6_runs/aggregate_means/ensamble_mean_average.py
# wait

#calculate monthly ensemble mean
# taskset -c 0-23 python -u ./ensamble_mean_monthly.py "historical" "hds" & \
# taskset -c 24-47 python -u   ./ensamble_mean_monthly.py "historical" "wtd" & \
# taskset -c 48-71 python -u   ./ensamble_mean_monthly.py "ssp126" "hds" & \
# taskset -c 72-95 python -u   ./ensamble_mean_monthly.py "ssp126" "wtd" & \
# taskset -c 96-119 python -u   ./ensamble_mean_monthly.py "ssp370" "hds" & \
# taskset -c 120-143 python -u   ./ensamble_mean_monthly.py "ssp370" "wtd" & \
# taskset -c 144-167 python -u  ./ensamble_mean_monthly.py "ssp585" "hds" & \
# taskset -c 168-191 python -u ./ensamble_mean_monthly.py "ssp585" "wtd"
# wait

# scenarios=("historical" "ssp126" "ssp370" "ssp585")
scenarios=("ssp126" "ssp370" "ssp585")
for scenario in "${scenarios[@]}"; do

    taskset -c 0-95 python -u ./ensamble_mean_monthly.py $scenario "hds" & \
    taskset -c 96-191 python -u   ./ensamble_mean_monthly.py $scenario "wtd" &
    wait

    taskset -c 0-191 python -u ./_rechunk_ensamble.py "${scenario}" "hds"
    echo "Rechunking done for ${scenario} hds"
    wait

    taskset -c 0-191 python -u ./_rechunk_ensamble.py "${scenario}" "wtd"
    wait
    echo "Rechunking done for ${scenario} wtd"
done
wait