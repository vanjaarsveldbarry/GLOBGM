#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=00:05:00
#SBATCH --cpus-per-task=16
#SBATCH --partition=genoa,rome

modelRoot=$1 

tilesPath=$(realpath ../_data/globgm_input/clonemap_tiles)

exe=$(realpath ../_bin/datamap_070224)
out_pref=./map_glob
cat=$(realpath ../_data/globgm_input/inp_idf/hybas_lake_lev08_v1c_filt.idf)
d=$(realpath   ../_data/globgm_input/inp_idf/d_top_2.idf)
top=$tilesPath/tile_163.txt
til=$tilesPath/idf/tile_

cd $modelRoot
mkdir -p ./mf6_map/
cd ./mf6_map/

${exe} 1 ${out_pref} ${cat} ${d} ${top} ${til}