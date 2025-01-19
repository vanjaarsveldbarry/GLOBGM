#!/bin/bash -l

source ${HOME}/.bashrc
mamba activate globgm

simulation=$1
outputDirectory=$2
run_globgm_dir=$3
data_dir=$4

cd $run_globgm_dir/model_job_scripts

for i in {1..50};do
    snakemake --cores 16 \
              --snakefile transient_with_pump_run.smk \
              --executor slurm --jobs 20 --default-resources slurm_account=uusei11758 \
              --config simulation=$simulation \
                     outputDirectory=$outputDirectory \
                     run_globgm_dir=$run_globgm_dir \
                     data_dir=$data_dir \
                     iteration=$i
    wait
    slurm_dir=$outputDirectory/$simulation/tr_with_pump/slurm_logs
    rm $slurm_dir/3_run_model/done_runModels_complete1_1
    rm $slurm_dir/3_run_model/done_runModels_complete2_1
    rm $slurm_dir/3_run_model/done_runModels_complete3_1
    rm $slurm_dir/3_run_model/done_runModels_complete4_1
    
    rm $slurm_dir/4_post-processing/done_post_1_1_hds
    rm $slurm_dir/4_post-processing/done_post_1_1_wtd
    rm $slurm_dir/4_post-processing/done_post_2_1_hds
    rm $slurm_dir/4_post-processing/done_post_2_1_wtd
    rm $slurm_dir/4_post-processing/done_post_3_1_hds
    rm $slurm_dir/4_post-processing/done_post_3_1_wtd
    rm $slurm_dir/4_post-processing/done_post_4_1_hds
    rm $slurm_dir/4_post-processing/done_post_4_1_wtd

    rm $slurm_dir/4_post-processing/done_validation
done