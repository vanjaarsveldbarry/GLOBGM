#!/bin/bash -l
#SBATCH -N 1
#SBATCH -t 00:45:00
#SBATCH --partition=genoa,rome
#SBATCH --job-name=_setup_tr

source ${HOME}/.bashrc
mamba activate globgm

modelRoot=$1
start_year=$2
end_year=$3
nSpin=$4
outFile=$5
dataDir=$6
label=$7
iniStatesFolder=$8
nMonths=$(((( $end_year - $start_year ) + 1) * 12))

inpdir=$modelRoot/model_input/2_partition_and_write_model_input/transient
exe=$dataDir/_bin/mf6ggm_181121
inpmod=mf6_mod_tr.inp
inpexe=mf6ggm_tr.inp
moddir=$modelRoot/mf6_mod/mf6_mod_${label}
parentDir=$(dirname $(realpath $modelRoot))
ssFolder=${iniStatesFolder}
echo $ssFolder
yodaInput=$dataDir/globgm_input
globgmDir=$modelRoot
mkdir -p $moddir
cp ${inpdir}/${inpmod} ${moddir}/${inpmod}
cp ${inpdir}/${inpexe} ${moddir}/${inpexe}
sed -i "s|{yoda_input}|${yodaInput}|g" ${moddir}/${inpmod}
sed -i "s|{globgm_dir}|${globgmDir}|g" ${moddir}/${inpmod}
sed -i "s|{ssFolder}|${ssFolder}|g" ${moddir}/${inpmod}
sed -i "s|{NUMBER_OF_MONTHS}|${nMonths}|g" ${moddir}/${inpmod}
sed -i "s|{NUMBER_SPIN_YEARS}|${nSpin}|g" ${moddir}/${inpmod}
sed -i "s|{START_DATE}|${start_year}|g" ${moddir}/${inpmod}
wait

cd ${moddir}
${exe} ${inpexe} 0

wait
touch "${outFile}"