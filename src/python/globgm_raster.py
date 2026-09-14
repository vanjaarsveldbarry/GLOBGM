"""Lossless conversion of GLOBGM legacy rasters (iMOD IDF, ESRI EHdr .flt) to
the NetCDF layout read by the Fortran ``raster_io`` module. The attribute set
written here is the one ``raster_io.f90``'s ``write_skeleton`` writes, so
Python- and Fortran-written rasters are interchangeable.

Usage: globgm_raster.py <src.idf|src.flt> <dst.nc>
"""
import sys
from dataclasses import dataclass
from pathlib import Path

import netCDF4
import numpy as np

IDF_MAGIC = {1271: "<f4", 2295: "<f8"}
BAND = 1024     # rows per put; a global raster is never materialised
CHUNK = 256


@dataclass
class Header:
    ncol: int
    nrow: int
    xmin: float
    ymin: float
    xmax: float
    ymax: float
    dx: float
    dy: float
    nodata: float | int
    dtype: str  # numpy dtype string, e.g. "<f4"


def read_idf(path):
    """Returns (header, memmap[nrow, ncol]) with row 0 = north."""
    with open(path, "rb") as fh:
        magic = int(np.fromfile(fh, "<i4", 1)[0])
        ftype = IDF_MAGIC[magic]
        itype = np.dtype(ftype).itemsize
        fh.seek(0)
        raw = fh.read(13 * itype)

    def rec(i):  # record i (1-based), itype bytes each
        return raw[(i - 1) * itype:i * itype]

    ncol = int(np.frombuffer(rec(2)[:4], "<i4")[0])
    nrow = int(np.frombuffer(rec(3)[:4], "<i4")[0])
    xmin, xmax, ymin, ymax, _dmin, _dmax, nodata = (
        float(np.frombuffer(rec(i), ftype)[0]) for i in range(4, 11))
    ieq, itb = np.frombuffer(rec(11)[:2], "i1")
    if ieq:
        raise ValueError(f"{path}: non-equidistant IDF (ieq=1) is not supported")
    dx = float(np.frombuffer(rec(12), ftype)[0])
    dy = float(np.frombuffer(rec(13), ftype)[0])
    offset = (15 if itb else 13) * itype
    hdr = Header(ncol, nrow, xmin, ymin, xmax, ymax, dx, dy, nodata, ftype)
    return hdr, np.memmap(path, dtype=ftype, mode="r", offset=offset, shape=(nrow, ncol))


def read_flt(path):
    """EHdr raster as written by gdal_rasterize -of EHdr: <name>.hdr + <name>.flt.
    Returns (header, memmap[nrow, ncol])."""
    path = Path(path)
    keys = {}
    for line in path.with_suffix(".hdr").read_text().splitlines():
        parts = line.split()
        if len(parts) >= 2:
            keys[parts[0].lower()] = parts[1]
    ncol, nrow = int(keys["ncols"]), int(keys["nrows"])
    if "xllcorner" in keys:                        # ESRI dialect
        xll, yll, cs = float(keys["xllcorner"]), float(keys["yllcorner"]), float(keys["cellsize"])
    else:                                          # GDAL dialect: UL cell centre
        cs = float(keys["xdim"])
        if float(keys["ydim"]) != cs:
            raise ValueError(f"{path}: non-square cells")
        xll = float(keys["ulxmap"]) - 0.5 * cs
        yll = float(keys["ulymap"]) + 0.5 * cs - nrow * cs
    nbits = int(keys.get("nbits", "32"))
    ptype = keys.get("pixeltype", "float").lower()
    order = "<" if keys.get("byteorder", "lsbfirst").lower() in ("lsbfirst", "i") else ">"
    kind = "f" if ptype.startswith("float") else "i" if ptype.startswith("signed") else "u"
    dtype = f"{order}{kind}{nbits // 8}"
    nodata_s = keys.get("nodata_value", keys.get("nodata", "0"))
    nodata = float(nodata_s) if kind == "f" else int(float(nodata_s))
    arr = np.memmap(path, dtype=dtype, mode="r", shape=(nrow, ncol))
    if order == ">":
        arr = np.array(arr).astype("<" + dtype[1:])
    hdr = Header(ncol, nrow, xll, yll, xll + ncol * cs, yll + nrow * cs, cs, cs, nodata, "<" + dtype[1:])
    return hdr, arr


