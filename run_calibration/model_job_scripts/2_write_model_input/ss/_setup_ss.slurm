#!/bin/bash -l
#SBATCH -N 1
#SBATCH -J _ssSetup
#SBATCH -t 00:05:00
#SBATCH --partition=genoa

source ${HOME}/.bashrc
mamba activate globgm

modelRoot=$1
data_dir=$2
run_globgm_dir=$3
outFile=$4

mkdir -p $modelRoot/model_input
cp -r $run_globgm_dir/model_input $modelRoot

inpdir=$modelRoot/model_input/2_partition_and_write_model_input/steady-state
inpmod=mf6_mod_ss.inp
inpexe=mf6ggm_ss.inp

moddir=$modelRoot/mf6_mod
mkdir -p $moddir

cp ${inpdir}/${inpmod} ${moddir}/${inpmod}
cp ${inpdir}/${inpexe} ${moddir}/${inpexe}

yodaInput=$data_dir/globgm_input
globgm_dir=$modelRoot
sed -i "s|{yoda_input}|${yodaInput}|g" ${moddir}/${inpmod}
sed -i "s|{globgm_dir}|${moddir}|g" ${moddir}/${inpmod}
wait

exe=$data_dir/_bin/mf6ggm_181121
cd ${moddir}
${exe} ${inpexe} 0 
wait 

touch $outFile