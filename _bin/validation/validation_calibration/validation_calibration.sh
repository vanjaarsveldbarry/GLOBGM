#!/bin/bash
#SBATCH --job-name=bias_calculation
#SBATCH --output=/projects/0/einf4705/workflow/GLOBGM/validation/validation_calibration/slurmOut/validation.out
#SBATCH --exclusive
#SBATCH --time=02:00:00
#SBATCH -p fat_genoa

source ${HOME}/.bashrc
mamba activate globgm

output_dir=/projects/0/einf4705/workflow/output_validation/validation_calibration
sim_dir=/scratch-shared/bvjaarsv
main_dir=/projects/0/einf4705/workflow/GLOBGM/validation/validation_calibration
osbserved_shapefile=$main_dir/data/observed_gwh_for_ss_val_ex_hotspots.gpkg

cd $main_dir
python scripts/validation_globgm.py $output_dir $sim_dir $osbserved_shapefile
wait
python scripts/plot_cdf.py $output_dir
