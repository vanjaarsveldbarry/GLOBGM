#!/bin/bash -l
#SBATCH --partition=staging
#SBATCH -N 1
#SBATCH -t 32:00:00
#SBATCH -J _yoda
#SBATCH --cpus-per-task 2 
#SBATCH --ntasks-per-node=1
#SBATCH --output=/projects/prjs1222/GLOBGM/analysis/_yoda_archive/upload_hist.out

module load 2023
module load iRODS-iCommands/4.3.0 

source ${HOME}/.bashrc
mamba activate globgm

cd /projects/prjs1222/GLOBGM/analysis/_yoda_archive

# python -u upload_data_hist.py average
# wait
# python -u upload_data_hist.py annual
# wait

# save_annual=/nluu11p/home/research-geowat-simulations/globgm_cmip6/reference_gswp3-w5e5/annual
# imkdir -p $save_annual
# iput -PfTv -N 10 /projects/prjs1222/scratch_backup/globgm_scratch/archive/reference_gswp3-w5e5/annual/hds_reference_gswp3-w5e5_annual_1960_2019.zarr.zip $save_annual
# iput -PfTv -N 10 /projects/prjs1222/scratch_backup/globgm_scratch/archive/reference_gswp3-w5e5/annual/wtd_reference_gswp3-w5e5_annual_1960_2019.zarr.zip $save_annual


save_monthly=/nluu11p/home/research-geowat-simulations/globgm_cmip6/reference_gswp3-w5e5/monthly
imkdir -p $save_monthly
# iput -PfTv -N 10 /projects/prjs1222/scratch_backup/globgm_scratch/archive/reference_gswp3-w5e5/monthly/hds_reference_gswp3-w5e5_monthly_1960_2019.zarr.zip $save_monthly
iput -PfTv -N 10 /projects/prjs1222/scratch_backup/globgm_scratch/archive/reference_gswp3-w5e5/monthly/wtd_reference_gswp3-w5e5_monthly_1960_2019.zarr.zip $save_monthly



