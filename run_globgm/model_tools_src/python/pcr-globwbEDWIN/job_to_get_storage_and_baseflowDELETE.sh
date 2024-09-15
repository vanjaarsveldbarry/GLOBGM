
analysis_output_folder="/scratch-shared/marfan/baseflow_and_storage/average/"
modflow6_output_folder="/scratch-shared/marfan/globgm_ss/output/average/gswp3-w5e5/ss/mf6_post/"

python deterministic_runner_for_calculating_baseflow_and_groundwater_storage_develop.py ${analysis_output_folder} ${modflow6_output_folder}
