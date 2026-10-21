"""Compare the ported steady-state input rasters against the original GLOBGM ss.zarr.

Each <var>.nc in INPUT_DIR (global 30" grid) is compared with ORIG_ZARR/<var>
(model='ss') over the window and model domain of the steady-state head output:
the bounding box of all s<NN>_hds.*.nc in HDS_DIR, restricted to cells where
any of them has a value.

    cd /gpfs/work4/0/prjs1222/globgm_port/GLOBGM
    pixi run python run_globgm/quick_checks/compare_steady_state_inputs.py [var ...]
"""

import argparse
from pathlib import Path

import numpy as np
import xarray as xr

from compare_steady_state import NEW_DIR as HDS_DIR, ORIG_ZARR, report, select_window

INPUT_DIR = Path("/gpfs/work4/0/prjs1222/globgm_port/output/input_data/5arcmin_derived/steady-state")


def model_domain(hds_dir, lat_all, lon_all):
    files = sorted(hds_dir.glob("s*_hds.*.nc"))
    if not files:
        raise FileNotFoundError(f"no head files in {hds_dir}")
    hds = [xr.open_dataset(f)["data"] for f in files]
    lat_max = max(float(h.lat.max()) for h in hds)
    lat_min = min(float(h.lat.min()) for h in hds)
    lon_min = min(float(h.lon.min()) for h in hds)
    lon_max = max(float(h.lon.max()) for h in hds)
    tol = 1e-6
    lat = lat_all[(lat_all <= lat_max + tol) & (lat_all >= lat_min - tol)]
    lon = lon_all[(lon_all >= lon_min - tol) & (lon_all <= lon_max + tol)]
    mask = xr.DataArray(np.zeros((lat.size, lon.size), bool), coords={"lat": lat, "lon": lon})
    for h in hds:
        part = np.isfinite(h.values)
        i0 = int(np.abs(lat - float(h.lat[0])).argmin())
        j0 = int(np.abs(lon - float(h.lon[0])).argmin())
        mask.values[i0:i0 + part.shape[0], j0:j0 + part.shape[1]] |= part
    return mask


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("vars", nargs="*", help="variables to compare (default: all .nc in INPUT_DIR)")
    p.add_argument("--input-dir", type=Path, default=INPUT_DIR)
    p.add_argument("--hds-dir", type=Path, default=HDS_DIR)
    p.add_argument("--orig", type=Path, default=ORIG_ZARR)
    p.add_argument("--rtol", type=float, default=1e-5)
    p.add_argument("--atol", type=float, default=1e-6)
    args = p.parse_args()

    z = xr.open_zarr(args.orig).sel(model="ss")
    names = args.vars or sorted(f.stem for f in args.input_dir.glob("*.nc"))
    first = xr.open_dataset(args.input_dir / f"{names[0]}.nc")
    mask = model_domain(args.hds_dir, first.lat.values, first.lon.values)
    lat, lon = mask.lat.values, mask.lon.values
    m = mask.values
    print(f"window lat {lat[-1]:.4f}..{lat[0]:.4f} lon {lon[0]:.4f}..{lon[-1]:.4f}, {m.sum():,} model cells")

    results = {}
    for name in names:
        new = xr.open_dataset(args.input_dir / f"{name}.nc")["data"].sel(lat=lat, lon=lon, method="nearest")
        if max(np.abs(new.lat.values - lat).max(), np.abs(new.lon.values - lon).max()) > 1e-6:
            raise ValueError(f"{name}: grid offset vs window")
        orig = select_window(z[name], lat, lon).values
        a = np.where(m, new.values, np.nan)
        b = np.where(m, orig, np.nan)
        results[name] = report(name, a, b, lat, lon, args.rtol, args.atol)

    print("\n== Summary")
    for name, ok in results.items():
        print(f"  {'MATCH' if ok else 'DIFF':5s} {name}")


if __name__ == "__main__":
    main()
