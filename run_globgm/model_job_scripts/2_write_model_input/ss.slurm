#!/bin/bash -l
#SBATCH -N 1
#SBATCH -t 00:45:00
#SBATCH --partition=genoa

source ${HOME}/.bashrc
mamba activate globgm
scriptRoot=$(pwd)

startTile=$SLURM_ARRAY_TASK_ID
endTile=$((SLURM_ARRAY_TASK_ID + 9))
if [ $endTile -gt 163 ]; then
    endTile=163
fi

modelRoot=$1
tempDir=$TMPDIR/job_${startTile}
mkdir -p $tempDir

# #WRITE THE TILE SUBMODULE NEEDS
model_input=$(realpath $modelRoot/model_input)
forcingDir=$(realpath $modelRoot/forcing_input)
cp -r $model_input $tempDir

OUT_DIR=$tempDir/input_map/steady-state
IN_DIR=$(realpath ../_data/globgm_input)

cd ../model_tools_src/python/pcr-globwb

if [ "$startTile" -eq 1 ]; then
    dummyTile=163
else
    dummyTile=$(printf "%03d" 1)
fi

# WRITE TILES
python deterministic_runner_for_offline_monthly_modflow.py $tempDir/model_input/1_write_tiled_parameter_data/steady-state_config.ini debug steady-state-only tile_${dummyTile}-163 $IN_DIR $OUT_DIR/dummy $forcingDir &
for ((i=$startTile; i<=$endTile; i++));do
    tile=$(printf "%03d" $i)
    python deterministic_runner_for_offline_monthly_modflow.py $tempDir/model_input/1_write_tiled_parameter_data/steady-state_config.ini debug steady-state-only tile_${tile}-163 $IN_DIR $OUT_DIR $forcingDir &
done
wait

# COPY UPPER LAYER
for ((i=$startTile; i<=$endTile; i++));do
    tile=$(printf "%03d" $i)
    mkdir -p $modelRoot/input_map/steady-state/tile_${tile}-163/steady-state_only/maps && cp "${OUT_DIR}/tile_${tile}-163/steady-state_only/maps/top_uppermost_layer.map" "$modelRoot/input_map/steady-state/tile_${tile}-163/steady-state_only/maps" &
done

# CREATE SYMLINKS
cd $OUT_DIR
for ((i=1; i<=163; i++));do
    dir=$(printf "./tile_%03d-163/steady-state_only/maps" $i)
    if [ -d "$dir" ]; then
        echo "Directory $dir exists."
    else
        mkdir -p "$dir"
        falseFolder=$OUT_DIR/dummy/tile_${dummyTile}-163/steady-state_only/maps
        for file in "$falseFolder"/*; do
            ln -s "$file" "$dir"
        done
    fi
done
wait

# ####WRITE MODFLOW FILES
cd $scriptRoot
inpdir=$(realpath $modelRoot/model_input/3_partition_and_write_model_input/steady-state/)
exe=$(realpath ../_bin/mf6ggm_181121)
inpmod=mf6_mod_ss.inp
inpexe=mf6ggm_ss.inp
moddir=$modelRoot/mf6_mod
yodaInput=$(realpath ../_data/globgm_input)
configFile=$tempDir/model_input/3_partition_and_write_model_input/steady-state/config.txt

mkdir -p $moddir
cd ${moddir}

for ((i=$startTile; i<=$endTile; i++));do
    (
        cp ${inpdir}/${inpmod} ${moddir}/mf6_mod_ss_${i}.inp
        cp ${inpdir}/${inpexe} ${moddir}/mf6ggm_ss_${i}.inp

        # # #REPLACE NECESSARY STRINGS
        sed -i "s|{yoda_input}|${yodaInput}|g" ${moddir}/mf6_mod_ss_${i}.inp
        sed -i "s|{globgm_dir}|${tempDir}|g" ${moddir}/mf6_mod_ss_${i}.inp
        sed -i "s|{ID}|${i}|g" ${moddir}/mf6ggm_ss_${i}.inp

        input_sub=${moddir}/mf6ggm_ss_${i}.inp
        models=$(awk -v task_id=${i} -F' ' '$1 == task_id {print $2}' ${configFile})
        models=$(echo $models | tr ',' ' ')

        for model in $models; do
            ${exe} ${input_sub} $model $model &
        done
        wait
    ) &
done  
wait

for ((i=$startTile; i<=$endTile; i++));do
    rm ${moddir}/mf6_mod_ss_${i}.inp
    rm ${moddir}/mf6ggm_ss_${i}.inp
done 