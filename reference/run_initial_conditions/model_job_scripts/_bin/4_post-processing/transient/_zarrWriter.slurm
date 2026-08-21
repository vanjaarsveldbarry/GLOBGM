#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=12:00:00
#SBATCH --partition=genoa
#SBATCH --constraint=scratch-node
#SBATCH -n 64

df -kh $TMPDIR
source ${HOME}/.bashrc
mamba activate globgm

modelRoot=$1
var=$2
solution=$3
startDate=$4
endDate=$5
modDir=$6
dataDir=$7
outFile=$8

_merge_zarr=$(realpath ../model_tools_src/python/to_zarr/mergeZarr_tr.py)
_plot_script=$(realpath ../model_tools_src/python/to_zarr/mean_plot.py)
inpdir=$modelRoot/model_input/4_post-processing/transient
inp_tr=mf6ggm_post_tr_$var.inp
exe=$dataDir/_bin/mf6ggmpost_260624
yodaInput=$dataDir/globgm_input
dir=$modelRoot/mf6_post
input_file=s0${solution}_${inp_tr}


counter=0
for ((year=$startDate; year<=$endDate; year++));do
    counter=$((counter+1))
    modFlowTemp=$TMPDIR/output
    mkdir -p $modFlowTemp
    cd $modFlowTemp
    mkdir -p ./mod_files_s0${solution}_${year} ./out
    cd ./mod_files_s0${solution}_${year}
    # #Convert output to .flt
    sub_input=${input_file}_${year}
    cp ${inpdir}/${inp_tr} ./$sub_input
    sed -i "s|{yoda_input}|${yodaInput}|g" $sub_input
    sed -i "s|{globgm_dir}|${modelRoot}|g" $sub_input
    sed -i "s|{mod_dir}|${modDir}|g" $sub_input
    sed -i "s|{solution}|${solution}|g" $sub_input
    sed -i "s|{START_DATE}|${year}|g" $sub_input
    sed -i "s|{END_DATE}|${year}|g" $sub_input
    sed -i "s|{MOD_START_DATE}|${startDate}|g" $sub_input
    ${exe} $sub_input &
    if [ $counter -eq 6 ]; then
        wait
        counter=0
    fi
done
wait

counter=0
for ((year=$startDate; year<=$endDate; year++));do
    counter=$((counter+1))
    # python -u $_merge_zarr $dir $modFlowTemp/out $solution $year 01 $var &
    # python -u $_merge_zarr $dir $modFlowTemp/out $solution $year 02 $var &
    # python -u $_merge_zarr $dir $modFlowTemp/out $solution $year 03 $var &
    # python -u $_merge_zarr $dir $modFlowTemp/out $solution $year 04 $var &
    # python -u $_merge_zarr $dir $modFlowTemp/out $solution $year 05 $var &
    # python -u $_merge_zarr $dir $modFlowTemp/out $solution $year 06 $var &
    # python -u $_merge_zarr $dir $modFlowTemp/out $solution $year 07 $var &
    # python -u $_merge_zarr $dir $modFlowTemp/out $solution $year 08 $var &
    # python -u $_merge_zarr $dir $modFlowTemp/out $solution $year 09 $var &
    # python -u $_merge_zarr $dir $modFlowTemp/out $solution $year 10 $var &
    # python -u $_merge_zarr $dir $modFlowTemp/out $solution $year 11 $var &
    python -u $_merge_zarr $dir $modFlowTemp/out $solution $year 12 $var
    if [ $counter -eq 3 ]; then
        wait
        counter=0
    fi
done
wait
df -kh $TMPDIR

python -u $_plot_script $dir $solution $var

touch ${outFile}