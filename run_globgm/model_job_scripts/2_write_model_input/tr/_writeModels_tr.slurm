#!/bin/bash -l
#SBATCH -N 1
#SBATCH -t 72:00:00
#SBATCH --partition=fat_genoa
#SBATCH --exclusive
#SBATCH --constraint=scratch-node

df -kh $TMPDIR

source ${HOME}/.bashrc
mamba activate globgm

modelRoot=$1
PCR_GLOB_dir=$(realpath ../model_tools_src/python/pcr-globwb)
end_year=$3
solution=$4
#HACK
globgmDir=$TMPDIR
exe=$(realpath ../_bin/mf6ggm_181121)
inpmod=mf6_mod_tr.inp
inpexe=mf6ggm_tr.inp
moddir=$modelRoot/mf6_mod/mf6_mod_${end_year}

model_input=$(realpath $modelRoot/model_input/1_write_tiled_parameter_data)
forcingDir=$(realpath $modelRoot/forcing_input)
OUT_DIR=$TMPDIR/input_map/transient
IN_DIR=$(realpath ../_data/globgm_input)
nMonths=$(grep 'NPER' ${moddir}/${inpmod} | awk '{print $2}')
START_DATE=$(grep 'STARTDATE' ${moddir}/${inpmod} | awk '{print $2}')

cd $PCR_GLOB_dir
cp $model_input/transient_config.ini $TMPDIR/transient_config.ini
wait 
time (
for ((i=1; i<=163; i+=1)); do
    num=$(printf "%03d" $((10#$i)))
    python deterministic_runner_for_offline_monthly_modflow.py $TMPDIR/transient_config.ini debug transient tile_${num}-163 $IN_DIR $OUT_DIR $forcingDir $START_DATE $nMonths &
done
wait
)

cp ${moddir}/${inpmod} ${moddir}/${inpmod}_${solution}_${SLURM_ARRAY_TASK_ID}_${end_year}
cp ${moddir}/${inpexe} ${moddir}/${inpexe}_${solution}_${SLURM_ARRAY_TASK_ID}_${end_year}

inputStr=mf6_mod_tr.inp_${solution}_${SLURM_ARRAY_TASK_ID}_${end_year}
sed -i "s|mf6_mod_tr.inp|${inputStr}|g" ${moddir}/${inpexe}_${solution}_${SLURM_ARRAY_TASK_ID}_${end_year}
sed -i "s|INPUT_DIST_DIR ${modelRoot}|INPUT_DIST_DIR ${globgmDir}|g" ${moddir}/${inpmod}_${solution}_${SLURM_ARRAY_TASK_ID}_${end_year}
wait 

cd ${moddir}

if [ $solution -eq 1 ]; then
    startMod=1
    endMod=224
fi

if [ $solution -eq 2 ]; then
    startMod=225
    endMod=320
fi

if [ $solution -eq 3 ]; then
    startMod=321
    endMod=352
fi

if [ $solution -eq 4 ]; then
    startMod=353
    endMod=384
fi
time (
for ((i=$startMod; i<=$endMod; i+=2)); do
    ii=$((i + 1))
    if [ $ii -gt 384 ]; then
        ii=384
    fi
    ${exe} ${inpexe}_${solution}_${SLURM_ARRAY_TASK_ID}_${end_year} $i $ii &
done
wait
)

if [ $solution -eq 3 ]; then
    for ((i=1; i<=163; i+=1));do
        tile=$(printf "%03d" $i)
        mkdir -p $modelRoot/input_map/transient/tile_${tile}-163/transient/maps && cp "${OUT_DIR}/tile_${tile}-163/transient/maps/top_uppermost_layer.map" "$modelRoot/input_map/transient/tile_${tile}-163/transient/maps" &
    done
fi
wait
rm ${moddir}/${inpexe}_${solution}_${SLURM_ARRAY_TASK_ID}_${end_year}
rm ${moddir}/${inpmod}_${solution}_${SLURM_ARRAY_TASK_ID}_${end_year}
wait
df -kh $TMPDIR