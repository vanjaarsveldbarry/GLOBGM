#!/bin/bash -l

data_dir=$1
iRodsPassword=$2

mkdir -p $data_dir

# scp -r eejit:/scratch/depfg/7006713/globgm_input/_bin $data_dir
scp -r eejit:/scratch/depfg/7006713/globgm_input/cmip6_input $data_dir
# scp -r eejit:/scratch/depfg/7006713/globgm_input/globgm_input $data_dir


# module load 2023
# module load iRODS-iCommands/4.3.0

# # Create a temporary file to store the password
# password_file=$(mktemp)
# echo "$iRodsPassword" > $password_file

# # Use the password file with iinit
# iinit < $password_file

# # Remove the temporary password file
# rm -f $password_file

# iget -r /nluu14p/home/deposit-pilot/globgm/initial_states/_ini_hds $data_dir/globgm_input