#!/bin/bash -l
#SBATCH -N 1
#SBATCH -t 01:00:00
#SBATCH --partition=genoa
#SBATCH --cpus-per-task=16

source ${HOME}/.bashrc
mamba activate globgm

modelRoot=$1

model_input=$(realpath $modelRoot/model_input/1_write_tiled_parameter_data)
forcingDir=$(realpath $modelRoot/forcing_input)
gwRechargeFile=$(find "$forcingDir" -type f -name "*gwRecharge*"); dischargeFile=$(find "$forcingDir" -type f -name "*discharge*")

OUT_DIR=$modelRoot/input_map/steady-state
IN_DIR=$(realpath ./globgm/_data/globgm_input)

cd ./globgm/model_tools_src/python/pcr-globwb

one=$(printf "%03d" ${SLURM_ARRAY_TASK_ID#0})
two=$(printf "%03d" $((10#$one + 1)))
three=$(printf "%03d" $((10#$one + 2)))

if (( 10#$one >= 163 )); then
    python deterministic_runner_for_offline_monthly_modflow.py $model_input/steady-state_config.ini debug steady-state-only tile_${one}-163 $IN_DIR $OUT_DIR $dischargeFile $gwRechargeFile &
    wait
else
    python deterministic_runner_for_offline_monthly_modflow.py $model_input/steady-state_config.ini debug steady-state-only tile_${one}-163 $IN_DIR $OUT_DIR $dischargeFile $gwRechargeFile  &
    python deterministic_runner_for_offline_monthly_modflow.py $model_input/steady-state_config.ini debug steady-state-only tile_${two}-163 $IN_DIR $OUT_DIR $dischargeFile $gwRechargeFile  &
    python deterministic_runner_for_offline_monthly_modflow.py $model_input/steady-state_config.ini debug steady-state-only tile_${three}-163 $IN_DIR $OUT_DIR $dischargeFile $gwRechargeFile  &
    wait
fi