#!/bin/bash -l
#SBATCH --partition=fat_genoa
#SBATCH -N 1
#SBATCH -t 32:00:00
#SBATCH -J _yoda
#SBATCH --cpus-per-task 1
#SBATCH --ntasks-per-node=24
#SBATCH --output=/projects/prjs1222/GLOBGM/analysis/_yoda_archive/create_cmip6.out


module load 2023
module load mpifileutils/0.11.1-gompi-2023a
mpirun -np 190 dtar -x -f historical_no_pump.tar


root_dir=/projects/prjs1222/globgm_output/cmip6_runs
temp_dir=/projects/prjs1222/scratch_backup/globgm_scratch/archive/cmip6/GCM

# models="gfdl-esm4 ipsl-cm6a-lr mpi-esm1-2-hr mri-esm2-0 ukesm1-0-ll"
# scenarios="historical ssp126 ssp370 ssp585"
models="mpi-esm1-2-hr"
scenarios="ssp370 ssp585"

# organise annual
# for model in $models; do
#     for scen in $scenarios; do
#         # for var in "hds" "wtd"; do
#         for var in "hds"; do
#             sourcePath=$root_dir/$model/$scen/annual/$var.zarr
#             mkdir -p $temp_dir/annual_temp $temp_dir/annual
#             if [ "$scen" == "historical" ]; then
#                 fileName=${var}_annual_1960_2014_${scen}_${model}.zarr
#             else
#                 fileName=${var}_annual_2015_2100_${scen}_${model}.zarr
#             fi
            mpirun -np 190 dcp $sourcePath $temp_dir/annual_temp/$fileName
#             wait
#         done
#     done
# done

# taskset -c 0-191 python /projects/prjs1222/GLOBGM/analysis/_yoda_archive/_rechunk_GCM.py

# for model in $models; do
#     for scen in $scenarios; do
#         cd "$temp_dir/annual" || { echo "Failed to cd to $temp_dir/annual"; exit 1; }
#         # for var in "wtd" "hds"; do
#         for var in "hds"; do
#             if [ "$scen" == "historical" ]; then
#                 fileName=${var}_annual_1960_2014_${scen}_${model}.zarr
#             else
#                 fileName=${var}_annual_2015_2100_${scen}_${model}.zarr
#             fi
#             dirPath="$temp_dir/annual/$fileName"
#             echo $dirPath

#             if [ -d "$dirPath" ]; then
#                 (
#                     cd "$dirPath" || { echo "Failed to cd to $dirPath"; exit 1; }
#                     zip -r0 "../${fileName}.zip" ./
#                 ) &
#             else
#                 echo "Directory $dirPath does not exist, skipping."
#             fi
#         done
#     done
# done
# wait 


for model in $models; do
    for scen in $scenarios; do
        cd "$temp_dir/annual" || { echo "Failed to cd to $temp_dir/annual"; exit 1; }
        for var in "wtd" "hds"; do
            if [ "$scen" == "historical" ]; then
                fileName=${var}_annual_1960_2014_${scen}_${model}.zarr
            else
                fileName=${var}_annual_2015_2100_${scen}_${model}.zarr
            fi
            dirPath="$temp_dir/annual/$fileName"
            mpirun -np 20 drm $dirPath
            wait
        done
    done
done

# #organise average  
# for model in $models; do
#     for scen in $scenarios; do
#         for var in "hds" "wtd"; do
#             sourcePath=$root_dir/$model/$scen/avg/$var.nc
#             mkdir -p $temp_dir/average
#             cd $temp_dir/average
#             if [ "$scen" == "historical" ]; then
#                 fileName=${var}_average_1960_2014_${scen}_${model}.nc
#             else
#                 fileName=${var}_average_2015_2100_${scen}_${model}.nc
#             fi
#             cp $sourcePath $temp_dir/average/$fileName
#         done
#     done
# done
