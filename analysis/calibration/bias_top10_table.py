from pathlib import Path
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import warnings
# Silence the PerformanceWarning
warnings.filterwarnings("ignore", category=pd.errors.PerformanceWarning)
pd.set_option('display.max_colwidth', None)
dataFolder = Path("/projects/prjs1222/globgm_output/calibration/calibration/validation/ss_validation_output/observed_gwh_for_ss_valex_hotspots")
saveFolder = Path("/projects/prjs1222/GLOBGM/analysis/calibration/_plots")
selected_parameter_setting= 'khuncon0.1_khcon0.1_khcar0.1_kvconf0.1_riverres0.1'	

depth_cats = labels = ["<0", "0-5", "5-10", "10-20", "20-60", ">60"]

data_files = sorted((dataFolder).glob('*.csv'))
data_files = [file for file in data_files if 'bias_results_jarno_ss.csv' not in file.name]
print(len(data_files))
for i, file in enumerate(sorted(data_files)):
    if i == 0:
        df_merged = pd.read_csv(file)
        df_merged['depth_category'] = pd.cut(df_merged['obs_gw'], bins=[-float('inf'), 0, 5, 10, 20, 60, float('inf')], labels=depth_cats)
        df_merged = df_merged[['depth_category', 'bias']].rename(columns={'bias': file.name[13:-4]})
        df_merged[file.name[13:-4]] = df_merged[file.name[13:-4]].abs()
        df_merged = df_merged.groupby('depth_category', observed=False).mean().reset_index()
        overall_mean_row = df_merged.iloc[:, 1:].mean(axis=0).to_frame().T
        df_merged = pd.concat([df_merged, overall_mean_row], ignore_index=True)
        df_merged['depth_category'] = df_merged['depth_category'].cat.add_categories(['overall_mean'])
        df_merged.iloc[-1, 0] = 'overall_mean'
    else:
        data = pd.read_csv(file)
        data['depth_category'] = pd.cut(data['obs_gw'], bins=[-float('inf'), 0, 5, 10, 20, 60, float('inf')], labels=depth_cats)
        data = data[['depth_category', 'bias']].rename(columns={'bias': file.name[13:-4]})
        data[file.name[13:-4]] = data[file.name[13:-4]].abs()
        data = data.groupby('depth_category', observed=False).mean().reset_index()
        overall_mean_row = data.iloc[:, 1:].mean(axis=0).to_frame().T
        data = pd.concat([data, overall_mean_row], ignore_index=True)
        data['depth_category'] = data['depth_category'].cat.add_categories(['overall_mean'])
        data.iloc[-1, 0] = 'overall_mean'
        df_merged = pd.merge(df_merged, data, on=['depth_category'], how='inner')
        
df_melted = df_merged.melt(id_vars=['depth_category'], var_name='Name', value_name='Bias')
df_pivoted = df_melted.pivot(index='Name', columns='depth_category', values='Bias')
df_pivoted = df_pivoted.sort_values(by='overall_mean', ascending=True)
df_top10 = df_pivoted.head(10)
df_top10 = df_top10.sort_values(by='0-5', ascending=True)
df_top10 = df_top10.round(1)
df_top10.to_csv(saveFolder / 'top10_bias.csv')