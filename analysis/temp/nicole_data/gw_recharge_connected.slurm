#!/bin/bash -l
#SBATCH --partition=fat_genoa
#SBATCH -N 1
#SBATCH -t 12:00:00
#SBATCH --cpus-per-task=1
#SBATCH --ntasks-per-node=192
#SBATCH --output=/projects/prjs1222/GLOBGM/analysis/temp/nicole_data/gw_recharge_connected.out

module load 2023
module load mpifileutils/0.11.1-gompi-2023a

source ${HOME}/.bashrc
mamba activate globgm

# cd /projects/prjs1222/globgm_output/_backup
# mpirun -np 190 dtar -x -f /projects/prjs1222/globgm_output/_backup/historical_with_pump.tar


cd /projects/prjs1222/GLOBGM/analysis/temp/nicole_data
taskset -c 0-191 python -u gwRecharge_corrected.py 
wait