#!/bin/bash -l

source ${HOME}/.bashrc
mamba activate globgm

cd "$(dirname "$0")"

# python -u bias_cdf_plot.py
# python -u bias_top10_table.py