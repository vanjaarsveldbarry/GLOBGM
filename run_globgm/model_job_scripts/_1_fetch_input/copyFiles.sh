#!/bin/bash -l

modelRoot=$1

simulation=$(basename "$modelRoot")

originPath=/gpfs/work2/0/dfguu2/users/edwin/pcrglobwb_wri_aqueduct_2021/pcrglobwb_aqueduct_2021_monthly_annual_files/version_2021-09-16_merged/$simulation
targetPath=$modelRoot/cmip6_input
cd "$originPath" && find . -name "*pcrglobwb_cmip6*gwRecharge_global_monthly-total*" -print0 | rsync -av --files-from=- --from0 . "$targetPath"
cd "$originPath" && find . -name "*pcrglobwb_cmip6*totalGroundwaterAbstraction_global_monthly-total*" -print0 | rsync -av --files-from=- --from0 . "$targetPath"
cd "$originPath" && find . -name "*pcrglobwb_cmip6*totalRunoff_global_monthly-total*" -print0 | rsync -av --files-from=- --from0 . "$targetPath"