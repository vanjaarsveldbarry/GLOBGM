#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=00:15:00
#SBATCH --partition=genoa,rome
#SBATCH --constraint=scratch-node

source ${HOME}/.bashrc
mamba activate globgm

modelRoot=$1
solution=$2
saveDir=$TMPDIR/mf6_post/temp_s0${solution}

inpdir=$(realpath $modelRoot/model_input/5_post-processing/steady-state)
zarrScripts=$(realpath ../model_tools_src/python/to_zarr)
inp_ss=mf6ggm_post_ss.inp
yodaInput=$(realpath ../_data/globgm_input)
globgm_dir=$modelRoot

exe=$(realpath ../_bin/mf6ggmpost)
mkdir -p $saveDir
cp ${inpdir}/${inp_ss} $saveDir/s0${solution}_${inp_ss}
sed -i "s|{yoda_input}|${yodaInput}|g" $saveDir/s0${solution}_${inp_ss}
sed -i "s|{globgm_dir}|${globgm_dir}|g" $saveDir/s0${solution}_${inp_ss}
sed -i "s|{solution}|${solution}|g" $saveDir/s0${solution}_${inp_ss}
wait

cd $saveDir
${exe} "s0${solution}_${inp_ss}"
wait 

mkdir -p $modelRoot/mf6_post
python -u $zarrScripts/createZarr_ss.py $saveDir s0$solution $modelRoot/mf6_post
wait