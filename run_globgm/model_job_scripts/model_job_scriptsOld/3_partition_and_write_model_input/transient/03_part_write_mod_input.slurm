#!/bin/bash
#SBATCH --partition=genoa,rome
# load modules
source ${HOME}/.bashrc
mamba activate globgm
module load 2022
module load intel/2022a

modelRoot=$1


modelRoot=$1
start_year=$2
end_year=$3


# inpdir=$(realpath $modelRoot/model_input/3_partition_and_write_model_input/transient/)
exe=$(realpath ../_bin/mf6ggm_181121)
inpmod=mf6_mod_tr.inp
inpexe=mf6ggm_tr.inp
moddir=$modelRoot/mf6_mod/

# mkdir -p $moddir

# cp ${inpdir}/${inpmod} ${moddir}
# cp ${inpdir}/${inpexe} ${moddir}

# #REPLACE NECESSARY STRINGS
# yodaInput=$(realpath ../_data/globgm_input)
# globgm_dir=$modelRoot
# ssFolder=$(dirname $modelRoot)/ss/mf6_mod/glob_ss/models/run_output_bin/
# nSpin=1
# startDate=$2
# endDate=$3
# nMonths=$(((( $endDate - $startDate ) + 1) * 12))
slurmDir_tr=$modelRoot/slurm_logs
# connectionsScript=$(realpath ./3_partition_and_write_model_input/transient/get_connections.py)
# pcrglob_path=$(realpath ../model_tools_src/python/pcr-globwb)
# writeTilesScript=$(realpath ./tr.slurm)


# # 3_partition_and_write_model_input/transient
# wait 
# sed -i "s|{yoda_input}|${yodaInput}|g" ${moddir}${inpmod}
# sed -i "s|{globgm_dir}|${globgm_dir}|g" ${moddir}${inpmod}
# sed -i "s|{ssFolder}|${ssFolder}|g" ${moddir}${inpmod}
# sed -i "s|{NUMBER_OF_MONTHS}|${nMonths}|g" ${moddir}${inpmod}
# sed -i "s|{NUMBER_SPIN_YEARS}|${nSpin}|g" ${moddir}${inpmod}
# sed -i "s|{START_DATE}|${startDate}|g" ${moddir}${inpmod}
# wait

# cd ${moddir}

# for ((id = 1; id <=384; id++)); do
#     echo $id
#     # your code here
#     outFile=$slurmDir_tr/3_partition_and_write_model_input/m${id}.out
#     sbatch --partition=genoa,rome --time=24:00:00 -o $outFile --wrap="${exe} ${inpexe} $id 384"
# done

# python $connectionsScript $slurmDir_tr/3_partition_and_write_model_input $moddir

tile=1
tile=$(printf "%03d" ${tile#0})

model_input=$(realpath $modelRoot/model_input/1_write_tiled_parameter_data)
forcingDir=$(realpath $modelRoot/forcing_input)

OUT_DIR=$modelRoot/input_map/transient
IN_DIR=$(realpath ../_data/globgm_input)
SS_DIR=$(dirname $modelRoot)/ss

cd ../model_tools_src/python/pcr-globwb

# I am doing this for one tile only will need to find a way to aplly to all tiles. 
python deterministic_runner_for_offline_monthly_modflow.py $model_input/transient_config.ini debug transient tile_${tile}-163 $SS_DIR $IN_DIR $OUT_DIR $forcingDir $start_year $end_year &

cd ${moddir}

sbatch --time=01:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m2.out --wrap="${exe} ${inpexe} 379 379"
sbatch --time=01:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m3.out --wrap="${exe} ${inpexe} 384 384"

###################################
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m1.out --wrap="${exe} ${inpexe} 0"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m2.out --wrap="${exe} ${inpexe} 1 12"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m3.out --wrap="${exe} ${inpexe} 13 24"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m4.out --wrap="${exe} ${inpexe} 25 36"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m5.out --wrap="${exe} ${inpexe} 37 48"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m6.out --wrap="${exe} ${inpexe} 49 60"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m7.out --wrap="${exe} ${inpexe} 61 72"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m8.out --wrap="${exe} ${inpexe} 73 84"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m9.out --wrap="${exe} ${inpexe} 85 96"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m10.out --wrap="${exe} ${inpexe} 97 108"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m11.out --wrap="${exe} ${inpexe} 109 120"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m12.out --wrap="${exe} ${inpexe} 121 132"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m13.out --wrap="${exe} ${inpexe} 133 144"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m14.out --wrap="${exe} ${inpexe} 145 156"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m15.out --wrap="${exe} ${inpexe} 157 168"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m16.out --wrap="${exe} ${inpexe} 168 180"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m17.out --wrap="${exe} ${inpexe} 181 192"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m18.out --wrap="${exe} ${inpexe} 193 204"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m19.out --wrap="${exe} ${inpexe} 205 216"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m20.out --wrap="${exe} ${inpexe} 217 228"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m21.out --wrap="${exe} ${inpexe} 229 240"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m22.out --wrap="${exe} ${inpexe} 241 252"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m23.out --wrap="${exe} ${inpexe} 253 264"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m24.out --wrap="${exe} ${inpexe} 265 276"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m25.out --wrap="${exe} ${inpexe} 277 288"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m26.out --wrap="${exe} ${inpexe} 289 300"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m27.out --wrap="${exe} ${inpexe} 301 312"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m28.out --wrap="${exe} ${inpexe} 313 324"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m29.out --wrap="${exe} ${inpexe} 325 336"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m30.out --wrap="${exe} ${inpexe} 337 348"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m31.out --wrap="${exe} ${inpexe} 349 350"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m32.out --wrap="${exe} ${inpexe} 351 352"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m33.out --wrap="${exe} ${inpexe} 353 354"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m34.out --wrap="${exe} ${inpexe} 355 356"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m35.out --wrap="${exe} ${inpexe} 357 358"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m36.out --wrap="${exe} ${inpexe} 359 360"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m37.out --wrap="${exe} ${inpexe} 361 362"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m38.out --wrap="${exe} ${inpexe} 363 364"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m39.out --wrap="${exe} ${inpexe} 365 366"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m40.out --wrap="${exe} ${inpexe} 367 368"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m41.out --wrap="${exe} ${inpexe} 369 370"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m42.out --wrap="${exe} ${inpexe} 371 372"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m43.out --wrap="${exe} ${inpexe} 373 374"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m44.out --wrap="${exe} ${inpexe} 375 376"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m45.out --wrap="${exe} ${inpexe} 377 378"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m46.out --wrap="${exe} ${inpexe} 379 380"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m47.out --wrap="${exe} ${inpexe} 381 382"
# sbatch --time=24:00:00 -o $slurmDir_tr/3_partition_and_write_model_input/m48.out --wrap="${exe} ${inpexe} 383 384"