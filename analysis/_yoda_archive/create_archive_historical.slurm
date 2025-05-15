#!/bin/bash -l
#SBATCH --partition=fat_genoa
#SBATCH -N 1
#SBATCH -t 32:00:00
#SBATCH -J _yoda
#SBATCH --cpus-per-task 1
#SBATCH --ntasks-per-node=24
#SBATCH --output=/projects/prjs1222/GLOBGM/analysis/_yoda_archive/create_historical.out

module load 2023
module load iRODS-iCommands/4.3.0 
module load mpifileutils/0.11.1-gompi-2023a


source ${HOME}/.bashrc
mamba activate globgm

root_dir=/projects/prjs1222/globgm_output/reference_gswp3-w5e5
temp_dir=/projects/prjs1222/scratch_backup/globgm_scratch/archive/reference_gswp3-w5e5

#organise average  
# for var in "hds" "wtd"; do
#     sourcePath=$root_dir/historical_with_pump/avg/$var.nc
#     echo $sourcePath
#     mkdir -p $temp_dir/average
#     cd $temp_dir/average
#     fileName=${var}_reference_gswp3-w5e5_average_1960_2019.nc
#     cp $sourcePath $temp_dir/average/$fileName
# done


# organise annual
# for var in "hds" "wtd"; do
#     sourcePath=$root_dir/historical_with_pump/annual/$var.zarr
#     mkdir -p $temp_dir/annual_temp $temp_dir/annual
#     fileName=${var}_reference_gswp3-w5e5_annual_1960_2019.zarr
#     # mpirun -np 190 dcp $sourcePath $temp_dir/annual_temp/$fileName
# done

# taskset -c 0-191 python /projects/prjs1222/GLOBGM/analysis/_yoda_archive/_rechunk_hist_annaul.py

# for var in "hds" "wtd"; do
    # sourcePath=$root_dir/historical_with_pump/annual/$var.zarr
    # mkdir -p $temp_dir/annual_temp $temp_dir/annual
    # fileName=${var}_reference_gswp3-w5e5_annual_1960_2019.zarr
    # cd $temp_dir/annual/$fileName
    # pwd
    # zip -r0 ../$fileName.zip ./
    # mpirun -np 20 drm $temp_dir/annual/$fileName
# done

# organise monthly
# for var in "wtd" "hds"; do
#     sourcePath=$root_dir/historical_with_pump/merged/$var.zarr
#     mkdir -p $temp_dir/monthly $temp_dir/monthly_temp
#     cd $temp_dir/monthly
#     fileName=${var}_reference_gswp3-w5e5_monthly_1960_2019.zarr
#     echo $sourcePath
#     mpirun -np 190 dcp $sourcePath $temp_dir/monthly_temp/$fileName
# done

# taskset -c 0-191 python /projects/prjs1222/GLOBGM/analysis/_yoda_archive/_rechunk_hist_monthly.py
cd "$temp_dir/monthly" || { echo "Failed to cd to $temp_dir/monthly"; exit 1; }
for var in "wtd" "hds"; do
    fileName="${var}_reference_gswp3-w5e5_monthly_1960_2019.zarr"
    dirPath="$temp_dir/monthly/$fileName"

    if [ -d "$dirPath" ]; then
        (
            cd "$dirPath" || { echo "Failed to cd to $dirPath"; exit 1; }
            zip -r0 "../${fileName}.zip" ./
        ) &
    else
        echo "Directory $dirPath does not exist, skipping."
    fi
done

wait
