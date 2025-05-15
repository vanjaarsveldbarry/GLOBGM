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
# df_merged = df_merged.drop(columns=[selected_parameter_setting])


# for i, column in enumerate(df_merged.columns):
#     if column != selected_parameter_setting:
#         sns.ecdfplot(data=df_merged, x=column, linewidth=2, color='gray', alpha=0.1, legend=False)

# plt.plot([], [], color='gray', alpha=0.1, linewidth=2, label='Other Calibration Settings')
# sns.ecdfplot(data=df_selected, x=selected_parameter_setting, linewidth=4, label='Chosen Calibration Setting', color='blue')


for file in data_files:
    if 'khuncon1.0_khcon1.0_khcar1.0_kvconf1.0_riverres1.0.csv' in file.name:
        uncalibrated_file = file
        uncalibrated_data = pd.read_csv(uncalibrated_file)['bias'] * -1
        # sns.ecdfplot(uncalibrated_data, linewidth=4, label='Uncalibrated', color='blue', linestyle='--')

# Plot jarno_ss.csv data in black
if jarno_ss_file:
    jarno_ss_data = pd.read_csv(jarno_ss_file)['bias'] * -1
    # sns.ecdfplot(jarno_ss_data, linewidth=2, label='GLOBGM V1', color='black')

print(jarno_ss_data)
# Combine jarno_ss_data, uncalibrated_data, and selected_parameter_setting into one DataFrame
combined_data = pd.DataFrame({
    'bias': pd.concat([jarno_ss_data, uncalibrated_data, df_selected[selected_parameter_setting]]),
    'type': (['GLOBGM V1'] * len(jarno_ss_data)) +
            (['Uncalibrated'] * len(uncalibrated_data)) +
            (['Chosen Calibration Setting'] * len(df_selected))
})

print(combined_data)
# Calculate the mean bias for each type
mean_bias = combined_data.groupby('type', dropna=True)['bias'].mean().reset_index()
mean_bias = mean_bias.dropna()  # Ensure no NaN values are present

# Create a points plot to show the difference in mean bias
plt.figure(figsize=(7.15, 10.5))
sns.stripplot(data=combined_data, y='type', x='bias', order=['GLOBGM V1', 'Uncalibrated', 'Chosen Calibration Setting'], jitter=0.4, 
            palette={'GLOBGM V1': 'black', 'Uncalibrated': 'hotpink', 'Chosen Calibration Setting': 'blue'}, alpha=0.02, zorder=1, orient='h')
sns.pointplot(data=mean_bias, y='type', x='bias', order=['GLOBGM V1', 'Uncalibrated', 'Chosen Calibration Setting'], 
              palette={'GLOBGM V1': 'black', 'Uncalibrated': 'hotpink', 'Chosen Calibration Setting': 'blue'}, 
              join=False, markers='o', scale=1.5, errwidth=1, zorder=2, orient='h')

plt.axvline(x=0, color='black', linestyle='--', linewidth=1, zorder=2)
plt.gca().yaxis.set_ticklabels([])
plt.ylabel(' ')
plt.xlabel(' ')
plt.tight_layout()
plt.tick_params(direction='in', labelsize=19)
plt.xlim(-14, 14)
plt.xticks(ticks=range(-14, 15, 2))
plt.xlabel('Water Table Depth Bias (m)', fontsize=21)
plt.savefig(saveFolder / 'bias_distribution_comparison.png', bbox_inches='tight',  dpi=800)
