#!/bin/bash -l
model_job_scripts=$1
slurmDir_tr=$2
modelRoot=$3
start_year=$4
end_year=$5
steps=1
nSpin=1

tr_writeInput_setup_script=$model_job_scripts/2_write_model_input/_setup_tr.slurm
model_job_scripts_writeModels=$model_job_scripts/2_write_model_input/_writeModels_tr.slurm
for ((year=start_year; year<=end_year; year+=steps)); do
    yearStart=$year
    yearEnd=$((year+steps-1))
    if [ $yearEnd -gt $end_year ]; then
        yearEnd=$end_year
    fi
    spin=0
    if [ $yearStart -eq $start_year ]; then
        spin=$nSpin
    fi

    jobid=$(sbatch -o $slurmDir_tr/2_write_model_input/_setup${yearEnd}.out $tr_writeInput_setup_script $modelRoot $yearStart $yearEnd $spin| awk '{print $4}')
    sbatch --dependency=afterok:$jobid -o $slurmDir_tr/2_write_model_input/_${yearEnd}wMod_1_%a.out --array=1-2 $model_job_scripts_writeModels $modelRoot $yearStart $yearEnd 1
    sbatch --dependency=afterok:$jobid -o $slurmDir_tr/2_write_model_input/_${yearEnd}wMod_2_%a.out --array=1 $model_job_scripts_writeModels $modelRoot $yearStart $yearEnd 2
    sbatch --dependency=afterok:$jobid -o $slurmDir_tr/2_write_model_input/_${yearEnd}wMod_3_%a.out --array=1 $model_job_scripts_writeModels $modelRoot $yearStart $yearEnd 3
    sbatch --dependency=afterok:$jobid -o $slurmDir_tr/2_write_model_input/_${yearEnd}wMod_4_%a.out --array=1 $model_job_scripts_writeModels $modelRoot $yearStart $yearEnd 4
done