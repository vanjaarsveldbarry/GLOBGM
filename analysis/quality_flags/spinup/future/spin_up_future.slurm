#!/bin/bash -l
#SBATCH --partition=fat_genoa
#SBATCH -N 1
#SBATCH -t 12:00:00
#SBATCH --cpus-per-task=1
#SBATCH --ntasks-per-node=192
#SBATCH --output=/projects/prjs1222/GLOBGM/analysis/quality_flags/spinup/future/spinup_future.out

module load 2023
module load mpifileutils/0.11.1-gompi-2023a

source ${HOME}/.bashrc
mamba activate globgm


#Extract the data you'll need
input_dir=/projects/prjs1222/globgm_output/_backup/cmip6_runs/cmip6_runs/ipsl-cm6a-lr
# mpirun -np 128 dtar -x -f $input_dir.tar

data_dir=/projects/prjs1222/scratch_backup/globgm_scratch/analysis/quality_flags/data/spinup/cmip6_run/data

# for scenario in "historical" "ssp370"; do
#     _data_dir=$data_dir/$scenario
#     mkdir -p $_data_dir
#     mpirun -np 190 dcp $input_dir/$scenario/forcing_input/gwRecharge_correction_factor.zarr $_data_dir
#     mpirun -np 190 dcp $input_dir/$scenario/forcing_input/gwRecharge.zarr $_data_dir
#     cp $input_dir/$scenario/forcing_input/precipitation.nc $_data_dir
# done
cd /projects/prjs1222/GLOBGM/analysis/quality_flags/spinup/future
# taskset -c 0-191 python -u gwRecharge_corrected.py 
# wait



end_year=2100
for start_year in {2070..1950..-40}; do
    if [ $start_year -lt 1960 ]; then
        start_year=1960
    fi
    echo "Processing start_year: $start_year $end_year"
    export NUMBA_NUM_THREADS=191
    taskset -c 0-191 python -u _calc_hds_slope.py $data_dir $start_year $end_year
    taskset -c 0-191 python -u _calc_gwRecharge_slope.py $data_dir $start_year $end_year
    taskset -c 0-191 python -u create_masks_datasets.py $data_dir $start_year $end_year
    taskset -c 0-191 python -u merge_data.py $data_dir $start_year $end_year
done