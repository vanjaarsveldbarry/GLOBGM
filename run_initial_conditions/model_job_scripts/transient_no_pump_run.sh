#!/bin/bash -l

source ${HOME}/.bashrc
mamba activate globgm

simulation=$1
outputDirectory=$2
run_globgm_dir=$3
data_dir=$4

cd $run_globgm_dir/model_job_scripts

for i in {1..20};do

    snakemake --cores 16 --until wrap_up --rerun-incomplete \
            --snakefile transient_no_pump_run.smk \
            --config simulation=$simulation \
                     outputDirectory=$outputDirectory \
                     run_globgm_dir=$run_globgm_dir \
                     data_dir=$data_dir
    wait

    rm /scratch-shared/_bvjaarsveld1/output_initial_conditions/gswp3-w5e5/tr_no_pump/slurm_logs/3_run_model/_runModels_complete1_1_rep
    rm /scratch-shared/_bvjaarsveld1/output_initial_conditions/gswp3-w5e5/tr_no_pump/slurm_logs/3_run_model/_runModels_complete2_1_rep
    rm /scratch-shared/_bvjaarsveld1/output_initial_conditions/gswp3-w5e5/tr_no_pump/slurm_logs/3_run_model/_runModels_complete3_1_rep
    rm /scratch-shared/_bvjaarsveld1/output_initial_conditions/gswp3-w5e5/tr_no_pump/slurm_logs/3_run_model/_runModels_complete4_1_rep

    rm /scratch-shared/_bvjaarsveld1/output_initial_conditions/gswp3-w5e5/tr_no_pump/slurm_logs/4_post-processing/_post_complete1_1_hds_rep
    rm /scratch-shared/_bvjaarsveld1/output_initial_conditions/gswp3-w5e5/tr_no_pump/slurm_logs/4_post-processing/_post_complete1_1_wtd_rep

    rm /scratch-shared/_bvjaarsveld1/output_initial_conditions/gswp3-w5e5/tr_no_pump/slurm_logs/4_post-processing/_post_complete2_1_hds_rep
    rm /scratch-shared/_bvjaarsveld1/output_initial_conditions/gswp3-w5e5/tr_no_pump/slurm_logs/4_post-processing/_post_complete2_1_wtd_rep

    rm /scratch-shared/_bvjaarsveld1/output_initial_conditions/gswp3-w5e5/tr_no_pump/slurm_logs/4_post-processing/_post_complete3_1_hds_rep
    rm /scratch-shared/_bvjaarsveld1/output_initial_conditions/gswp3-w5e5/tr_no_pump/slurm_logs/4_post-processing/_post_complete3_1_wtd_rep

    rm /scratch-shared/_bvjaarsveld1/output_initial_conditions/gswp3-w5e5/tr_no_pump/slurm_logs/4_post-processing/_post_complete4_1_hds_rep
    rm /scratch-shared/_bvjaarsveld1/output_initial_conditions/gswp3-w5e5/tr_no_pump/slurm_logs/4_post-processing/_post_complete4_1_wtd_rep

    rm /scratch-shared/_bvjaarsveld1/output_initial_conditions/gswp3-w5e5/tr_no_pump/slurm_logs/sim_done
    wait
done