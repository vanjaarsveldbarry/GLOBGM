#!/bin/bash -l
#SBATCH -N 1
#SBATCH -t 00:45:00
#SBATCH --partition=genoa

source ${HOME}/.bashrc
mamba activate globgm
scriptRoot=$(pwd)

modelRoot=$1
startDate=$2
endDate=$3
nSpin=1
nMonths=$(((( $endDate - $startDate ) + 1) * 12))
tempDir=$TMPDIR/job_${startTile}

cd $scriptRoot
inpdir=$(realpath $modelRoot/model_input/3_partition_and_write_model_input/transient/)
ssFolder=$(dirname $modelRoot)/ss/mf6_mod/glob_ss/models/run_output_bin/
exe=$(realpath ../_bin/mf6ggm_181121)
inpmod=mf6_mod_tr.inp
inpexe=mf6ggm_tr.inp
moddir=$modelRoot/mf6_mod

mkdir -p $moddir
i=1
cp ${inpdir}/${inpmod} ${moddir}/mf6_mod_tr_${i}.inp
cp ${inpdir}/${inpexe} ${moddir}/mf6ggm_tr_${i}.inp

# # #REPLACE NECESSARY STRINGS
yodaInput=$(realpath ../_data/globgm_input)
globgm_dir=$modelRoot
sed -i "s|{yoda_input}|${yodaInput}|g" ${moddir}/mf6_mod_tr_${i}.inp
sed -i "s|{globgm_dir}|${tempDir}|g" ${moddir}/mf6_mod_tr_${i}.inp
sed -i "s|{ssFolder}|${ssFolder}|g" ${moddir}/mf6_mod_tr_${i}.inp
sed -i "s|{NUMBER_OF_MONTHS}|${nMonths}|g" ${moddir}/mf6_mod_tr_${i}.inp
sed -i "s|{NUMBER_SPIN_YEARS}|${nSpin}|g" ${moddir}/mf6_mod_tr_${i}.inp
sed -i "s|{START_DATE}|${startDate}|g" ${moddir}/mf6_mod_tr_${i}.inp
sed -i "s|{ID}|${i}|g" ${moddir}/mf6ggm_tr_${i}.inp
wait

cd ${moddir}
input_sub=${moddir}/mf6ggm_tr_${i}.inp
${exe} ${input_sub} 0 