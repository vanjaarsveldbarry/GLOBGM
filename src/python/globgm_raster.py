"""Rasters in the NetCDF layout read by the Fortran ``raster_io`` module. The
attribute set written here is the one ``raster_io.f90``'s ``write_skeleton``
writes, so Python- and Fortran-written rasters are interchangeable.
"""
from dataclasses import dataclass

import netCDF4
import numpy as np

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


def write_nc(path, hdr, arr, zlib=True):
    """``arr[nrow, ncol]``, row 0 = north; anything supporting ``arr[r0:r1]``
    row-band slicing (memmap, ndarray, or a lazily computed view)."""
    dtype = np.dtype(hdr.dtype)
    shape = (hdr.nrow, hdr.ncol)
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
        v = ds.createVariable("data", dtype, ("lat", "lon"), zlib=zlib, complevel=1,
                              chunksizes=(min(CHUNK, hdr.nrow), min(CHUNK, hdr.ncol)),
                              fill_value=nodata)
        v.set_auto_maskandscale(False)
        for r0 in range(0, hdr.nrow, BAND):
            blk = np.ascontiguousarray(arr[r0:r0 + BAND])
            if dtype.kind == "f" and np.isnan(blk).any():
                raise ValueError("NaN in raster; nodata must be a finite value")
            v[r0:r0 + BAND, :] = blk
        for k in ("xmin", "ymin", "xmax", "ymax", "dx", "dy"):
            ds.setncattr(k, np.float64(getattr(hdr, k)))
        ds.setncattr("nrow", np.int32(hdr.nrow))
        ds.setncattr("ncol", np.int32(hdr.ncol))
        ds.Conventions = "CF-1.8"
        ds.source = "globgm_raster.write_nc"
