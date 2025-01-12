import flopy as fp
from pathlib import Path
import sys

# id_mod=sys.argv[1][-1]
# id_previous=int(id_mod)
modDir = Path(sys.argv[1])
# previusModDir=Path(f"{sys.argv[1][:-1]}{id_previous}")

iniFilesDir=modDir / 'glob_tr/models/run_input'
source_dir=modDir / 'glob_tr/models/run_output_bin/_ini_hds'
files = [path for path in Path(iniFilesDir).rglob("m*.spu.ic")]
for file in files:
    model=file.name[:-7]
    newPath=source_dir/f'{model}.tr.hds (BINARY)'
    line=f"  OPEN/CLOSE {newPath}"
    with open(file, 'r') as f:
        lines = f.readlines()
    with open(file, 'w') as f:
        for l in lines:
            if "OPEN/CLOSE" in l:
                f.write(line + "\n")
            else:
                f.write(l)