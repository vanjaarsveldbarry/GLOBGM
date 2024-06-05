#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=12:00:00
#SBATCH --partition=genoa
#SBATCH --constraint=scratch-node

modelRoot=$1
solution=$2
startDate=$3
endDate=$4
var=$5

df -kh ${TMPDIR}

source ${HOME}/.bashrc
mamba activate globgm

inpdir=$(realpath $modelRoot/model_input/5_post-processing/transient)
inp_tr=mf6ggm_post_tr_$var.inp
exe=$(realpath ../_bin/mf6ggmpost)
to_zarrFolder=$(realpath ../model_tools_src/python/to_zarr)

yodaInput=$(realpath ../_data/globgm_input)
globgm_dir=$modelRoot

dir=$modelRoot/mf6_post
mkdir -p $dir

#Create empty final zarr store
python -u $to_zarrFolder/createZarr_tr.py $modelRoot $solution $dir $startDate $endDate $var


#create final zarr dataset
function process_file() {
    local year=$1
    local month=$2
    mkdir -p $tempFolder

    cp ${inpdir}/${inp_tr} ./s0${solution}_${inp_tr}_$year$month
    sed -i "s|{yoda_input}|${yodaInput}|g" s0${solution}_${inp_tr}_$year$month
    sed -i "s|{globgm_dir}|${globgm_dir}|g" s0${solution}_${inp_tr}_$year$month
    sed -i "s|{solution}|${solution}|g" s0${solution}_${inp_tr}_$year$month
    sed -i "s|{START_DATE}|${year}|g" s0${solution}_${inp_tr}_$year$month
    sed -i "s|{END_DATE}|${year}|g" s0${solution}_${inp_tr}_$year$month
    sed -i "s|{month}|${month}|g" s0${solution}_${inp_tr}_$year$month

    ${exe} s0${solution}_${inp_tr}_$year$month 
}

cd ${TMPDIR}
mkdir -p ./mod_files
cd ./mod_files
tempFolder=$(realpath ./temp) 


for ((year=startDate; year<=endDate; year++))
do
    for month in $(seq -f "%02g" 1 12); do
        process_file $year $month &
    done
    wait

    python -u $to_zarrFolder/mergeZarr_tr.py $dir $tempFolder $solution $year 01 $var &
    python -u $to_zarrFolder/mergeZarr_tr.py $dir $tempFolder $solution $year 02 $var &
    python -u $to_zarrFolder/mergeZarr_tr.py $dir $tempFolder $solution $year 03 $var &
    python -u $to_zarrFolder/mergeZarr_tr.py $dir $tempFolder $solution $year 04 $var &
    python -u $to_zarrFolder/mergeZarr_tr.py $dir $tempFolder $solution $year 05 $var &
    python -u $to_zarrFolder/mergeZarr_tr.py $dir $tempFolder $solution $year 06 $var &
    python -u $to_zarrFolder/mergeZarr_tr.py $dir $tempFolder $solution $year 07 $var &
    python -u $to_zarrFolder/mergeZarr_tr.py $dir $tempFolder $solution $year 08 $var &
    python -u $to_zarrFolder/mergeZarr_tr.py $dir $tempFolder $solution $year 09 $var &
    python -u $to_zarrFolder/mergeZarr_tr.py $dir $tempFolder $solution $year 10 $var &
    python -u $to_zarrFolder/mergeZarr_tr.py $dir $tempFolder $solution $year 11 $var &
    python -u $to_zarrFolder/mergeZarr_tr.py $dir $tempFolder $solution $year 12 $var
    wait
done
df -kh ${TMPDIR}
mkdir -p /projects/0/einf4705/workflow/output/test/$solution
cp -r ${TMPDIR} /projects/0/einf4705/workflow/output/test/$solution
echo "done copy"
wait