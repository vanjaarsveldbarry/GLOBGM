#!/bin/bash -l
#SBATCH -N 1
#SBATCH -t 01:00:00
#SBATCH --partition=genoa
#SBATCH --exclusive
#SBATCH --constraint=scratch-node

source ${HOME}/.bashrc
mamba activate globgm

modelRoot=$1
#TILES INPUT
model_input=$(realpath $modelRoot/model_input/1_write_tiled_parameter_data)
forcingDir=$(realpath $modelRoot/forcing_input)
OUT_DIR=$TMPDIR/input_map/steady-state
IN_DIR=$(realpath ../_data/globgm_input)

#SUBMODELS INPUT
exe=$(realpath ../_bin/mf6ggm_181121)
inpmod=mf6_mod_ss.inp
inpexe=mf6ggm_ss.inp
moddir=$modelRoot/mf6_mod
yodaInput=$(realpath ../_data/globgm_input)
inpdir=$(realpath $modelRoot/model_input/3_partition_and_write_model_input/steady-state)
globgmDir=$TMPDIR

cd ../model_tools_src/python/pcr-globwb
counter=0
for ((i=1; i<=163; i+=1)); do
    num=$(printf "%03d" $((10#$i)))
    python deterministic_runner_for_offline_monthly_modflow.py $model_input/steady-state_config.ini debug steady-state-only tile_${num}-163 $IN_DIR $OUT_DIR $forcingDir &
    counter=$((counter+1))
    if [ $counter -eq 30 ]; then
        wait
        counter=0
    fi
done
wait

# COPY UPPER LAYER
for ((i=1; i<=163; i+=1));do
    tile=$(printf "%03d" $i)
    mkdir -p $modelRoot/input_map/steady-state/tile_${tile}-163/steady-state_only/maps && cp "${OUT_DIR}/tile_${tile}-163/steady-state_only/maps/top_uppermost_layer.map" "$modelRoot/input_map/steady-state/tile_${tile}-163/steady-state_only/maps" &
done

mkdir -p $moddir
cp ${inpdir}/${inpmod} ${moddir}/${inpmod}
cp ${inpdir}/${inpexe} ${moddir}/${inpexe}
# #REPLACE NECESSARY STRINGS
sed -i "s|{yoda_input}|${yodaInput}|g" ${moddir}/${inpmod}
sed -i "s|{globgm_dir}|${globgmDir}|g" ${moddir}/${inpmod}
wait
cd ${moddir}

for ((i=1; i<=384; i+=12)); do
    ii=$((i + 11))
    if [ $ii -gt 384 ]; then
        ii=384
    fi
    ${exe} ${inpexe} $i $ii &
done
wait

cd $moddir/glob_ss/log
num_files=$(ls | wc -l)
[ $num_files -eq 384 ] || { echo "Some models are missing"; exit 1; }