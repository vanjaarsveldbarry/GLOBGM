"""Merge the 244 PCR-GLOBWB clone tiles of each forcing file into one global
30" NetCDF in the `raster_io` layout of `globgm_raster.write_nc`; NaN/fill
becomes NODATA, values are left as in the source.
Tiles overlap but their valid cells barely do (~0.2%, catchment edges): there
discharge takes the larger value (more upstream area), the rest the first.

The main process writes an empty file per variable with write_nc's attributes
and chunking; every (file, month, row band) is merged and compressed (shuffle +
deflate, as write_nc) by a worker, and the main process only writes the chunks
(h5py direct chunk write), so all cores work.

Usage: merge_forcing.py <forcing_30sec dir> <period, e.g. 1979_1994> <out_dir>
"""
import os
import sys
import zlib
import multiprocessing
from pathlib import Path

import h5py
import netCDF4
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "src" / "python"))
from globgm_raster import CHUNK  # noqa: E402

NODATA = np.float32(-9999.0)
D = 1 / 120
NROW, NCOL = 21600, 43200
BAND = 8 * CHUNK   # rows per work unit
FILES = ("discharge_monthAvg_output.nc", "gwRecharge_monthTot_output.nc",
         "totalGroundwaterAbstraction_monthTot_output.nc")

TILES = {}   # name -> [(path, var, r0, r1, c0, c1)], set before the pool forks
OPEN = {}    # per worker: path -> netCDF variable


def tiles(paths):
    out = []
    for p in paths:
        with netCDF4.Dataset(p) as ds:
            var = next(v for v in ds.variables if v not in ("time", "lat", "lon"))
            lat, lon = ds["lat"][:].astype("f8"), ds["lon"][:].astype("f8")
        r0 = round((90 - (lat[0] + D / 2)) / D)
        c0 = round((lon[0] - D / 2 + 180) / D)
        out.append((str(p), var, r0, r0 + lat.size, c0, c0 + lon.size))
    return out


def skeleton(path, times):
    """The file write_nc writes, without the data."""
    with netCDF4.Dataset(path, "w", format="NETCDF4") as ds:
        ds.createDimension("time", len(times[0]))
        ds.createDimension("lat", NROW)
        ds.createDimension("lon", NCOL)
        vt = ds.createVariable("time", "f8", ("time",))
        vt.units, vt.calendar = times[1], "standard"
        vt[:] = times[0]
        vlat = ds.createVariable("lat", "f8", ("lat",))
        vlon = ds.createVariable("lon", "f8", ("lon",))
        vlat.units, vlon.units = "degrees_north", "degrees_east"
        vlat[:] = 90.0 - (np.arange(NROW) + 0.5) * D
        vlon[:] = -180.0 + (np.arange(NCOL) + 0.5) * D
        ds.createVariable("data", "<f4", ("time", "lat", "lon"), zlib=True, complevel=1,
                          shuffle=True, chunksizes=(1, CHUNK, CHUNK), fill_value=NODATA)
        for k, v in (("xmin", -180.0), ("ymin", -90.0), ("xmax", 180.0), ("ymax", 90.0),
                     ("dx", D), ("dy", D)):
            ds.setncattr(k, np.float64(v))
        ds.setncattr("nrow", np.int32(NROW))
        ds.setncattr("ncol", np.int32(NCOL))
        ds.Conventions = "CF-1.8"
        ds.source = "globgm_raster.write_nc"


def unit(args):
    """Merge rows [b0, b0+BAND) of month t and return its compressed chunks."""
    name, t, b0 = args
    b1 = min(b0 + BAND, NROW)
    g = np.full((b1 - b0, NCOL), np.nan, "<f4")
    for p, var, r0, r1, c0, c1 in TILES[name]:
        lo, hi = max(r0, b0), min(r1, b1)
        if lo >= hi:
            continue
        if p not in OPEN:
            OPEN[p] = netCDF4.Dataset(p)[var]
            OPEN[p].set_var_chunk_cache(size=0)   # else every open tile keeps a month cached
        a = OPEN[p][t, lo - r0:hi - r0, :].filled(np.nan).astype("<f4")
        sub = g[lo - b0:hi - b0, c0:c1]
        if name.startswith("discharge"):
            np.fmax(sub, a, out=sub)
        else:
            np.copyto(sub, a, where=np.isnan(sub))
    g[np.isnan(g)] = NODATA
    chunks = []
    for r in range(0, b1 - b0, CHUNK):
        for c in range(0, NCOL, CHUNK):
            blk = np.full((CHUNK, CHUNK), NODATA, "<f4")   # edge chunks are padded
            part = g[r:r + CHUNK, c:c + CHUNK]
            blk[:part.shape[0], :part.shape[1]] = part
            shuffled = blk.view("u1").reshape(-1, 4).T.tobytes()
            chunks.append(((t, b0 + r, c), zlib.compress(shuffled, 1)))
    return name, chunks


def main(src, period, out_dir):
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    nt, work = {}, []
    for name in FILES:
        TILES[name] = tiles(sorted(Path(src).glob(f"*/{period}/netcdf/{name}")))
        with netCDF4.Dataset(TILES[name][0][0]) as ds:
            times = ds["time"][:].astype("f8"), ds["time"].units
        skeleton(out_dir / name, times)
        nt[name] = len(times[0])
        work += [(name, t, b0) for t in range(nt[name]) for b0 in range(0, NROW, BAND)]
        print(f"{name}: {len(TILES[name])} tiles, {nt[name]} months", flush=True)
    files = {n: h5py.File(out_dir / n, "r+") for n in FILES}
    dsets = {n: f["data"] for n, f in files.items()}
    n = os.cpu_count()
    # fork, so the workers inherit TILES
    with multiprocessing.get_context("fork").Pool(n) as p:
        i = 0
        # batches bound the finished units waiting here to be written
        for b in range(0, len(work), 4 * n):
            for name, chunks in p.imap_unordered(unit, work[b:b + 4 * n]):
                for off, data in chunks:
                    dsets[name].id.write_direct_chunk(off, data, filter_mask=0)
                i += 1
                if i % 100 == 0 or i == len(work):
                    print(f"{i} out of {len(work)} units", flush=True)
    for f in files.values():
        f.close()


if __name__ == "__main__":
    main(*sys.argv[1:4])
