#!/bin/bash -l

module load 2023
module load mpifileutils/0.11.1-gompi-2023a

save_dir=/scratch-shared/globgm_nicole/


# cp /projects/prjs1222/scratch_backup/globgm_scratch/analysis/historical_reference_gswp3-w5e5/validation/output/kge_wtd.parquet $save_dir

# mpirun -np 190 dcp /projects/prjs1222/globgm_output/_backup/historical_with_pump/gswp3-w5e5/forcing_input/gwAbstraction.zarr $save_dir

# HEADS TRANSFER #
# mpirun -np 128 dcp /projects/prjs1222/globgm_output/reference_gswp3-w5e5/historical_with_pump/merged $save_dir/hds_monthly
mpirun -np 128 dchmod --mode 777 $save_dir


#!/bin/bash
#SBATCH -N 1
#SBATCH -t 02:02:00
#SBATCH -p genoa
#SBATCH -J copy_data
#SBATCH --exclusive
#SBATCH -o copy_data.out
#SBATCH -e copy_data.err

module load 2023
module load mpifileutils/0.11.1-gompi-2023a

save_dir=SAVE_DIR_PATH
mkdir -p $save_dir
mpirun -np 192 dcp /scratch-shared/globgm_nicole/hds_monthly/merged/hds.zarr $save_dir


