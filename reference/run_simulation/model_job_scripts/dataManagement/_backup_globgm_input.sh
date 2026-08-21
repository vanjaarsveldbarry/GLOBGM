#!/bin/bash -l
module load 2023
module load mpifileutils/0.11.1-gompi-2023a 

# cd /projects/prjs1222
# mpirun -np 120 dtar --progress 3 -c -f "globgm_input.tar" "globgm_input"


cd /projects/prjs1222/GLOBGM/run_simulation/model_job_scripts/dataManagement
source ${HOME}/.bashrc
mamba activate globgm
saveDir=/projects/prjs1222
irodsPath="/nluu14p/home/deposit-pilot/globgm"
irods_pass='kRRKnvRE4TLIr9gx0yjW_wuCiE4eZ7iO'
# python -u ./_dag_globgm_input.py $irods_pass $saveDir/globgm_input.tar $irodsPath

sbatch --partition=staging --time=24:00:00 \
       --job-name=dag_globgm_input \
       --output=/projects/prjs1222/GLOBGM/run_simulation/model_job_scripts/dataManagement/slurmOut/globgm_input.out \
       --export=ALL,irods_pass=$irods_pass --wrap="source ${HOME}/.bashrc && mamba activate globgm && python -u ./_dag_globgm_input.py $irods_pass $saveDir/globgm_input.tar $irodsPath" 
