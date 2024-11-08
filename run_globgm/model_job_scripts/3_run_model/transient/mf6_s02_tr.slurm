#!/bin/bash
#SBATCH --exclusive
#SBATCH --nodes=3
#SBATCH --ntasks-per-node=32
#SBATCH --time=02:00:00
#SBATCH --cpus-per-task=1
#SBATCH --gres=cpu:1
#SBATCH --partition=genoa,rome
#SBATCH --job-name=run_s02

# load modules
module load 2023
module load OpenMPI/4.1.5-GCC-12.3.0
source ${HOME}/.bashrc
mamba activate globgm

modelRoot=$1
runType=$2
solution=$3
simStart=$4
simEnd=$5
label=$6
dataDir=$7
outFile=$8

if [ "$runType" = "start" ]; then
    to_zarrFolder=$(realpath ../model_tools_src/python/to_zarr)
    postDir=$modelRoot/mf6_post
    mkdir -p $postDir
    python -u $to_zarrFolder/createZarr_tr.py $dataDir $solution $postDir $simStart $simEnd wtd & 
    python -u $to_zarrFolder/createZarr_tr.py $dataDir $solution $postDir $simStart $simEnd hds
    wait
fi

iniConditionsScript=$(realpath ../model_tools_src/python/initial_states/initial_states.py)
exe=$dataDir/_bin/mf6_rel_openmpi-4.1.4-gcc-11.3.0
nam1=s02.par.mfsim.spu.nam
nam2=s02.par.mfsim.ic_spu.nam

dir_run=$modelRoot/mf6_mod/mf6_mod_${label}/glob_tr/solutions/run_output/
cd ${dir_run}

if [ "$runType" = "start" ]; then
    srun ${exe} -s ../run_input/${nam1}
fi
srun ${exe} -s ../run_input/${nam2}
wait
python $iniConditionsScript $dir_run
wait
touch $outFile