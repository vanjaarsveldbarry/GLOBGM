import os
import sys
import re
from pathlib import Path

def get_error_info(file_path):
    with open(file_path, 'r') as file:
        for line in file:
            if 'error' in line.lower():
                return line.strip()
    return None

def process_files(directory, saveFolder):
    with open(f'{saveFolder}connections_output.txt', 'w') as output_file:
        output_file.write('subModel' 'tile_number\n')
        
        for root, dirs, files in os.walk(directory):
            for file in files:
                file_path = os.path.join(root, file)
                error_info = get_error_info(file_path)
                if error_info:
                    match = re.search(r'tile_(\d+-\d+)', error_info)
                    if match:
                        tile_number = match.group(1)
                        tile_number = tile_number[:3]
                        file_path = Path(file_path).stem
                        file_pathNumber = file_path[1:]
                        output_file.write(f'{file_pathNumber} {tile_number}\n')

# Replace 'directory_path' with the path to the directory containing the files
directory_path = sys.argv[1]
saveFolder = sys.argv[2]
process_files(directory_path, saveFolder)

tile_dict = {}

# Open the file and read line by line
with open(f'{saveFolder}connections_output.txt', 'r') as file:
    next(file)  # Skip the header
    for line in file:
        subModel, tile_number = line.strip().split()
        
        # Check if tile_number is in the dictionary
        if tile_number in tile_dict:
            tile_dict[tile_number].add(subModel)
        else:
            tile_dict[tile_number] = {subModel}

# Print the unique tile_numbers and their associated subModels
with open(f'{saveFolder}_tile_mapping.txt', 'w') as f:
    for tile_number, subModels in tile_dict.items():
        f.write(f"{tile_number}, {subModels}\n")