#!/bin/bash -l
#SBATCH -N 1
#SBATCH -t 01:00:00
#SBATCH --partition=rome
#SBATCH --cpus-per-task=16

source ${HOME}/.bashrc
mamba activate globgm

modelRoot=$1
modelScratch=$2

model_input=$(realpath $modelScratch/model_input/1_write_tiled_parameter_data)
forcingDir=$(realpath $modelScratch/forcing_input)

OUT_DIR=$modelScratch/input_map/steady-state
IN_DIR=$(realpath ../_data/globgm_input)

cd ../model_tools_src/python/pcr-globwb

one=$(printf "%03d" ${SLURM_ARRAY_TASK_ID#0})
two=$(printf "%03d" $((10#$one + 1)))
three=$(printf "%03d" $((10#$one + 2)))

if (( 10#$one >= 163 )); then
    python deterministic_runner_for_offline_monthly_modflow.py $model_input/steady-state_config.ini debug steady-state-only tile_${one}-163 $IN_DIR $OUT_DIR $forcingDir &

else
    python deterministic_runner_for_offline_monthly_modflow.py $model_input/steady-state_config.ini debug steady-state-only tile_${one}-163 $IN_DIR $OUT_DIR $forcingDir &
    python deterministic_runner_for_offline_monthly_modflow.py $model_input/steady-state_config.ini debug steady-state-only tile_${two}-163 $IN_DIR $OUT_DIR $forcingDir &
    python deterministic_runner_for_offline_monthly_modflow.py $model_input/steady-state_config.ini debug steady-state-only tile_${three}-163 $IN_DIR $OUT_DIR $forcingDir &
    wait
fi
wait


if (( 10#$one >= 163 )); then
    mkdir -p $modelRoot/input_map/steady-state/tile_${one}-163/steady-state_only/maps && cp "${OUT_DIR}/tile_${one}-163/steady-state_only/maps/top_uppermost_layer.map" "$modelRoot/input_map/steady-state/tile_${one}-163/steady-state_only/maps"

else
    mkdir -p $modelRoot/input_map/steady-state/tile_${one}-163/steady-state_only/maps && cp "${OUT_DIR}/tile_${one}-163/steady-state_only/maps/top_uppermost_layer.map" "$modelRoot/input_map/steady-state/tile_${one}-163/steady-state_only/maps"
    mkdir -p $modelRoot/input_map/steady-state/tile_${two}-163/steady-state_only/maps && cp "${OUT_DIR}/tile_${two}-163/steady-state_only/maps/top_uppermost_layer.map" "$modelRoot/input_map/steady-state/tile_${two}-163/steady-state_only/maps"
    mkdir -p $modelRoot/input_map/steady-state/tile_${three}-163/steady-state_only/maps && cp "${OUT_DIR}/tile_${three}-163/steady-state_only/maps/top_uppermost_layer.map" "$modelRoot/input_map/steady-state/tile_${three}-163/steady-state_only/maps"
fi
wait
