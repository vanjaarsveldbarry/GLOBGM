#!/bin/bash -l
#SBATCH -N 1
#SBATCH -t 00:45:00
#SBATCH --partition=genoa

source ${HOME}/.bashrc
mamba activate globgm
scriptRoot=$(pwd)

modelRoot=$1
cd $scriptRoot
inpdir=$(realpath $modelRoot/model_input/3_partition_and_write_model_input/steady-state/)
exe=$(realpath ../_bin/mf6ggm_181121)
inpmod=mf6_mod_ss.inp
inpexe=mf6ggm_ss.inp
moddir=$modelRoot/mf6_mod/

mkdir -p $moddir
i=1
cp ${inpdir}/${inpmod} ${moddir}/mf6_mod_ss_${i}.inp
cp ${inpdir}/${inpexe} ${moddir}/mf6ggm_ss_${i}.inp

# # #REPLACE NECESSARY STRINGS
yodaInput=$(realpath ../_data/globgm_input)
globgm_dir=$modelRoot
sed -i "s|{yoda_input}|${yodaInput}|g" ${moddir}/mf6_mod_ss_${i}.inp
sed -i "s|{globgm_dir}|${tempDir}|g" ${moddir}/mf6_mod_ss_${i}.inp
sed -i "s|{ID}|${i}|g" ${moddir}/mf6ggm_ss_${i}.inp
wait

cd ${moddir}
input_sub=${moddir}/mf6ggm_ss_${i}.inp
${exe} ${input_sub} 0 