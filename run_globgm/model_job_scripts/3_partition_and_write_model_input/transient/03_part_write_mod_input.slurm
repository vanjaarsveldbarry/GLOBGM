#!/bin/bash
#SBATCH --exclusive
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=02:00:00
#SBATCH --cpus-per-task=32


# load modules
module load 2022
module load intel/2022a

modelRoot=$1

inpdir=$(realpath $modelRoot/model_input/3_partition_and_write_model_input/transient/)
exe=$(realpath ../_bin/mf6ggm_181121)
inpmod=mf6_mod_tr.inp
inpexe=mf6ggm_tr.inp
moddir=$modelRoot/mf6_mod/

mkdir -p $moddir

cp ${inpdir}/${inpmod} ${moddir}
cp ${inpdir}/${inpexe} ${moddir}

#REPLACE NECESSARY STRINGS
yodaInput=$(realpath ../_data/globgm_input)
globgm_dir=$modelRoot
ssFolder=$(dirname $modelRoot)/ss/mf6_mod/glob_ss/models/run_output_bin/
sed -i "s|{yoda_input}|${yodaInput}|g" ${moddir}${inpmod}
sed -i "s|{globgm_dir}|${globgm_dir}|g" ${moddir}${inpmod}
sed -i "s|{ssFolder}|${ssFolder}|g" ${moddir}${inpmod}
wait

cd ${moddir}
${exe} ${inpexe} 0
${exe} ${inpexe} 1 12 &
${exe} ${inpexe} 13 24 &
${exe} ${inpexe} 25 36 &
${exe} ${inpexe} 37 48 &
${exe} ${inpexe} 49 60 &
${exe} ${inpexe} 61 72 &
${exe} ${inpexe} 73 84 &
${exe} ${inpexe} 85 96 &
${exe} ${inpexe} 97 108 &
${exe} ${inpexe} 109 120 &
${exe} ${inpexe} 121 132 &
${exe} ${inpexe} 133 144 &
${exe} ${inpexe} 145 156 &
${exe} ${inpexe} 157 168 &
${exe} ${inpexe} 168 180 &
${exe} ${inpexe} 181 192 &
${exe} ${inpexe} 193 204 &
${exe} ${inpexe} 205 216 &
${exe} ${inpexe} 217 228 &
${exe} ${inpexe} 229 240 &
${exe} ${inpexe} 241 252 &
${exe} ${inpexe} 253 264 &
${exe} ${inpexe} 265 276 &
${exe} ${inpexe} 277 288 &
${exe} ${inpexe} 289 300 &
${exe} ${inpexe} 301 312 &
${exe} ${inpexe} 313 324 &
${exe} ${inpexe} 325 336 &
${exe} ${inpexe} 337 348 &
${exe} ${inpexe} 349 360 &
${exe} ${inpexe} 361 372 &
${exe} ${inpexe} 373 384 &
wait