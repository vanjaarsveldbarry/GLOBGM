#!/bin/bash -l
#SBATCH --partition=staging
#SBATCH -N 1
#SBATCH -t 110:00:00
#SBATCH -J _yoda_gcm
#SBATCH --cpus-per-task 3
#SBATCH --ntasks-per-node=1
#SBATCH --output=/projects/prjs1222/GLOBGM/analysis/_yoda_archive/upload_GCM.out

module load 2023
module load iRODS-iCommands/4.3.0 
module load mpifileutils/0.11.1-gompi-2023a

source ${HOME}/.bashrc
mamba activate globgm

cd /projects/prjs1222/GLOBGM/analysis/_yoda_archive

# python -u upload_data_GCM.py average
# wait


save_dir=/nluu11p/home/research-geowat-simulations/globgm_cmip6/cmip6/GCM/annual
input_dir=/projects/prjs1222/scratch_backup/globgm_scratch/archive/cmip6/GCM/annual

imkdir -p $save_dir
for file in "$input_dir"/*; do
    echo "Processing file: $(basename "$file")"
    iput -PfT -N 3 $file $save_dir
done

