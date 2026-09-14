"""Derive the model land mask from the PCR-GLOBWB drainage direction raster.

A cell is land iff the ldd holds a direction there and its 8-connected ldd
component holds at least one HydroBASINS cell. The component test is what
removes Greenland: the ldd covers it, HydroBASINS does not map it at all, and
without the test `process_hydbas`'s gap fill would hand all 9.5 M of its cells
to whichever catchment lies nearest across the Davis Strait. A component is the
unit of the test, not a cell, so a rasterisation sliver cannot flip it.

The ldd declares `_FillValue = -1` and stores 255, so the test is on the
direction values themselves and the declared nodata is never used.

Usage: make_landmask.py <ldd.nc> <out.nc> <region.nc> ...
"""
import sys

import netCDF4
import numpy as np

from globgm_raster import Header, write_nc

BAND = 1080


def spanfill(unknown, seed, r, c):
    """Clear the 8-connected component of `unknown` at (r, c), returning its
    spans and whether any of them touches `seed`."""
    h, w = unknown.shape
    spans, touched = [], False

    def run(r, c):
        l = c
        while l > 0 and unknown[r, l - 1]:
            l -= 1
        rt = c
        while rt < w - 1 and unknown[r, rt + 1]:
            rt += 1
        unknown[r, l:rt + 1] = False
        return r, l, rt

    stack = [run(r, c)]
    while stack:
        r, l, rt = stack.pop()
        spans.append((r, l, rt))
        lo, hi = max(l - 1, 0), min(rt + 1, w - 1)
        if not touched:
            touched = bool(seed[r, lo] or seed[r, hi]
                           or (r > 0 and seed[r - 1, lo:hi + 1].any())
                           or (r < h - 1 and seed[r + 1, lo:hi + 1].any()))
        for nr in (r - 1, r + 1):
            if 0 <= nr < h:
                i = lo
                while i <= hi:
                    if unknown[nr, i]:
                        stack.append(run(nr, i))
                        i = stack[-1][2] + 1
                    else:
                        i += 1
    return spans, touched


def main(ldd_nc, out_nc, region_ncs):
    d = netCDF4.Dataset(ldd_nc)
    v = d["Band1"]
    v.set_auto_maskandscale(False)
    nrow, ncol = v.shape
    regions = []
    for f in region_ncs:
        rv = netCDF4.Dataset(f)["data"]
        rv.set_auto_maskandscale(False)
        regions.append(rv)

    land = np.zeros((nrow, ncol), bool)      # ldd cells with a catchment
    unknown = np.zeros((nrow, ncol), bool)   # ldd cells without one
    for r in range(0, nrow, BAND):
        ldd = v[r:r + BAND, :]
        valid = (ldd >= 1) & (ldd <= 9)
        cov = np.zeros(valid.shape, bool)
        for rv in regions:
            cov |= rv[r:r + BAND, :] != 0
        land[r:r + BAND, :] = valid & cov
        unknown[r:r + BAND, :] = valid & ~cov
    nseed = int(land.sum())

    kept = ncomp = ndrop = ndropcell = 0
    rows, cols = np.nonzero(unknown)
    for r, c in zip(rows.tolist(), cols.tolist()):
        if not unknown[r, c]:
            continue
        ncomp += 1
        spans, touched = spanfill(unknown, land, r, c)
        n = sum(rt - l + 1 for _, l, rt in spans)
        if touched:
            # safe to grow `land` inside the loop: two gap components are never
            # 8-adjacent, or they would be one component
            for sr, l, rt in spans:
                land[sr, l:rt + 1] = True
            kept += n
        else:
            ndrop += 1
            ndropcell += n
    del unknown

    dx = 360.0 / ncol
    hdr = Header(ncol=ncol, nrow=nrow, xmin=-180.0, ymin=-90.0, xmax=180.0,
                 ymax=90.0, dx=dx, dy=dx, nodata=0.0, dtype="<f4")
    class Bands:
        shape = (nrow, ncol)
        dtype = np.dtype("<f4")

        def __getitem__(self, sl):
            return land[sl].view(np.int8).astype("<f4")

    write_nc(out_nc, hdr, Bands())
    print(f"{out_nc}: {nseed + kept} land cells ({nseed} with a catchment, "
          f"{kept} in {ncomp - ndrop} gap components adjoining one; "
          f"{ndropcell} cells in {ndrop} catchment-free components dropped)")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3:])
