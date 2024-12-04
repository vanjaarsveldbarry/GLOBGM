#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=00:59:00
#SBATCH --cpus-per-task=16
#SBATCH --partition=genoa,rome

modelRoot=$1 
data_dir=$2
outFile=$3

top=$data_dir/globgm_input/clonemap_tiles/tile_163.txt
til=$data_dir/globgm_input/clonemap_tiles/idf/tile_
exe=$data_dir/_bin/datamap_070224
out_pref=./map_glob

cat=$data_dir/globgm_input/inp_idf/hybas_lake_lev08_v1c_filt.idf
d=$data_dir/globgm_input/inp_idf/d_top_2.idf

cd $modelRoot

mkdir -p ./mf6_map/
cd ./mf6_map/

${exe} 1 './map_glob' ${cat} ${d} ${top} ${til}
wait 
touch $outFile