def write_nc(path, hdr, arr, times=None):
    """``arr[nrow, ncol]``, row 0 = north; anything supporting ``arr[r0:r1]``
    row-band slicing (memmap, ndarray, or a lazily computed view). With
    ``times=(values, units)`` the array is ``arr[nt, nrow, ncol]`` and gets a
    leading ``time`` dimension."""
    dtype = np.dtype(hdr.dtype)
    nt = len(times[0]) if times else None
    shape = (nt, hdr.nrow, hdr.ncol) if times else (hdr.nrow, hdr.ncol)
    if tuple(arr.shape) != shape:
        raise ValueError(f"array {arr.shape} does not match header {shape}")
    if np.dtype(arr.dtype) != dtype:
        raise ValueError(f"array dtype {arr.dtype} != header dtype {dtype}")
    nodata = np.array(hdr.nodata, dtype=dtype)[()]
    with netCDF4.Dataset(path, "w", format="NETCDF4") as ds:
        ds.createDimension("lat", hdr.nrow)
        ds.createDimension("lon", hdr.ncol)
        vlat = ds.createVariable("lat", "f8", ("lat",))
        vlon = ds.createVariable("lon", "f8", ("lon",))
        vlat.units = "degrees_north"
        vlon.units = "degrees_east"
        vlat[:] = hdr.ymax - (np.arange(hdr.nrow) + 0.5) * hdr.dy
        vlon[:] = hdr.xmin + (np.arange(hdr.ncol) + 0.5) * hdr.dx
        dims, chunks = ("lat", "lon"), (min(CHUNK, hdr.nrow), min(CHUNK, hdr.ncol))
        if times:
            ds.createDimension("time", nt)
            vt = ds.createVariable("time", "f8", ("time",))
            vt.units = times[1]
            vt.calendar = "standard"
            vt[:] = times[0]
            dims, chunks = ("time",) + dims, (1,) + chunks
        v = ds.createVariable("data", dtype, dims, zlib=True, complevel=1,
                              chunksizes=chunks, fill_value=nodata)
        v.set_auto_maskandscale(False)
        for t in range(nt) if times else [None]:
            a = arr if t is None else arr[t]
            for r0 in range(0, hdr.nrow, BAND):
                blk = np.ascontiguousarray(a[r0:r0 + BAND])
                if dtype.kind == "f" and np.isnan(blk).any():
                    raise ValueError("NaN in raster; nodata must be a finite value")
                if t is None:
                    v[r0:r0 + BAND, :] = blk
                else:
                    v[t, r0:r0 + BAND, :] = blk
        for k in ("xmin", "ymin", "xmax", "ymax", "dx", "dy"):
            ds.setncattr(k, np.float64(getattr(hdr, k)))
        ds.setncattr("nrow", np.int32(hdr.nrow))
        ds.setncattr("ncol", np.int32(hdr.ncol))
        ds.Conventions = "CF-1.8"
        ds.source = "globgm_raster.write_nc"


def convert(src, dst):
    reader = {".idf": read_idf, ".flt": read_flt}[Path(src).suffix.lower()]
    hdr, arr = reader(src)
    write_nc(dst, hdr, arr)
    return hdr


if __name__ == "__main__":
    src, dst = sys.argv[1:3]
    hdr = convert(src, dst)
    print(f"{dst}: {hdr.nrow}x{hdr.ncol} {hdr.dtype} nodata={hdr.nodata}")
