"""Build the 15-degree clone tiles and their index from the global landmask.

A tile is kept iff it holds at least one land cell, so the count follows from
the landmask: 157, not the published 163. The extra six sit in the 30N-15N
band, hold no land in the landmask (nor a valid cell in `lddsound_30sec`, whose
valid mask the landmask equals) and no rule in any input produces them.

`datamap` builds tile filenames as ``<pref><i>-<ntile>.nc``, so the count is
part of every name; the index is written as ``<pref><ntile>.txt`` to match.
Only tiles intersecting the window are rasterised; the index always lists all.

Usage: make_tiles.py <landmask.nc> <out_dir> <pref> [gir0 gir1 gic0 gic1]
"""
import sys
from pathlib import Path

import netCDF4
import numpy as np

from globgm_raster import Header, write_nc

TILE_DEG = 15.0


def main(landmask_nc, out_dir, pref, window=None):
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    d = netCDF4.Dataset(landmask_nc)
    v = d["data"]
    v.set_auto_maskandscale(False)
    nrow, ncol = v.shape
    side = round(ncol * TILE_DEG / 360.0)
    if ncol % side or nrow % side:
        raise ValueError(f"{ncol}x{nrow} is not a whole number of {TILE_DEG} deg tiles")
    dx = float(d.getncattr("dx"))

    tiles = []
    for jr in range(nrow // side):
        band = v[jr * side:(jr + 1) * side, :]
        for jc in range(ncol // side):
            if band[:, jc * side:(jc + 1) * side].any():
                tiles.append((jc * side + 1, (jc + 1) * side,
                              jr * side + 1, (jr + 1) * side))
    n = len(tiles)

    index = out / f"{pref}{n}.txt"
    with open(index, "w") as fh:
        fh.write(f"{n} {ncol} {nrow}\n")
        for ic0, ic1, ir0, ir1 in tiles:
            fh.write(f"{ic0} {ic1} {ir0} {ir1} 0 0 0 0\n")

    written = 0
    for i, (ic0, ic1, ir0, ir1) in enumerate(tiles, 1):
        if window is not None:
            gir0, gir1, gic0, gic1 = window
            if ic1 < gic0 or ic0 > gic1 or ir1 < gir0 or ir0 > gir1:
                continue
        xmin = -180.0 + (ic0 - 1) // side * TILE_DEG
        ymax = 90.0 - (ir0 - 1) // side * TILE_DEG
        hdr = Header(ncol=side, nrow=side, xmin=xmin, ymin=ymax - TILE_DEG,
                     xmax=xmin + TILE_DEG, ymax=ymax, dx=dx, dy=dx,
                     nodata=0.0, dtype="<f4")
        blk = np.array(v[ir0 - 1:ir1, ic0 - 1:ic1], dtype="<f4")
        write_nc(out / f"{pref}{i:03d}-{n:03d}.nc", hdr, blk)
        written += 1

    print(f"wrote {index} ({n} tiles) and {written} tile rasters")


if __name__ == "__main__":
    a = sys.argv[1:]
    main(a[0], a[1], a[2], tuple(int(x) for x in a[3:7]) if len(a) > 3 else None)
