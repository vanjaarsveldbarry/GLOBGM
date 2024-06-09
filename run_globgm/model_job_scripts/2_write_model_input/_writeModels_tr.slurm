#!/bin/bash -l
#SBATCH -N 1
#SBATCH -t 01:00:00
#SBATCH --partition=genoa
#SBATCH --exclusive

source ${HOME}/.bashrc
mamba activate globgm

modelRoot=$1
solution=$2

if [ $solution -eq 1 ]; then
    if [ $SLURM_ARRAY_TASK_ID -eq 1 ]; then
        startMod=1
        endMod=32
    fi
    if [ $SLURM_ARRAY_TASK_ID -eq 2 ]; then
        startMod=33
        endMod=64
    fi
    if [ $SLURM_ARRAY_TASK_ID -eq 3 ]; then
        startMod=65
        endMod=96
    fi
    if [ $SLURM_ARRAY_TASK_ID -eq 4 ]; then
        startMod=97
        endMod=128
    fi
    if [ $SLURM_ARRAY_TASK_ID -eq 5 ]; then
        startMod=129
        endMod=160
    fi
    if [ $SLURM_ARRAY_TASK_ID -eq 6 ]; then
        startMod=161
        endMod=192
    fi
    if [ $SLURM_ARRAY_TASK_ID -eq 7 ]; then
        startMod=193
        endMod=224
    fi
fi

if [ $solution -eq 2 ]; then
    if [ $SLURM_ARRAY_TASK_ID -eq 1 ]; then
        startMod=225
        endMod=256
    fi
    if [ $SLURM_ARRAY_TASK_ID -eq 2 ]; then
        startMod=257
        endMod=288
    fi
    if [ $SLURM_ARRAY_TASK_ID -eq 3 ]; then
        startMod=289
        endMod=320
    fi
fi

if [ $solution -eq 3 ]; then
    startMod=321
    endMod=352
fi

if [ $solution -eq 4 ]; then
    startMod=353
    endMod=384
fi

exe=$(realpath ../_bin/mf6ggm_181121)
inpmod=mf6_mod_tr.inp
inpexe=mf6ggm_tr.inp
moddir=$modelRoot/mf6_mod

mkdir -p $moddir
cd ${moddir}

for ((i=$startMod; i<=$endMod; i+=2)); do
    ii=$((i + 1))
    if [ $ii -gt 384 ]; then
        ii=384
    fi
    ${exe} ${inpexe} $i $ii &
done
wait