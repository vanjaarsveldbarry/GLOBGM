#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=00:15:00
#SBATCH --partition=genoa,rome
#SBATCH --constraint=scratch-node
#SBATCH --job-name=post_ss

source ${HOME}/.bashrc
mamba activate globgm

modelRoot=$1
solution=$2
outFile=$3
saveDir=$TMPDIR/mf6_post/temp_s0${solution}
mkdir -p $saveDir $modelRoot/mf6_post

inpdir=$modelRoot/model_input/5_post-processing/steady-state
zarrScripts=$(realpath ../model_tools_src/python/to_zarr)
inp_ss=mf6ggm_post_ss.inp
yodaInput=$(realpath ../_data/globgm_input)
exe=$(realpath ../_bin/mf6ggmpost_260624)

cp ${inpdir}/${inp_ss} $saveDir/s0${solution}_${inp_ss}
sed -i "s|{yoda_input}|${yodaInput}|g" $saveDir/s0${solution}_${inp_ss}
sed -i "s|{globgm_dir}|${modelRoot}|g" $saveDir/s0${solution}_${inp_ss}
sed -i "s|{solution}|${solution}|g" $saveDir/s0${solution}_${inp_ss}
wait

cd $saveDir
${exe} "s0${solution}_${inp_ss}"
wait 

python -u $zarrScripts/createZarr_ss.py $saveDir s0$solution $modelRoot/mf6_post
wait
touch $outFile