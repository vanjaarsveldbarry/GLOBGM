#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=12:00:00
#SBATCH --partition=genoa
#SBATCH --constraint=scratch-node
#SBATCH --exclusive

source ${HOME}/.bashrc
mamba activate globgm

modelRoot=$1
var=$2
solution=$3
startDate=$4
endDate=$5

_merge_zarr=$(realpath ../model_tools_src/python/to_zarr/mergeZarr_tr.py)
inpdir=$(realpath $modelRoot/model_input/5_post-processing/transient)
inp_tr=mf6ggm_post_tr_$var.inp
exe=$(realpath ../_bin/mf6ggmpost)
yodaInput=$(realpath ../_data/globgm_input)
dir=$modelRoot/mf6_post

input_file=s0${solution}_${inp_tr}

tempDir=$TMPDIR
cd $tempDir
mkdir -p ./mod_files_s0${solution}
cd ./mod_files_s0${solution}
tempFolder=$(realpath ./temp) 

#Convert output to .flt
cp ${inpdir}/${inp_tr} ./$input_file
sed -i "s|{yoda_input}|${yodaInput}|g" $input_file
sed -i "s|{globgm_dir}|${modelRoot}|g" $input_file
sed -i "s|{solution}|${solution}|g" $input_file
sed -i "s|{START_DATE}|${startDate}|g" $input_file
sed -i "s|{END_DATE}|${endDate}|g" $input_file
sed -i "s|{MOD_START_DATE}|${startDate}|g" $input_file
wait

${exe} $input_file 
wait
time {
  for ((year=$startDate; year<=$endDate; year++));do
     python -u $_merge_zarr $dir $tempFolder $solution $year 01 $var &
     python -u $_merge_zarr $dir $tempFolder $solution $year 02 $var &
     python -u $_merge_zarr $dir $tempFolder $solution $year 03 $var &
     python -u $_merge_zarr $dir $tempFolder $solution $year 04 $var &
     python -u $_merge_zarr $dir $tempFolder $solution $year 05 $var &
     python -u $_merge_zarr $dir $tempFolder $solution $year 06 $var &
     python -u $_merge_zarr $dir $tempFolder $solution $year 07 $var &
     python -u $_merge_zarr $dir $tempFolder $solution $year 08 $var &
     python -u $_merge_zarr $dir $tempFolder $solution $year 09 $var &
     python -u $_merge_zarr $dir $tempFolder $solution $year 10 $var &
     python -u $_merge_zarr $dir $tempFolder $solution $year 11 $var &
     python -u $_merge_zarr $dir $tempFolder $solution $year 12 $var
     wait
  done
  wait
}