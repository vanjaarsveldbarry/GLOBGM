#!/bin/bash
#SBATCH -N 1
#SBATCH -t 119:59:00
#SBATCH -p staging
#SBATCH -J touch

squeue -u barrygwt -o "%.10i %.10P %.24j %.10u %.12T %.12M %.12l %.5D %16R %20S"

# touch all files on your scratch-shared - please modify "edwindemo"
cd /scratch-shared/globgm_scratch
ls -lah .
find . -exec touch {} \;
ls -lah .