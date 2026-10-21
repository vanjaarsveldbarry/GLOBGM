"""Rasterize datamap's map_glob.*.bin outputs to georeferenced NetCDF for
inspection in QGIS/ncview/Panoply: domain (land/sea boundary), nlay, the
catchment id and the region id datamap assigned each catchment to.

The five map_glob.*.bin files are raw Fortran stream writes (open_file's
lbin=.true. uses access='stream'), so there are no record markers to skip;
see src/fortran/datamap/datamap.f90 for the write order this mirrors.
intfnodes.bin (inter-catchment interface edges) has no raster meaning and
is not read here.

Usage: inspect_datamap.py [--datamap-dir DIR] [--params params.json] [--out-dir DIR]
"""
import argparse
import json
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).parent))
from globgm_raster import Header, write_nc  # noqa: E402


def read_catch(path):
    with open(path, "rb") as f:
        mxlid = int(np.fromfile(f, "<i4", 1)[0])
        _mja = int(np.fromfile(f, "<i4", 1)[0])
        ia = np.fromfile(f, "<i4", mxlid + 1)  # 1-based pointers into data
        data = np.fromfile(f, "<i4")
    offsets = ia[:-1] - 1  # 0-based, one per catchment local id 1..mxlid
    nlnd = data[offsets + 4]
    nsea = data[offsets + 5]
    return mxlid, nlnd + nsea


def read_reg(path, mxlid):
    with open(path, "rb") as f:
        nreg = int(np.fromfile(f, "<i4", 1)[0])
        nlist = int(np.fromfile(f, "<i4", 1)[0])
        regncell = np.fromfile(f, "<f8", nreg)
        ia = np.fromfile(f, "<i4", nreg + 1)
        data = np.fromfile(f, "<i4", nlist)
    cat_to_reg = np.zeros(mxlid + 1, dtype="<i4")  # index by local catchment id
    for r in range(1, nreg + 1):
        cat_to_reg[data[ia[r - 1] - 1:ia[r] - 1]] = r
    return nreg, regncell, cat_to_reg


def read_nodes(path, n):
    arr = np.fromfile(path, dtype="<i4", count=2 * n).reshape(n, 2)
    return arr[:, 0], arr[:, 1]  # jc (negative if sea), jr


def rasterize(datamap_dir, gir0, gir1, gic0, gic1):
    mxlid, cat_sizes = read_catch(datamap_dir / "map_glob.catch.bin")
    nreg, regncell, cat_to_reg = read_reg(datamap_dir / "map_glob.reg.bin", mxlid)
    n = cat_sizes.sum()
    n_file = Path(datamap_dir / "map_glob.nodes.bin").stat().st_size // 8
    if n != n_file:
        raise ValueError(f"catch.bin node count {n} != nodes.bin node count {n_file}")
    jc, jr = read_nodes(datamap_dir / "map_glob.nodes.bin", n)
    nlay = np.fromfile(datamap_dir / "map_glob.nlay.bin", dtype="i1", count=n)
    cat_id = np.repeat(np.arange(1, mxlid + 1, dtype="<i4"), cat_sizes)  # node order == catchment order
    #
    nrow, ncol = gir1 - gir0 + 1, gic1 - gic0 + 1
    row, col = jr - gir0, np.abs(jc) - gic0
    domain = np.zeros((nrow, ncol), dtype="i1")
    domain[row, col] = np.where(jc < 0, 2, 1)  # 1 land, 2 sea boundary
    nlay_r = np.zeros((nrow, ncol), dtype="i1")
    nlay_r[row, col] = nlay
    catch_r = np.zeros((nrow, ncol), dtype="<i4")
    catch_r[row, col] = cat_id
    reg_r = np.zeros((nrow, ncol), dtype="<i4")
    reg_r[row, col] = cat_to_reg[cat_id]
    #
    print(f"catchments: {mxlid}, regions: {nreg}, active nodes: {n}")
    print(f"land: {(domain == 1).sum()}, sea boundary: {(domain == 2).sum()}")
    top = min(nreg, 10)
    print(f"top {top} regions (regncell is datamap's own METIS weight: nlay summed per cell, not a cell count):")
    for i in range(top):
        print(f"  {i + 1:2d}  weight={int(regncell[i]):>10d}  catchments={int((cat_to_reg == i + 1).sum()):>6d}")
    return domain, nlay_r, catch_r, reg_r


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--datamap-dir", type=Path, default=Path("../output/run_globgm/datamap"))
    ap.add_argument("--params", type=Path, default=Path("../output/run_globgm/config/params.json"))
    ap.add_argument("--out-dir", type=Path, default=None)
    args = ap.parse_args()
    out_dir = args.out_dir or args.datamap_dir / "inspect"
    out_dir.mkdir(parents=True, exist_ok=True)
    #
    params = json.loads(args.params.read_text())
    grid = params["preprocess_inputs"]["grid"]
    gir0, gir1, gic0, gic1 = (int(x) for x in params["map_glob"]["window"].split())
    ymax_global = grid["ymin"] + grid["nrow"] * grid["cellsize"]
    dx = grid["cellsize"]
    xmin = grid["xmin"] + (gic0 - 1) * dx
    xmax = grid["xmin"] + gic1 * dx
    ymax = ymax_global - (gir0 - 1) * dx
    ymin = ymax_global - gir1 * dx
    #
    domain, nlay_r, catch_r, reg_r = rasterize(args.datamap_dir, gir0, gir1, gic0, gic1)
    nrow, ncol = gir1 - gir0 + 1, gic1 - gic0 + 1
    rasters = {
        "domain": (domain, "<i1"),      # 0 inactive, 1 land, 2 sea boundary
        "nlay": (nlay_r, "<i1"),        # 0 inactive, 1 or 2
        "catchment_id": (catch_r, "<i4"),  # 0 inactive, else local catchment id
        "region_id": (reg_r, "<i4"),    # 0 inactive, else region rank (1 = largest)
    }
    for name, (arr, dtype) in rasters.items():
        hdr = Header(ncol, nrow, xmin, ymin, xmax, ymax, dx, dx, 0, dtype)
        dst = out_dir / f"{name}.nc"
        write_nc(dst, hdr, arr.astype(dtype))
        print(f"wrote {dst}")


if __name__ == "__main__":
    main()
