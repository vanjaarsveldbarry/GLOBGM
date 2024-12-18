#!/bin/bash -l
#SBATCH -N 1
#SBATCH -t 06:00:00
#SBATCH --partition=fat_genoa
#SBATCH --exclusive
#SBATCH --constraint=scratch-node

df -BG $TMPDIR

source ${HOME}/.bashrc
mamba activate globgm

modelRoot=$1
id=$2
solution=$3
runType=$4
dataDir=$5
outFile=$6
iniFileName=$7

exe=$dataDir/_bin/mf6ggm_181121
model_input=$modelRoot/model_input/2_partition_and_write_model_input/transient
moddir=$modelRoot/mf6_mod/mf6_mod_${id}
inpmod=mf6_mod_tr.inp
inpexe=mf6ggm_tr.inp

_tempDir=$TMPDIR/_temp
mkdir -p $_tempDir

# module load 2023
# module load mpifileutils/0.11.1-gompi-2023a
# mpirun -np 160 dcp --progress 5 $dataDir/globgm_input $_tempDir
# wait
# mpirun -np 160 dcp --progress 5 $modelRoot/forcing_input $_tempDir
# wait
# ls -lah $_tempDir

# IN_DIR=$_tempDir/globgm_input
# forcingDir=$_tempDir/forcing_input
# globgmDir=$modelRoot

# OUT_DIR=$modelRoot/input_map/transient

# START_DATE=$(grep 'STARTDATE' ${moddir}/${inpmod} | awk '{print $2}')
# nMonths=$(grep 'NPER' ${moddir}/${inpmod} | awk '{print $2}')
# PCR_GLOB_dir=$(realpath ../model_tools_src/python/pcr-globwb)
# cd $PCR_GLOB_dir
# cp $model_input/${iniFileName} $TMPDIR/${iniFileName}
# wait 

# for ((i=1; i<=163; i+=1)); do
#     num=$(printf "%03d" $((10#$i)))
#     python deterministic_runner_for_monthly_offline_globgm.py $TMPDIR/${iniFileName} debug transient tile_${num}-163 $IN_DIR $OUT_DIR $forcingDir $START_DATE $nMonths &
# done

wait
touch $outFile
