#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=00:05:00

modelRoot=$1 
tilesPath=$(realpath ./globgm/_data/globgm_input/clonemap_tiles)


exe=$(realpath ./globgm/_bin/datamap_070224)
out_pref=./map_glob
cat=$(realpath ./globgm/_data/globgm_input/inp_idf/hybas_lake_lev08_v1c_filt.idf)
d=$(realpath   ./globgm/_data/globgm_input/inp_idf/d_top_2.idf)
top=$tilesPath/tile_163.txt
til=$tilesPath/idf/tile_

cd $modelRoot
mkdir -p ./mf6_map/
cd ./mf6_map/

${exe} 1 ${out_pref} ${cat} ${d} ${top} ${til}
