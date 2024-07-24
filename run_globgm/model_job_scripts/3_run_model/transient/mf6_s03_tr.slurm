#!/bin/bash
#SBATCH --exclusive
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=32
#SBATCH --time=16:00:00
#SBATCH --cpus-per-task=1
#SBATCH --gres=cpu:1
#SBATCH --partition=genoa
#SBATCH --job-name=run_s03

# load modules
module load 2022
module load OpenMPI/4.1.4-GCC-11.3.0
source ${HOME}/.bashrc
mamba activate globgm

startDir=$(pwd)
modelRoot=$1
solution=3
model_job_scripts=$2
slurmDir_tr=$3
start_year=$4 
end_year=$5

modDir=$modelRoot/mf6_mod
iniConditionsScript=$(realpath ../model_tools_src/python/initial_states/initial_states.py)
exe=$(realpath ../_bin/mf6_rel_openmpi-4.1.4-gcc-11.3.0)
nam1=s03.par.mfsim.spu.nam
nam2=s03.par.mfsim.ic_spu.nam
mod=glob_tr

to_zarrFolder=$(realpath ../model_tools_src/python/to_zarr)
_zarrWriter=$(realpath ./4_post-processing/transient/_zarrWriter.slurm)
postDir=$modelRoot/mf6_post
mkdir -p $postDir

python -u $to_zarrFolder/createZarr_tr.py $modelRoot $solution $postDir $start_year $end_year wtd & 
python -u $to_zarrFolder/createZarr_tr.py $modelRoot $solution $postDir $start_year $end_year hds
wait    

directories=$(find $modDir -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort -t '_' -k2,2n)
counter=0
for mod_dir in $directories; do
    counter=$((counter+1))
    dir_run=$modelRoot/mf6_mod/$mod_dir/${mod}/solutions/run_output/
    cd ${dir_run}

    if [ $counter -eq 1 ]; then
        srun ${exe} -s ../run_input/${nam1}
    fi
    srun ${exe} -s ../run_input/${nam2}
    python $iniConditionsScript $dir_run
    wait

    cd $startDir
    dir=$modelRoot/mf6_mod/$mod_dir/${mod}
    modName=$(basename $(dirname $dir))
    iniFile=$(dirname $dir)/mf6_mod_tr.inp
    nper=$(grep "NPER" $iniFile | awk '{print $2}')
    startYear=$(grep "STARTDATE" $iniFile | awk '{print $2}')
    startYear=${startYear:0:4}
    nper=$(($nper / 12))
    endYear=$(($startYear + $nper - 1))
    sbatch --partition=genoa -o $slurmDir_tr/4_post-processing/_s0${solution}_zarrWriter/${solution}_${modName}_wtd.out $_zarrWriter $modelRoot wtd $solution $startYear $endYear $dir
    sbatch --partition=genoa -o $slurmDir_tr/4_post-processing/_s0${solution}_zarrWriter/${solution}_${modName}_hds.out $_zarrWriter $modelRoot hds $solution $startYear $endYear $dir
    wait
    if [ $counter -eq 2 ]; then
        break
    fi
done