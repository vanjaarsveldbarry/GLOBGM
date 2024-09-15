#!/bin/bash
#SBATCH --exclusive
#SBATCH --nodes=3
#SBATCH --ntasks-per-node=32
#SBATCH --time=00:30:00
#SBATCH --cpus-per-task=1
#SBATCH --gres=cpu:1
#SBATCH --partition=rome
#SBATCH --job-name=run_s02

# load modules
module load 2022
module load OpenMPI/4.1.4-GCC-11.3.0

modelRoot=$1
model_job_scripts=$2
slurmDir_ss=$3
outFile=$4
dir=$modelRoot/mf6_mod/glob_ss/solutions/run_output/
exe=$(realpath ../_bin/mf6_rel_openmpi-4.1.4-gcc-11.3.0)
nam=s02.par.mfsim.ic_sh0.nam
startDir=$(pwd)

cd ${dir}
srun ${exe} -s ../run_input/${nam}
wait

#Post process files
cd $startDir
run_script_post_ss=$model_job_scripts/4_post-processing/steady-state/04_post_globgm_ss.slurm
sbatch -o $slurmDir_ss/4_post-processing/4_post_globgm_2.out $run_script_post_ss $modelRoot 2 "${outFile}_2"