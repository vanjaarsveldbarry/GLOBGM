import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import warnings
from pathlib import Path    

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

df_selected = df_merged[[selected_parameter_setting]]
df_merged = df_merged.drop(columns=[selected_parameter_setting])

plt.figure(figsize=(10.5, 10.5))
for i, column in enumerate(df_merged.columns):
    if column != selected_parameter_setting:
        sns.ecdfplot(data=df_merged, x=column, linewidth=2, color='gray', alpha=0.1, legend=False)

plt.plot([], [], color='gray', alpha=0.1, linewidth=2, label='Other Calib. Settings')
sns.ecdfplot(data=df_selected, x=selected_parameter_setting, linewidth=4, label='Chosen Calib. Setting', color='blue')


for file in data_files:
    if 'khuncon1.0_khcon1.0_khcar1.0_kvconf1.0_riverres1.0.csv' in file.name:
        uncalibrated_file = file
        uncalibrated_data = pd.read_csv(uncalibrated_file)['bias'] * -1
        sns.ecdfplot(uncalibrated_data, linewidth=4, label='Uncalibrated', color='hotpink')

# Plot jarno_ss.csv data in black
if jarno_ss_file:
    jarno_ss_data = pd.read_csv(jarno_ss_file)['bias'] * -1
    sns.ecdfplot(jarno_ss_data, linewidth=2, label='GLOBGM V1', color='black')


plt.axvline(x=0, color='black', linestyle='--')
plt.xlim(-50, 50)
plt.legend(loc='upper left', frameon=False, fontsize=17)
plt.tick_params(direction='in', labelsize=19)
plt.xlabel('Water Table Depth Bias (m)', fontsize=21)
plt.ylabel('CDF', fontsize=21)
plt.savefig(saveFolder / f'bias_cdf_plot.png', bbox_inches='tight', dpi=800)    