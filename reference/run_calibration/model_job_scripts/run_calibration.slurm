#! /usr/bin/zsh
#SBATCH -N 1
#SBATCH -J sn_ss_W5E5
#SBATCH -t 12:00:00
#SBATCH --partition=genoa,rome
#SBATCH --output=/projects/0/einf4705/workflow/GLOBGM/run_calibration/model_job_scripts/_slurmOut/calib_%a.out
#SBATCH --array=1


source ${HOME}/.bashrc
mamba activate globgm

run_globgm_dir=/home/bvjaarsveld1/projects/workflow/GLOBGM/run_calibration
cd $run_globgm_dir/model_job_scripts

simulation=gswp3-w5e5
outputDirectory=/scratch-shared/_bvjaarsveld1/output_calibration
data_dir=/scratch-shared/_bvjaarsveld1/_data
savedir="/scratch-shared/_bvjaarsveld1/calibrationOut"

# bash ./_fetch_data.sh $data_dir

# kh_unconsolidated=(0.1 1.0 10.0)
# kh_consolidated=(0.1 1.0 10.0)
# kh_carbonate=(0.1 1.0 10.0)
# kv_confining_layer=(0.1 1.0)
# river_bed_resistance=(0.1 1.0 10.0)

kh_unconsolidated=(1.0)
kh_consolidated=(1.0)
kh_carbonate=(1.0)
kv_confining_layer=(1.0)
river_bed_resistance=(1.0)


SLURM_ARRAY_TASK_ID=1
count=0
for kh_un in "${kh_unconsolidated[@]}"; do
 for kh_con in "${kh_consolidated[@]}"; do
    for kh_car in "${kh_carbonate[@]}"; do
      for kv_conf in "${kv_confining_layer[@]}"; do
        for river_res in "${river_bed_resistance[@]}"; do
          count=$((count + 1))
          if [ $count -eq $SLURM_ARRAY_TASK_ID ]; then
            calib_str="khuncon${kh_un}_khcon${kh_con}_khcar${kh_car}_kvconf${kv_conf}_riverres${river_res}"
            echo $calib_str 
            snakemake --cores 16 \
            --executor slurm --jobs 20 --default-resources slurm_account=uusei11758 \
            --snakefile run_calibration.smk \
            --config simulation=$simulation \
                        outputDirectory=$outputDirectory \
                        run_globgm_dir=$run_globgm_dir \
                        data_dir=$data_dir \
                        calib_str=$calib_str \
                        savedir=$savedir
          fi
        done
      done
    done
  done
done
# echo "Total combinations: $count"