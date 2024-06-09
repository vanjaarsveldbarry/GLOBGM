#!/bin/bash -l
#SBATCH -N 1
#SBATCH -t 01:00:00
#SBATCH --partition=genoa
#SBATCH --exclusive

source ${HOME}/.bashrc
mamba activate globgm

modelRoot=$1

exe=$(realpath ../_bin/mf6ggm_181121)
inpmod=mf6_mod_ss.inp
inpexe=mf6ggm_ss.inp
moddir=$modelRoot/mf6_mod

mkdir -p $moddir
cd ${moddir}

for ((i=1; i<=384; i+=12)); do
    ii=$((i + 11))
    if [ $ii -gt 384 ]; then
        ii=384
    fi
    ${exe} ${inpexe} $i $ii &
done
wait