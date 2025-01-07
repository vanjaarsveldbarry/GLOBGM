#!/bin/bash -l

source ${HOME}/.bashrc
mamba activate globgm

simulation=$1
outputDirectory=$2
run_globgm_dir=$3
data_dir=$4

cd $run_globgm_dir/model_job_scripts

for i in {1..20};do

    snakemake --cores 16 \
              --executor slurm --jobs 20 --default-resources slurm_account=uusei11758 \
              --snakefile transient_no_pump_run.smk \
              --config simulation=$simulation \
                     outputDirectory=$outputDirectory \
                     run_globgm_dir=$run_globgm_dir \
                     data_dir=$data_dir
    wait
    break
    slurm_dir=$outputDirectory/$simulation/tr_no_pump/slurm_logs
    # rm $slurm_dir/done_runModels_complete1_1_rep
    # rm $slurm_dir/done_runModels_complete2_1_rep
    # rm $slurm_dir/done_runModels_complete3_1_rep
    # rm $slurm_dir/done_runModels_complete4_1_rep
    
    # rm $slurm_dir/done_post_1_1_hds_rep
    # rm $slurm_dir/done_post_1_1_wtd_rep
    # rm $slurm_dir/done_post_2_1_hds_rep
    # rm $slurm_dir/done_post_2_1_wtd_rep
    # rm $slurm_dir/done_post_3_1_hds_rep
    # rm $slurm_dir/done_post_3_1_wtd_rep
    # rm $slurm_dir/done_post_4_1_hds_rep
    # rm $slurm_dir/done_post_4_1_wtd_rep

    # rm $slurm_dir/done_validation_rep

    # wait
done