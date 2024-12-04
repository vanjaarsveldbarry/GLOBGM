#!/bin/bash -l

source ${HOME}/.bashrc
mamba activate globgm

simulation=$1
outputDirectory=$2
run_globgm_dir=$3
data_dir=$4

cd $run_globgm_dir/model_job_scripts

kh_un=1.0
kh_con=1.0
kh_car=1.0
kv_conf=1.0
river_res=1.0

calib_str="khuncon${kh_un}_khcon${kh_con}_khcar${kh_car}_kvconf${kv_conf}_riverres${kv_conf}"
count=$((count + 1))
snakemake --cores 16 \
        --snakefile steady-state.smk \
        --config simulation=$simulation \
                    outputDirectory=$outputDirectory \
                    run_globgm_dir=$run_globgm_dir \
                    data_dir=$data_dir \
                    calib_str=$calib_str