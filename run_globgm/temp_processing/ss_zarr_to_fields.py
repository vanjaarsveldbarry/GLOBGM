"""Steady-state GLOBGM zarr -> the NetCDF fields `mf6ggm` reads, one file per
2-D variable (dims model, latitude, longitude), named as the variable, in the
`raster_io` layout of `globgm_raster.write_nc`. NaN becomes `nodata`. The
rasters cover the zarr's latitude span, a window of the global 30" grid.
Variables with a layer dimension (hds, wtd) are model output, not fields, and
are skipped. NODATA is globgm.toml's [globals] nodata.

The zarr leaves the uppermost layer NaN where the column has one layer, but
mf6ggm puts that layer in the lowermost one and takes its top from
bottom_uppermost_layer, so that field is filled there with top minus
make_d_top_2.py's 0.1 m minimum confining thickness.

Usage: ss_zarr_to_fields.py <ss.zarr> <out_dir>
"""
import sys
from multiprocessing import Pool
from pathlib import Path

import numpy as np
import zarr

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "src" / "python"))
from globgm_raster import Header, write_nc  # noqa: E402

NODATA = -9999.0
WORKERS = 20
D_TOP_2_MIN = np.float32(0.1)


class Filled:
    """Row-band view of a (1, nrow, ncol) zarr array as float32, NaN -> nodata."""

    def __init__(self, arr, nodata):
        self.arr, self.nodata = arr, np.float32(nodata)
        self.shape, self.dtype = arr.shape[1:], np.dtype("<f4")

    def __getitem__(self, rows):
        a = self.arr[0, rows].astype("<f4")
        a[np.isnan(a)] = self.nodata
        return a


class BotUpper(Filled):
    """bottom_uppermost_layer with its one-layer gaps filled as top - 0.1."""

    def __init__(self, g, nodata):
        super().__init__(g["bottom_uppermost_layer"], nodata)
        self.top, self.bot2 = g["top_uppermost_layer"], g["bottom_lowermost_layer"]

    def __getitem__(self, rows):
        bot1 = self.arr[0, rows].astype("<f4")
        top = self.top[0, rows].astype("<f4")
        gap = np.isnan(bot1) & ~np.isnan(top)
        bot1[gap] = top[gap] - D_TOP_2_MIN
        bad = gap & ~(bot1 > self.bot2[0, rows].astype("<f4"))
        if bad.any():
            raise ValueError(f"rows {rows}: {bad.sum()} filled bottom_uppermost_layer "
                             "cells not above bottom_lowermost_layer")
        bot1[np.isnan(bot1)] = self.nodata
        return bot1


def convert(args):
    src, name, out_dir, nodata = args
    g = zarr.open_group(src, mode="r")
    lat, lon = g["latitude"][:], g["longitude"][:]
    d = 1 / 120
    hdr = Header(ncol=lon.size, nrow=lat.size,
                 xmin=round(lon[0] - d / 2, 6), ymin=round(lat[-1] - d / 2, 6),
                 xmax=round(lon[-1] + d / 2, 6), ymax=round(lat[0] + d / 2, 6),
                 dx=d, dy=d, nodata=nodata, dtype="<f4")
    arr = BotUpper(g, nodata) if name == "bottom_uppermost_layer" else Filled(g[name], nodata)
    write_nc(out_dir / f"{name}.nc", hdr, arr)
    return name


def main(src, out_dir):
    g = zarr.open_group(src, mode="r")
    if g["latitude"][0] < g["latitude"][-1]:
        raise ValueError(f"{src}: expected latitude north to south")
    names = sorted(k for k, a in g.arrays()
                   if a.metadata.dimension_names == ("model", "latitude", "longitude"))
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    with Pool(WORKERS) as p:
        for name in p.imap_unordered(convert, [(src, n, out_dir, NODATA) for n in names]):
            print(f"{out_dir / name}.nc", flush=True)


if __name__ == "__main__":
    main(*sys.argv[1:3])
