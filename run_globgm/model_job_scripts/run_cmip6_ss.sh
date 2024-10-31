#!/bin/bash -l
#SBATCH -N 1
#SBATCH -J sn_ss_W5E5
#SBATCH -t 24:00:00
#SBATCH --partition=genoa
#SBATCH --output=/projects/0/einf4705/workflow/GLOBGM/run_globgm/model_job_scripts/_slurmOut/calib_%a.out
#SBATCH --array=1


source ${HOME}/.bashrc
mamba activate globgm

simulation=gswp3-w5e5
outputDirectory=/projects/0/einf4705/workflow/output_test
run_globgm_dir=/projects/0/einf4705/workflow/GLOBGM/run_globgm
data_dir=/projects/0/einf4705/_data

cd $run_globgm_dir/model_job_scripts

kh_unconsolidated=(0.1 1.0 10.0)
kh_consolidated=(0.1 1.0 10.0)
kh_carbonate=(0.1 1.0 10.0)
kv_confining_layer=(0.1 1.0)
river_bed_resistance=(0.1 1.0 10.0)

count=0
for kh_un in "${kh_unconsolidated[@]}"; do
 for kh_con in "${kh_consolidated[@]}"; do
    for kh_car in "${kh_carbonate[@]}"; do
      for kv_conf in "${kv_confining_layer[@]}"; do
        for river_res in "${river_bed_resistance[@]}"; do
            calib_str="khuncon${kh_un}_khcon${kh_con}_khcar${kh_car}_kvconf${kv_conf}_riverres${kv_conf}"
            count=$((count + 1))
            if [ $count -eq $SLURM_ARRAY_TASK_ID ]; then
              echo $calib_str
              # snakemake -n --cores 16 \
              # --snakefile Snakefile_W5E5_ss.smk \
              # --config simulation=$simulation \
              #             outputDirectory=$outputDirectory \
              #             run_globgm_dir=$run_globgm_dir \
              #             data_dir=$data_dir \
              #             calib_str=$calib_str
            fi
# break
        done
# break
      done
# break
    done
# break
  done
# break
done

echo "Total combinations: $count"