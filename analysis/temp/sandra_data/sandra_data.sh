#!/bin/bash -l

module load 2023
module load mpifileutils/0.11.1-gompi-2023a

save_dir=/scratch-shared/globgm_sandra/

# mpirun -np 190 dcp /projects/prjs1222/globgm_output/_backup/historical_with_pump/gswp3-w5e5/forcing_input/gwAbstraction.zarr $save_dir
# mpirun -np 190 dcp /projects/prjs1222/globgm_output/_backup/historical_with_pump/gswp3-w5e5/forcing_input/discharge.zarr $save_dir


taskset -c 0-191 python -u /projects/prjs1222/GLOBGM/analysis/temp/sandra_data/gwRecharge_corrected.py --save_dir $save_dir
# mpirun -np 190 dchmod --mode 777 $save_dir

# /scratch/depfg/globgm_temp