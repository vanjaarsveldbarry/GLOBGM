"""Regenerate d_top_2 (upper/confining layer thickness, m) from the PCR-GLOBWB
DEM and confining-layer rasters, as groundwater_MODFLOW.py:set_grid_for_two_layer_model
does with usePreDefinedConfiningLayer = True, followed by the iMOD `C = A - B`
that produced the published IDF:

    dem  = cover(dem_average, 0.0)
    conf = cover(confining_layer_thickness, 0.0)
    b2   = dem - conf
    t2   = max(0.1, dem - b2)
    d_top_2 = dem - (dem - t2)

The DEM does not cancel: every subtraction rounds in float32, and replaying all
four is what makes the result bit-identical to d_top_2.idf. Doing it in one step
as max(0.1, conf) leaves ~30 % of land cells off by up to 3e-5 m, enough to move
cells across datamap's 0.1001 layer threshold.

Nodata (float32 max, as the published IDF) outside the 163 clone tiles.

Usage: make_d_top_2.py <dem_average.nc> <confining.nc> <tile_index.txt> <out.nc>
"""
import sys

import netCDF4
import numpy as np

from globgm_raster import Header, write_nc

NODATA = float(np.finfo("<f4").max)


def open_var(path, name):
    d = netCDF4.Dataset(path)
    v = d[name]
    v.set_auto_maskandscale(False)
    flip = bool(d["lat"][0] < d["lat"][-1])       # want row 0 = north
    return v, flip, np.float32(v.getncattr("_FillValue"))


def main(dem_nc, conf_nc, tiles_txt, out_nc):
    dem, dem_flip, dem_fill = open_var(dem_nc, "dem_average")
    conf, conf_flip, conf_fill = open_var(conf_nc, "thickness_deklaag")
    nrow, ncol = conf.shape
    if dem.shape != conf.shape:
        raise ValueError(f"grid mismatch: dem {dem.shape} vs confining {conf.shape}")
    dx = 360.0 / ncol
    tiles = np.loadtxt(tiles_txt, skiprows=1, usecols=(0, 1, 2, 3), dtype=np.int64)

    hdr = Header(ncol=ncol, nrow=nrow, xmin=-180.0, ymin=-90.0, xmax=180.0,
                 ymax=90.0, dx=dx, dy=dx, nodata=NODATA, dtype="<f4")

    def band(v, flip, fill, r0, r1):
        src = slice(nrow - r1, nrow - r0) if flip else slice(r0, r1)
        blk = np.array(v[src, :], dtype="<f4")
        if flip:
            blk = blk[::-1]
        blk[~np.isfinite(blk) | (blk == fill)] = 0.0     # cover(x, 0.0)
        return blk

    class Bands:
        shape = (nrow, ncol)
        dtype = np.dtype("<f4")

        def __getitem__(self, sl):
            r0, r1 = sl.start, min(sl.stop, nrow)
            a = band(dem, dem_flip, dem_fill, r0, r1)
            c = band(conf, conf_flip, conf_fill, r0, r1)
            t2 = np.maximum(np.float32(0.1), a - (a - c))
            blk = a - (a - t2)
            inside = np.zeros((r1 - r0, ncol), bool)
            for c0, c1, tr0, tr1 in tiles:                # 1-based incl.
                lo, hi = max(tr0 - 1, r0), min(tr1, r1)
                if lo < hi:
                    inside[lo - r0:hi - r0, c0 - 1:c1] = True
            blk[~inside] = np.float32(NODATA)
            return blk

    write_nc(out_nc, hdr, Bands())
    print(f"wrote {out_nc}")


if __name__ == "__main__":
    main(*sys.argv[1:5])
