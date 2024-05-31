#!/bin/bash

#SBATCH -t 16:00:00

#~ #SBATCH --output=ss_%j.out
#~ #SBATCH --error=ss_%j.err

#SBATCH -p genoa
#SBATCH -N 1

#SBATCH -n 192

MODEL_SCRIPT_FOLDER="/home/edwinbar/github/edwinkost/GLOBGM/model_tools_src/python/pcr-globwb/"
INI_FILE="/home/edwinbar/github/edwinkost/GLOBGM/model_input/1_write_tiled_parameter_data/develop/steady-state_config_develop_edwinbar.ini"

TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE="/scratch-shared/edwinbar/globgm_tile_map_files_for_arfan/map_input/steady-state/average/ini_files/"

#~ cd {git_dir}/model_tools_src/python/pcr-globwb

cd ${MODEL_SCRIPT_FOLDER}


# activate the pcrglobwb conda environment
. /home/edwin/load_all_default.sh


python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_001-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_002-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_003-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_004-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_005-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_006-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_007-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_008-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_009-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_010-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
wait

python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_011-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_012-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_013-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_014-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_015-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_016-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_017-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_018-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_019-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_020-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
wait

python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_021-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_022-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_023-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_024-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_025-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_026-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_027-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_028-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_029-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_030-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
wait

python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_031-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_032-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_033-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_034-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_035-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_036-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_037-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_038-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_039-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_040-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
wait

python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_041-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_042-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_043-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_044-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_045-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_046-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_047-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_048-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_049-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_050-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
wait

python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_051-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_052-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_053-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_054-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_055-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_056-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_057-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_058-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_059-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_060-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
wait

python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_061-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_062-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_063-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_064-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_065-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_066-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_067-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_068-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_069-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_070-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
wait

python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_071-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_072-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_073-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_074-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_075-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_076-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_077-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_078-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_079-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_080-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
wait

python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_081-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_082-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_083-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_084-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_085-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_086-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_087-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_088-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_089-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_090-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
wait

python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_091-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_092-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_093-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_094-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_095-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_096-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_097-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_098-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_099-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_100-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
wait

python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_101-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_102-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_103-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_104-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_105-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_106-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_107-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_108-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_109-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_110-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
wait

python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_111-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_112-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_113-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_114-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_115-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_116-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_117-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_118-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_119-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_120-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
wait

python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_121-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_122-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_123-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_124-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_125-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_126-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_127-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_128-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_129-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_130-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
wait

python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_131-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_132-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_133-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_134-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_135-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_136-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_137-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_138-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_139-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_140-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
wait

python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_141-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_142-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_143-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_144-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_145-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_146-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_147-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_148-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_149-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_150-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
wait

python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_151-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_152-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_153-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_154-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_155-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_156-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_157-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_158-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_159-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_160-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
wait

python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_161-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_162-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
python deterministic_runner_for_monthly_offline_globgm.py ${INI_FILE} debug steady-state-only tile_163-163 ${TMP_FOLDER_FOR_THE_MODIFIED_INI_FILE} &
wait
