#!/bin/bash -l
#SBATCH -N 1
#SBATCH -t 00:45:00
#SBATCH --partition=genoa

source ${HOME}/.bashrc
mamba activate globgm

modelRoot=$1
modelScratch=$2
startDate=$3
endDate=$4
nSpin=1
nMonths=$(((( $endDate - $startDate ) + 1) * 12))


inpdir=$(realpath $modelRoot/model_input/3_partition_and_write_model_input/transient)
exe=$(realpath ../_bin/mf6ggm_181121)
inpmod=mf6_mod_tr.inp
inpexe=mf6ggm_tr.inp
moddir=$modelRoot/mf6_mod
globgmDir=$modelScratch
ssFolder=$(dirname $modelRoot)/ss/mf6_mod/glob_ss/models/run_output_bin/

mkdir -p $moddir
cp ${inpdir}/${inpmod} ${moddir}/${inpmod}
cp ${inpdir}/${inpexe} ${moddir}/${inpexe}
yodaInput=$(realpath ../_data/globgm_input)
globgm_dir=$modelRoot
sed -i "s|{yoda_input}|${yodaInput}|g" ${moddir}/${inpmod}
sed -i "s|{globgm_dir}|${globgmDir}|g" ${moddir}/${inpmod}
sed -i "s|{ssFolder}|${ssFolder}|g" ${moddir}/${inpmod}
sed -i "s|{NUMBER_OF_MONTHS}|${nMonths}|g" ${moddir}/${inpmod}
sed -i "s|{NUMBER_SPIN_YEARS}|${nSpin}|g" ${moddir}/${inpmod}
sed -i "s|{START_DATE}|${startDate}|g" ${moddir}/${inpmod}
wait

cd ${moddir}
${exe} ${inpexe} 0