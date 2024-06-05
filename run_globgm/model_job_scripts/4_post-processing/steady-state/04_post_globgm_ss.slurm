#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=00:15:00
#SBATCH --partition=genoa,rome

source ${HOME}/.bashrc
mamba activate globgm

modelRoot=$1
solution=$2

inpdir=$(realpath $modelRoot/model_input/5_post-processing/steady-state)
inp_ss=mf6ggm_post_ss.inp

exe=$(realpath ../_bin/mf6ggmpost)
mkdir -p ${modelRoot}/mf6_post/temp_s0${solution}
cp ${inpdir}/${inp_ss} ${modelRoot}/mf6_post/temp_s0${solution}/s0${solution}_${inp_ss}
yodaInput=$(realpath ../_data/globgm_input)
globgm_dir=$modelRoot
sed -i "s|{yoda_input}|${yodaInput}|g" ${modelRoot}/mf6_post/temp_s0${solution}/s0${solution}_${inp_ss}
sed -i "s|{globgm_dir}|${globgm_dir}|g" ${modelRoot}/mf6_post/temp_s0${solution}/s0${solution}_${inp_ss}
sed -i "s|{solution}|${solution}|g" ${modelRoot}/mf6_post/temp_s0${solution}/s0${solution}_${inp_ss}
wait

cd ${modelRoot}/mf6_post/temp_s0${solution}
${exe} "s0${solution}_${inp_ss}"
wait 

cd - && cd ../model_tools_src/python/to_zarr
echo $(pwd)
wait

python -u ./createZarr_ss.py ${modelRoot}/mf6_post/temp_s0${solution} s0$solution
wait && rm -r $modelRoot/mf6_post/temp_s0${solution}