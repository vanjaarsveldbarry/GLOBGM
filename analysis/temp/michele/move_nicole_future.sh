#!/bin/bash
#Set job requirements
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --partition=staging
#SBATCH --time=72:00:00
#SBATCH -o /projects/prjs1222/temp/move_nicole_future.out

eval "$(ssh-agent -s)"


scp -r /projects/prjs1222/globgm_output/cmip6_runs/ensemble eejit:/scratch/depfg/nicole_future_data

wait
# Kill the ssh-agent process after the command finishes
kill $SSH_AGENT_PID