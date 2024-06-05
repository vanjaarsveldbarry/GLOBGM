#!/bin/bash
#SBATCH --exclusive
#SBATCH --nodes=3
#SBATCH --ntasks-per-node=32
#SBATCH --time=30:00:00
#SBATCH --cpus-per-task=1
#SBATCH --gres=cpu:1
#SBATCH --partition=genoa,rome
#SBATCH --job-name=run_s02

# load modules
module load 2022
module load OpenMPI/4.1.4-GCC-11.3.0

modelRoot=$1

sol=s02
mod=glob_tr

dir=$modelRoot/mf6_mod/${mod}/solutions/run_output/
exe=$(realpath ../_bin/mf6_rel_openmpi-4.1.4-gcc-11.3.0)
nam1=${sol}.par.mfsim.spu.nam
nam2=${sol}.par.mfsim.ic_spu.nam

cd ${dir}

srun ${exe} -s ../run_input/${nam1}
srun ${exe} -s ../run_input/${nam2}
