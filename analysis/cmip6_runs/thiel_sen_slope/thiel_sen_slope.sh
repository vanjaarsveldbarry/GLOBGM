#!/bin/bash -l

cd /home/bvjaarsveld1/projects/workflow/GLOBGM/analysis/cmip6_runs/thiel_sen_slope
sbatch --export=GCM="ipsl-cm6a-lr",scenario="historical",variable="hds" \
       --output=/home/bvjaarsveld1/projects/workflow/GLOBGM/analysis/cmip6_runs/thiel_sen_slope/slurmOut/thiel_sen_ipsl-cm6a-lr_historical_hds.out \
       _thiel_sen_slope.slurm

# sbatch --export=GCM="ipsl-cm6a-lr",scenario="historical",variable="wtd" \
#        --output=/home/bvjaarsveld1/projects/workflow/GLOBGM/analysis/cmip6_runs/thiel_sen_slope/slurmOut/thiel_sen_ipsl-cm6a-lr_historical_wtd.out \
#        _thiel_sen_slope.slurm

# sbatch --export=GCM="ipsl-cm6a-lr",scenario="ssp126",variable="hds" \
#        --output=/home/bvjaarsveld1/projects/workflow/GLOBGM/analysis/cmip6_runs/thiel_sen_slope/slurmOut/thiel_sen_ipsl-cm6a-lr_ssp126_hds.out \
#        _thiel_sen_slope.slurm

# sbatch --export=GCM="ipsl-cm6a-lr",scenario="ssp126",variable="wtd" \
#        --output=/home/bvjaarsveld1/projects/workflow/GLOBGM/analysis/cmip6_runs/thiel_sen_slope/slurmOut/thiel_sen_ipsl-cm6a-lr_ssp126_wtd.out \
#        _thiel_sen_slope.slurm


sbatch --export=GCM="ipsl-cm6a-lr",scenario="ssp370",variable="hds" \
       --output=/home/bvjaarsveld1/projects/workflow/GLOBGM/analysis/cmip6_runs/thiel_sen_slope/slurmOut/thiel_sen_ipsl-cm6a-lr_ssp370_hds.out \
       _thiel_sen_slope.slurm

# sbatch --export=GCM="ipsl-cm6a-lr",scenario="ssp370",variable="wtd" \
#        --output=/home/bvjaarsveld1/projects/workflow/GLOBGM/analysis/cmip6_runs/thiel_sen_slope/slurmOut/thiel_sen_ipsl-cm6a-lr_ssp370_wtd.out \
       # _thiel_sen_slope.slurm
sbatch --export=GCM="ipsl-cm6a-lr",scenario="ssp585",variable="hds" \
       --output=/home/bvjaarsveld1/projects/workflow/GLOBGM/analysis/cmip6_runs/thiel_sen_slope/slurmOut/thiel_sen_ipsl-cm6a-lr_ssp585_hds.out \
       _thiel_sen_slope.slurm

# sbatch --export=GCM="ipsl-cm6a-lr",scenario="ssp585",variable="wtd" \
#        --output=/home/bvjaarsveld1/projects/workflow/GLOBGM/analysis/cmip6_runs/thiel_sen_slope/slurmOut/thiel_sen_ipsl-cm6a-lr_ssp585_wtd.out \
#        _thiel_sen_slope.slurm
