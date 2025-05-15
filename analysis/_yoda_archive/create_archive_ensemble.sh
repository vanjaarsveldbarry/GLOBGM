#!/bin/bash -l
#SBATCH --partition=fat_genoa
#SBATCH -N 1
#SBATCH -t 72:00:00
#SBATCH -J _yoda
#SBATCH --cpus-per-task 1
#SBATCH --ntasks-per-node=24
#SBATCH --output=/projects/prjs1222/GLOBGM/analysis/_yoda_archive/create_cmip6_ensemble.out


module load 2023
module load mpifileutils/0.11.1-gompi-2023a


root_dir=/projects/prjs1222/globgm_output/cmip6_runs
temp_dir=/projects/prjs1222/scratch_backup/globgm_scratch/archive/cmip6/ensemble


models="ensemble"
scenarios="historical ssp126 ssp370 ssp585"

# # # organise monthly
# for model in $models; do
#     for scen in $scenarios; do
#         for var in "hds" "wtd"; do
#             mkdir -p $temp_dir/monthly
#             sourcePath=$root_dir/$model/merged/$scen/$var.zarr
#             if [ "$scen" == "historical" ]; then
#                 fileName=${var}_monthly_1960_2014_${scen}_${model}.zarr
#             else
#                 fileName=${var}_monthly_2015_2100_${scen}_${model}.zarr
#             fi
#             mpirun -np 190 dcp $sourcePath $temp_dir/monthly/$fileName
#             wait
#         done
#     done
# done


# for model in $models; do
#     for scen in $scenarios; do
#         cd "$temp_dir/monthly" || { echo "Failed to cd to $temp_dir/monthly"; exit 1; }
#         for var in "wtd" "hds"; do
#             if [ "$scen" == "historical" ]; then
#                 fileName=${var}_monthly_1960_2014_${scen}_${model}.zarr
#             else
#                 fileName=${var}_monthly_2015_2100_${scen}_${model}.zarr
#             fi
#             dirPath="$temp_dir/monthly/$fileName"

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
        for var in "wtd" "hds"; do
            if [ "$scen" == "historical" ]; then
                fileName=${var}_monthly_1960_2014_${scen}_${model}.zarr
            else
                fileName=${var}_monthly_2015_2100_${scen}_${model}.zarr
            fi
            dirPath="$temp_dir/monthly/$fileName"
            echo $dirPath
            mpirun -np 190 drm $dirPath
            wait
        done
    done
done


# # organise annual
# for model in $models; do
#     for scen in $scenarios; do
#         for var in "hds" "wtd"; do
#             sourcePath=$root_dir/$model/annual/$scen/$var.zarr
#             mkdir -p $temp_dir/annual_temp
#             mkdir -p $temp_dir/annual
#             cd $temp_dir/annual
#             if [ "$scen" == "historical" ]; then
#                 fileName=${var}_annual_1960_2014_${scen}_${model}.zarr
#             else
#                 fileName=${var}_annual_2015_2100_${scen}_${model}.zarr
#             fi
#             mpirun -np 190 dcp $sourcePath $temp_dir/annual_temp/$fileName
#         done
#     done
# done

# taskset -c 0-191 python /projects/prjs1222/GLOBGM/analysis/_yoda_archive/_rechunk_ensemble_annual.py

# for model in $models; do
#     for scen in $scenarios; do
#         cd "$temp_dir/annual" || { echo "Failed to cd to $temp_dir/annual"; exit 1; }
#         for var in "wtd" "hds"; do
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


# for model in $models; do
#     for scen in $scenarios; do
#         for var in "wtd" "hds"; do
#             if [ "$scen" == "historical" ]; then
#                 fileName=${var}_annual_1960_2014_${scen}_${model}.zarr
#             else
#                 fileName=${var}_annual_2015_2100_${scen}_${model}.zarr
#             fi
#             dirPath="$temp_dir/annual/$fileName"
#             echo $dirPath
#             mpirun -np 190 drm $dirPath
#             wait
#         done
#     done
# done



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
