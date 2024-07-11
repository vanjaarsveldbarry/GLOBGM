#!/bin/bash
#SBATCH --exclusive
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=32
#SBATCH --time=16:00:00
#SBATCH --cpus-per-task=1
#SBATCH --gres=cpu:1
#SBATCH --partition=genoa,rome
#SBATCH --job-name=run_s03

# load modules
module load 2022
module load OpenMPI/4.1.4-GCC-11.3.0

modelRoot=$1
model_job_scripts=$2
modDir=$modelRoot/mf6_mod
exe=$(realpath ../_bin/mf6_rel_openmpi-4.1.4-gcc-11.3.0)
nam1=${sol}.par.mfsim.spu.nam
nam2=${sol}.par.mfsim.ic_spu.nam
sol=s03

mod=glob_tr
directories=$(find $modDir -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort -t '_' -k2,2n)
counter=0
for mod_dir in $directories; do
    counter=$((counter+1))
    dir=$modelRoot/mf6_mod/$mod_dir/${mod}/solutions/run_output/
    if [ $counter -eq 1 ]; then
        srun ${exe} -s ../run_input/${nam1}
    fi
    srun ${exe} -s ../run_input/${nam2}
done




# dir=$modelRoot/mf6_mod/mf6_mod_2013/${mod}/solutions/run_output/
# exe=$(realpath ../_bin/mf6_rel_openmpi-4.1.4-gcc-11.3.0)
# nam1=${sol}.par.mfsim.spu.nam
# nam2=${sol}.par.mfsim.ic_spu.nam

# cd ${dir}

# srun ${exe} -s ../run_input/${nam1}
# srun ${exe} -s ../run_input/${nam2}
# srun $model_job_scripts/4_post-processing/transient/04_post_globgm_tr.slurm $modelRoot 3 $start_year $end_year
