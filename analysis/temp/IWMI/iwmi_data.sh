#!/bin/bash -l

module load 2023
module load mpifileutils/0.11.1-gompi-2023a

save_dir=/scratch-shared/IWMI_globgm

cd /projects/prjs1222/globgm_output/_backup
# mpirun -np 191 dtar -x -f historical_with_pump.tar
# mpirun -np 191 dtar -x -f historical_no_pump.tar
# wait

taskset -c 0-191 python /projects/prjs1222/GLOBGM/analysis/temp/IWMI/IWMI.py
wait
