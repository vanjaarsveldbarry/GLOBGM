import flopy as fp
from pathlib import Path
import sys

## Write the binary files
inputFolder = Path(sys.argv[1])
saveDir = Path(sys.argv[2])
saveDir=saveDir / '_ini_hds'
saveDir.mkdir(exist_ok=True)
files= list(inputFolder.glob('*.tr.hds'))
for file in files:
    file = Path(file)
    savePath=saveDir / file.name
    try:
        hds = fp.utils.binaryfile.HeadFile(file, text='HEAD')
    except Exception as e:
        continue
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