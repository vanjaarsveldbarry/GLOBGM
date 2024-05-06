#!/bin/bash
#SBATCH --exclusive
#SBATCH --nodes=7
#SBATCH --ntasks-per-node=32
#SBATCH --time=04:00:00
#SBATCH --cpus-per-task=1
#SBATCH --gres=cpu:1
#SBATCH --partition=rome
#SBATCH --job-name=run_s01

# load modules
module load 2022
module load OpenMPI/4.1.4-GCC-11.3.0

modelRoot=$1

sol=s01
mod=glob_ss

dir=$modelRoot/mf6_mod/${mod}/solutions/run_output/
exe=$(realpath ./globgm/_bin/mf6_rel_openmpi-4.1.4-gcc-11.3.0)
nam=${sol}.par.mfsim.ic_sh0.nam

cd ${dir}

srun ${exe} -s ../run_input/${nam}
