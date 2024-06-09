#!/bin/bash -l
#SBATCH -N 1
#SBATCH -t 00:45:00
#SBATCH -J _ssSetup
#SBATCH --partition=genoa

source ${HOME}/.bashrc
mamba activate globgm

modelRoot=$1
modelScratch=$2
inpdir=$(realpath $modelRoot/model_input/3_partition_and_write_model_input/steady-state)
exe=$(realpath ../_bin/mf6ggm_181121)
inpmod=mf6_mod_ss.inp
inpexe=mf6ggm_ss.inp
moddir=$modelRoot/mf6_mod
globgmDir=$modelScratch

mkdir -p $moddir
cp ${inpdir}/${inpmod} ${moddir}/${inpmod}
cp ${inpdir}/${inpexe} ${moddir}/${inpexe}
#REPLACE NECESSARY STRINGS
yodaInput=$(realpath ../_data/globgm_input)
globgm_dir=$modelRoot
sed -i "s|{yoda_input}|${yodaInput}|g" ${moddir}/${inpmod}
sed -i "s|{globgm_dir}|${globgmDir}|g" ${moddir}/${inpmod}
wait

cd ${moddir}
${exe} ${inpexe} 0 