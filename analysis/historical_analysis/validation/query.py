import os
import psycopg2
import pandas as pd
import geopandas as gpd
import logging
from pathlib import Path

# Database connection information
db_name = 'geowat'
db_user = 'geowat_user'
db_host = 'ages-db01.geo.uu.nl'
db_pass = 'utrecht1994'
db_port = 5432


savePath = Path(r"C:\Users\7006713\OneDrive - Universiteit Utrecht\Desktop\validation_query\data")
shapefile_path = savePath / "well_locations_with_layer.shp"
layer_info_df = gpd.read_file(shapefile_path).drop_duplicates(subset=['id_gerbil'])
layer_info_df = layer_info_df[['id_gerbil', 'lon', 'lat', 'layer_no_x', 'geometry']].rename(columns={'layer_no_x': 'layer_no'})

def _getData():
    db_params = {
        'dbname': 'geowat',
        'dbuser': 'geowat_user',
        'dbhost': 'ages-db01.geo.uu.nl',
        'dbpass': 'utrecht1994',
        'dbport': 5432
    }
    
    def connect_to_dtbase(dbname, dbuser, dbhost, dbpass, dbport):
        print(f"dbname={dbname} port={dbport} user={dbuser} host={dbhost} password={dbpass}")    
        connstring = f"dbname={dbname} port={dbport} user={dbuser} host={dbhost} password={dbpass}"
        connection = psycopg2.connect(connstring)
        cursor = connection.cursor()
        return connection, cursor
    def extract_data_from_db(connection, cursor, table_name, start_year, end_year):
        sql_cmd = f"""
            SELECT * FROM public.{table_name}
            WHERE year BETWEEN {start_year} AND {end_year}
        """
        cursor.execute(sql_cmd)
        results = cursor.fetchall()

        # Extract the column names
        col_names = [desc[0] for desc in cursor.description]

        # Create a DataFrame from the results
        df = pd.DataFrame(results, columns=col_names)
        
        # Convert columns with '_gw_head_m' in their name from centimeters to meters
        for col in df.columns:
            if '_gw_head_m' in col:
                df[col] = df[col] / 100.0
        
        return df
    def extract_coordinates(connection, cursor):
        sql_cmd = "SELECT DISTINCT id_gerbil, x_wgs84, y_wgs84 FROM public._lookup_tb"
        cursor.execute(sql_cmd)
        results = cursor.fetchall()

        # Extract the column names
        col_names = [desc[0] for desc in cursor.description]

        # Create a DataFrame from the results
        df = pd.DataFrame(results, columns=col_names)
        return df
    def append_layer_to_wells(data_df, layer_info_df):
        data_df = data_df[data_df['id_gerbil'].isin(layer_info_df['id_gerbil'])]
        merged_df = data_df.merge(layer_info_df, on='id_gerbil', how='inner')
        merged_points = merged_df[['id_gerbil', 'geometry', 'layer_no', 'lon', 'lat']].drop_duplicates()
        merged_data = merged_df.drop(columns=['geometry'])
        merged_points = gpd.GeoDataFrame(merged_points, geometry='geometry')
        return merged_points, merged_data
    db_con, db_cur = connect_to_dtbase(**db_params)
    coord_df = extract_coordinates(db_con, db_cur)
    data_df = extract_data_from_db(db_con, db_cur, '_gwh_monthly_tb', 1960, 2019)

    melted_df = data_df.melt(id_vars=['id_gerbil', 'year'], var_name='month', value_name='gwh_m')
    melted_df['month'] = melted_df['month'].str.extract(r'(\d+)').astype(int)
    melted_df['date'] = pd.to_datetime(melted_df['year'].astype(str) + '-' + melted_df['month'].astype(str) + '-01')
    melted_df = melted_df[['id_gerbil', 'date', 'gwh_m']]
    melted_df = melted_df.sort_values(by=['id_gerbil', 'date']).reset_index(drop=True)
    melted_df['date'] = melted_df['date'] + pd.offsets.MonthEnd(0)
    _points, _data = append_layer_to_wells(melted_df, layer_info_df)
    _data = _data.drop_duplicates(subset=['id_gerbil', 'date'])
    _data.to_parquet(savePath / "observed_gwh_withlayers_data.parquet", index=False)
    _points.to_file(savePath / "observed_gwh_withlayers_points.gpkg", driver='GPKG')
_getData()