#!/bin/bash -l
#SBATCH -N 1
#SBATCH -J sn_ss_W5E5
#SBATCH -t 24:00:00
#SBATCH --partition=genoa
#SBATCH --output=/projects/0/einf4705/workflow/GLOBGM/run_globgm/model_job_scripts/sn_W5E5.out

source ${HOME}/.bashrc
mamba activate globgm

simulation=gswp3-w5e5
outputDirectory=/projects/0/einf4705/workflow/output/ss_no_downscale
run_globgm_dir=/projects/0/einf4705/workflow/GLOBGM/run_globgm
data_dir=/projects/0/einf4705/_data

cd $run_globgm_dir/model_job_scripts

#TEST ONE RULE
# snakemake --unlock --rerun-incomplete --cores 1 --force -R --until prepare_model_partitioning \
# snakemake --rerun-incomplete --cores 1 --force -R --until run_models \
# --snakefile Snakefile_W5E5_ss.smk \
# --config simulation=$simulation \
#          outputDirectory=$outputDirectory \
#          run_globgm_dir=$run_globgm_dir \
#          data_dir=$data_dir
         
#FULL RUN
snakemake --cores 16 \
--snakefile Snakefile_W5E5_ss.smk \
--config simulation=$simulation \
         outputDirectory=$outputDirectory \
         run_globgm_dir=$run_globgm_dir \
         data_dir=$data_dir

# linear_multiplier_for_kh_unconsolidated: 0.1 , 1.0 , 10.0
# linear_multiplier_for_kh_consolidated: 0.1 , 1.0 , 10.0
# linear_multiplier_for_kh_carbonate: 0.1 , 1.0 , 10.0
# linear_multiplier_for_kv_confining_layer: 0.1 , 1.0
# linear_multiplier_for_river_bed_resistance: 0.1 , 1.0 , 10.0

# kh_unconsolidated=(0.1 1.0 10.0)
# kh_consolidated=(0.1 1.0 10.0)
# kh_carbonate=(0.1 1.0 10.0)
# kv_confining_layer=(0.1 1.0)
# river_bed_resistance=(0.1 1.0 10.0)

# Receive the serialized arrays
# array1_str=$1
# array2_str=$2

# # Deserialize the arrays
# IFS=',' read -r -a array1 <<< "$array1_str"
# IFS=',' read -r -a array2 <<< "$array2_str"

# # Print the array elements
# echo "Array 1 elements:"
# for element in "${array1[@]}"; do
#     echo "$element"
# done

# echo "Array 2 elements:"
# for element in "${array2[@]}"; do
#     echo "$element"
# done

# count=0
# for kh_un in "${kh_unconsolidated[@]}"; do
#   for kh_con in "${kh_consolidated[@]}"; do
#     for kh_car in "${kh_carbonate[@]}"; do
#       for kv_conf in "${kv_confining_layer[@]}"; do
#         for river_res in "${river_bed_resistance[@]}"; do
#           echo "kh_unconsolidated: $kh_un"
#           echo "kh_consolidated: $kh_con"
#           echo "kh_carbonate: $kh_car" 
#           echo "kv_confining_layer: $kv_conf"
#           echo "river_bed_resistance: $river_res"
#           count=$((count + 1))
#         done
#       done
#     done
#   done
# done

# echo "Total combinations: $count"