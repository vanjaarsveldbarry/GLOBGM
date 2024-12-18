#!/bin/bash -l

source ${HOME}/.bashrc
mamba activate globgm

simulation=$1
outputDirectory=$2
run_globgm_dir=$3
data_dir=$4

cd $run_globgm_dir/model_job_scripts

for i in {1..30};do

    snakemake --cores 16 --until wrap_up --rerun-incomplete \
              --snakefile transient_with_pump_run.smk \
              --config simulation=$simulation \
                     outputDirectory=$outputDirectory \
                     run_globgm_dir=$run_globgm_dir \
                     data_dir=$data_dir
    wait
    _slurm_logs_dir=$outputDirectory/$simulation/tr_with_pump/slurm_logs
    rm $_slurm_logs_dir/3_run_model/_runModels_complete1_1_rep
    rm $_slurm_logs_dir/3_run_model/_runModels_complete2_1_rep
    rm $_slurm_logs_dir/3_run_model/_runModels_complete3_1_rep
    rm $_slurm_logs_dir/3_run_model/_runModels_complete4_1_rep

    rm $_slurm_logs_dir/4_post-processing/_post_complete1_1_hds_rep
    rm $_slurm_logs_dir/4_post-processing/_post_complete1_1_wtd_rep

    rm $_slurm_logs_dir/4_post-processing/_post_complete2_1_hds_rep
    rm $_slurm_logs_dir/4_post-processing/_post_complete2_1_wtd_rep

    rm $_slurm_logs_dir/4_post-processing/_post_complete3_1_hds_rep
    rm $_slurm_logs_dir/4_post-processing/_post_complete3_1_wtd_rep

    rm $_slurm_logs_dir/4_post-processing/_post_complete4_1_hds_rep
    rm $_slurm_logs_dir/4_post-processing/_post_complete4_1_wtd_rep
    rm $_slurm_logs_dir/4_post-processing/_analyse_heads_complete_rep

    rm /scratch-shared/_bvjaarsveld1/output_initial_conditions/gswp3-w5e5/tr_with_pump/slurm_logs/sim_done
done