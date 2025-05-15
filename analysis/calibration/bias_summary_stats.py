from pathlib import Path
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import warnings

warnings.filterwarnings("ignore", category=pd.errors.PerformanceWarning)

dataFolder = Path("/projects/prjs1222/scratch_backup/globgm_scratch/calibration/calibration/validation/ss_validation_output/observed_gwh_for_ss_valex_hotspots")
saveFolder = Path("/projects/prjs1222/scratch_backup/globgm_scratch/analysis/calibration/_plots")
saveFolder.mkdir(parents=True, exist_ok=True)

selected_parameter_setting = 'khuncon0.1_khcon0.1_khcar0.1_kvconf0.1_riverres0.1'
df_merged = pd.DataFrame()
data_files = sorted((dataFolder).glob('*.csv'))
jarno_ss_file = None

# Separate jarno_ss.csv file
for file in data_files:
    if 'bias_results_jarno_ss.csv' in file.name:
        jarno_ss_file = file
        continue
    data = pd.read_csv(file)['bias']
    name = file.name[13:-4]
    df_merged[name] = data * -1

df_selected = df_merged[[selected_parameter_setting]].rename(columns={selected_parameter_setting: 'Selected'})
df_uncalibrated = df_merged[['khuncon1.0_khcon1.0_khcar1.0_kvconf1.0_riverres1.0']].rename(columns={selected_parameter_setting: 'Uncalibrated'})
jarno_ss_data = pd.read_csv(jarno_ss_file)[['bias']] * -1
jarno_ss_data = jarno_ss_data.rename(columns={'bias': 'Jarno SS'})

df_summary = pd.concat([df_selected.describe().T, df_uncalibrated.describe().T, jarno_ss_data.describe().T], axis=0)
df_summary.index = ['Selected', 'Uncalibrated', 'Jarno']
print(df_summary)
df_summary.to_csv(saveFolder / 'bias_summary_statistics.csv')