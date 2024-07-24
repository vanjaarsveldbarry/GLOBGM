import flopy as fp
from pathlib import Path
from tqdm import tqdm
import sys

## Write the binary files
inputFolder = Path(sys.argv[1]).parent.parent / 'models/run_output_bin'
saveDir=inputFolder / '_ini_hds'
saveDir.mkdir(exist_ok=True)
files= list(inputFolder.glob('*.tr.hds'))
for file in files:
    file = Path(file)
    savePath=saveDir / file.name
    hds=fp.utils.binaryfile.HeadFile(file, text='HEAD')
    idx=len(hds.get_times())-1
    aa = hds.get_data(idx=idx)
    _aa_shape=aa.shape
    text = "HEAD"
    ilay = 1
    pertim = 31
    totim = int(365*((idx+1)/12))
    kper = idx
    kstp = 31
    nrow = 1
    ncol = _aa_shape[2]
    _shape = (1, nrow, ncol)
    header = fp.utils.BinaryHeader.create(bintype="head", precision="double",
                                         text=text, nrow=nrow, ncol=ncol,
                                         ilay=1, pertim=pertim,
                                         totim=totim, kstp=kstp, kper=kper)
    fp.utils.Util2d.write_bin(_shape, savePath, aa, header_data=header)

##CHANGE THE PATHS
modDir=inputFolder.parent.parent.parent.parent
currentModDir=inputFolder.parent.parent.parent.name[-4:]
directories = [d for d in modDir.iterdir() if d.is_dir()]
dirPool=[]
for directory in directories:
    dirName=directory.name[-4:]
    if int(currentModDir) <= int(dirName):
        dirPool.append(dirName)
        
maxDir= max(dirPool)
dirPool = [d for d in dirPool if d != dirName and d != maxDir]
if len(dirPool) !=0:
    targetDir= min(dirPool)
    targetDir=modDir / f'mf6_mod_{targetDir}'
    iniFilesDir=targetDir / 'glob_tr/models/run_input'
    files = [path for path in Path(iniFilesDir).rglob("m*.spu.ic")]
    iniHDSFolder=iniFilesDir / 'ini_hds'
    for file in files:
        model=file.name[:-7]
        newPath=inputFolder/f'_ini_hds/{model}.tr.hds (BINARY)'
        line=f"  OPEN/CLOSE {newPath}"
        with open(file, 'r') as f:
            lines = f.readlines()
        with open(file, 'w') as f:
            for l in lines:
                if "OPEN/CLOSE" in l:
                    f.write(line + "\n")
                else:
                    f.write(l)