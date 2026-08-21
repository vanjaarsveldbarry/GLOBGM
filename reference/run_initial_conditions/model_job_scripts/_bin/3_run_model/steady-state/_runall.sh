#!/bin/bash
ssModelRoot=$1
model_job_scripts=$2
slurmDir_ss=$3
outFile=$4
data_dir=$5

sbatch -o $slurmDir_ss/3_run_model/3_run_globgm_s01.out $model_job_scripts/3_run_model/steady-state/mf6_s01_ss.slurm $ssModelRoot $model_job_scripts $slurmDir_ss $outFile $data_dir
sbatch -o $slurmDir_ss/3_run_model/3_run_globgm_s02.out $model_job_scripts/3_run_model/steady-state/mf6_s02_ss.slurm $ssModelRoot $model_job_scripts $slurmDir_ss $outFile $data_dir
sbatch -o $slurmDir_ss/3_run_model/3_run_globgm_s03.out $model_job_scripts/3_run_model/steady-state/mf6_s03_ss.slurm $ssModelRoot $model_job_scripts $slurmDir_ss $outFile $data_dir
sbatch -o $slurmDir_ss/3_run_model/3_run_globgm_s04.out $model_job_scripts/3_run_model/steady-state/mf6_s04_ss.slurm $ssModelRoot $model_job_scripts $slurmDir_ss $outFile $data_dir