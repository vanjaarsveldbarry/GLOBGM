#!/bin/bash -l

data_dir=$1
mkdir -p $data_dir

scp -r eejit:/scratch/depfg/7006713/globgm_input/_bin $data_dir
scp -r eejit:/scratch/depfg/7006713/globgm_input/cmip6_input $data_dir
scp -r eejit:/scratch/depfg/7006713/globgm_input/globgm_input $data_dir
scp -r eejit:/scratch/depfg/7006713/globgm_input/initial_states $data_dir