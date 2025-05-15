#!/bin/bash -l
#SBATCH --partition=fat_genoa
#SBATCH -N 1
#SBATCH -t 12:00:00
#SBATCH -J ref
#SBATCH --cpus-per-task 1 
#SBATCH --ntasks-per-node=192
#SBATCH --exclusive
#SBATCH --output=/projects/prjs1222/GLOBGM/analysis/cmip6_runs/merge_outputs/slurmOut/merge_ref.out


source ${HOME}/.bashrc
mamba activate globgm

cd /projects/prjs1222/GLOBGM/analysis/cmip6_runs/merge_outputs

scenario="gswp3-w5e5"
GCMs=("historical_no_pump" "historical_with_pump")

for GCM in "${GCMs[@]}"; do
    input_dir=/projects/prjs1222/globgm_output/_backup/$GCM/$scenario/mf6_post
    save_dir=/projects/prjs1222/globgm_output/reference_gswp3-w5e5/$GCM/merged

    mkdir -p $save_dir
    python -u ./initilalise_zarrStore.py $save_dir $input_dir "wtd" & \
    python -u ./initilalise_zarrStore.py $save_dir $input_dir "hds"
done
wait

cpu_start=0
for GCM in "${GCMs[@]}"; do
    input_dir=/projects/prjs1222/globgm_output/_backup/$GCM/$scenario/mf6_post
    save_dir=/projects/prjs1222/globgm_output/reference_gswp3-w5e5/$GCM/merged
    
    taskset -c $cpu_start-$((cpu_start+15)) python -u ./merge_outputs.py $save_dir $input_dir "wtd" &
    taskset -c $((cpu_start+16))-$((cpu_start+31)) python -u ./merge_outputs.py $save_dir $input_dir "hds" &
    cpu_start=$((cpu_start+32))
done
wait