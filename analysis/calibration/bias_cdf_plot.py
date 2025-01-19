from pathlib import Path
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import warnings
# Silence the PerformanceWarning
warnings.filterwarnings("ignore", category=pd.errors.PerformanceWarning)

dataFolder = Path("/projects/prjs1222/globgm_output/calibration/calibration/validation/ss_validation_output/observed_gwh_for_ss_valex_hotspots")
saveFolder = Path("/projects/prjs1222/GLOBGM/analysis/calibration/_plots")
selected_parameter_setting= 'khuncon0.1_khcon0.1_khcar0.1_kvconf0.1_riverres0.1'	


df_merged = pd.DataFrame()
data_files = sorted((dataFolder).glob('*.csv'))
data_files = [file for file in data_files if 'bias_results_jarno_ss.csv' not in file.name]
for file in sorted(data_files):
    data = pd.read_csv(file)['bias']
    name = file.name[13:-4]
    df_merged[name] = data *-1
print(df_merged,shape)

df_selected = df_merged[[selected_parameter_setting]]
df_merged = df_merged.drop(columns=[selected_parameter_setting])

plt.figure(figsize=(10, 6))
for i, column in enumerate(df_merged.columns):
    if column != selected_parameter_setting:
        sns.ecdfplot(data=df_merged, x=column, linewidth=2, color='gray', alpha=0.1, legend=False)

sns.ecdfplot(data=df_selected, x=selected_parameter_setting, linewidth=2, label='Best', color='red')

plt.plot([], [], color='gray', alpha=0.1, linewidth=2, label='Others')

plt.xlabel('Bias ($obs - sim$)')
plt.axvline(x=0, color='black', linestyle='--')
plt.ylabel('CDF')
plt.xlim(-50, 50)
plt.legend(loc='upper left')
plt.savefig(saveFolder / f'bias_cdf_plot.png')