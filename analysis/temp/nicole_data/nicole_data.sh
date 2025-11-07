#!/bin/bash -l

module load 2023
module load mpifileutils/0.11.1-gompi-2023a

save_dir=/scratch-shared/globgm_nicole/

# mpirun -np 190 dcp /projects/prjs1222/globgm_output/reference_gswp3-w5e5/historical_with_pump/annual $save_dir

# cp /projects/prjs1222/scratch_backup/globgm_scratch/analysis/historical_reference_gswp3-w5e5/validation/output/kge_wtd.parquet $save_dir

# mpirun -np 190 dcp /projects/prjs1222/globgm_output/_backup/historical_with_pump/gswp3-w5e5/forcing_input/gwAbstraction.zarr $save_dir

mpirun -np 190 dchmod --mode 777 $save_dir