#!/bin/bash
#SBATCH --exclusive
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=32
#SBATCH --time=16:00:00
#SBATCH --cpus-per-task=1
#SBATCH --gres=cpu:1
#SBATCH --partition=genoa,rome
#SBATCH --job-name=run_s04

# load modules
module load 2022
module load OpenMPI/4.1.4-GCC-11.3.0

modelRoot=$1
model_job_scripts=$2
modDir=$modelRoot/mf6_mod
exe=$(realpath ../_bin/mf6_rel_openmpi-4.1.4-gcc-11.3.0)
nam1=s04.par.mfsim.spu.nam
nam2=s04.par.mfsim.ic_spu.nam

mod=glob_tr
directories=$(find $modDir -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort -t '_' -k2,2n)
# counter=0
# for mod_dir in $directories; do
#     counter=$((counter+1))
#     dir=$modelRoot/mf6_mod/$mod_dir/${mod}/solutions/run_output/
#     cd ${dir}

#     if [ $counter -eq 1 ]; then
#         srun ${exe} -s ../run_input/${nam1}
#     fi
#     srun ${exe} -s ../run_input/${nam2}
# done
wait
cd $startDir
run_script_post_tr=$model_job_scripts/4_post-processing/transient/04_post_globgm_tr.slurm
for mod_dir in $directories; do
    counter=$((counter+1))
    dir=$modelRoot/mf6_mod/$mod_dir/${mod}
    sbatch -o $slurmDir_tr/4_post-processing/4_post_globgm_4.out $run_script_post_tr $modelRoot 4 $start_year $end_year $dir
done