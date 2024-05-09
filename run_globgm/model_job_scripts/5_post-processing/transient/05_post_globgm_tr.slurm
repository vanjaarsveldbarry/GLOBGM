#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=120:00:00
#SBATCH --partition=genoa,rome

modelRoot=$1
solution=$2
startDate=$3
endDate=$4


inpdir=$(realpath $modelRoot/model_input/5_post-processing/transient)
inp_tr=mf6ggm_post_tr.inp

exe=$(realpath ../_bin/mf6ggmpost)
mkdir -p ${modelRoot}/mf6_post
cp ${inpdir}/${inp_tr} ${modelRoot}/mf6_post
yodaInput=$(realpath ../_data/globgm_input)
globgm_dir=$modelRoot
sed -i "s|{yoda_input}|${yodaInput}|g" ${modelRoot}/mf6_post/$inp_tr
sed -i "s|{globgm_dir}|${globgm_dir}|g" ${modelRoot}/mf6_post/$inp_tr
sed -i "s|{solution}|${solution}|g" ${modelRoot}/mf6_post/$inp_tr
wait

cd ${modelRoot}/mf6_post
${exe} ${inp_tr}
