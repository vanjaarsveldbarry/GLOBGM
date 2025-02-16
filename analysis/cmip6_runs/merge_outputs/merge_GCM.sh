#!/bin/bash -l

GCM=
time_chunk=6

cd /home/bvjaarsveld1/projects/workflow/GLOBGM/analysis/cmip6_runs/merge_outputs

# sbatch --export=scenario="historical",variable="wtd",GCM="ipsl-cm6a-lr",time_chunk=${time_chunk} \
#        --output=/home/bvjaarsveld1/projects/workflow/GLOBGM/analysis/cmip6_runs/merge_outputs/slurmOut/merge_GCM_${GCM}_wtd_hist.out \
#        _merge_GCM.slurm
# sbatch --export=scenario="historical",variable="hds",GCM="ipsl-cm6a-lr",time_chunk=${time_chunk} \
#        --output=/home/bvjaarsveld1/projects/workflow/GLOBGM/analysis/cmip6_runs/merge_outputs/slurmOut/merge_GCM_${GCM}_hds_hist.out \
#        _merge_GCM.slurm
# sbatch --export=scenario="ssp126",variable="wtd",GCM="ipsl-cm6a-lr",time_chunk=${time_chunk} \
#        --output=/home/bvjaarsveld1/projects/workflow/GLOBGM/analysis/cmip6_runs/merge_outputs/slurmOut/merge_GCM_${GCM}_wtd_ssp126.out \
#        _merge_GCM.slurm
# sbatch --export=scenario="ssp126",variable="hds",GCM="ipsl-cm6a-lr",time_chunk=${time_chunk} \
#        --output=/home/bvjaarsveld1/projects/workflow/GLOBGM/analysis/cmip6_runs/merge_outputs/slurmOut/merge_GCM_${GCM}_hds_ssp126.out \
#        _merge_GCM.slurm
# sbatch --export=scenario="ssp370",variable="wtd",GCM="ipsl-cm6a-lr",time_chunk=${time_chunk} \
#        --output=/home/bvjaarsveld1/projects/workflow/GLOBGM/analysis/cmip6_runs/merge_outputs/slurmOut/merge_GCM_${GCM}_wtd_ssp370.out \
#        _merge_GCM.slurm
# sbatch --export=scenario="ssp370",variable="hds",GCM="ipsl-cm6a-lr",time_chunk=${time_chunk} \
#        --output=/home/bvjaarsveld1/projects/workflow/GLOBGM/analysis/cmip6_runs/merge_outputs/slurmOut/merge_GCM_${GCM}_hds_ssp370.out \
#        _merge_GCM.slurm
sbatch --export=scenario="ssp585",variable="wtd",GCM="ipsl-cm6a-lr",time_chunk=${time_chunk} \
       --output=/home/bvjaarsveld1/projects/workflow/GLOBGM/analysis/cmip6_runs/merge_outputs/slurmOut/merge_GCM_${GCM}_wtd_ssp585.out \
       _merge_GCM.slurm
sbatch --export=scenario="ssp585",variable="hds",GCM="ipsl-cm6a-lr",time_chunk=${time_chunk} \
       --output=/home/bvjaarsveld1/projects/workflow/GLOBGM/analysis/cmip6_runs/merge_outputs/slurmOut/merge_GCM_${GCM}_hds_ssp585.out \
       _merge_GCM.slurm