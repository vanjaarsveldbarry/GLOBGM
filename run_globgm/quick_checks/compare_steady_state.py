"""Compare the ported steady-state heads/wtd against the original GLOBGM ss.zarr.

Each s<NN>_<var>.ss.<date>_l<L>.nc in NEW_DIR is a regional window for one
solution and layer; the matching window of ORIG_ZARR/<var> (model='ss', layer=L)
is selected by coordinate and compared on the cells the new run has values for.
Each comparison also writes <name>.old_minus_new.nc (ss.zarr minus port) to DIFF_DIR.

    cd /gpfs/work4/0/prjs1222/globgm_port/GLOBGM
    pixi run python run_globgm/quick_checks/compare_steady_state.py
"""

import argparse
import re
from pathlib import Path

import numpy as np
import xarray as xr

NEW_DIR = Path("/gpfs/work4/0/prjs1222/globgm_port/output/run_globgm/post/steady-state")
ORIG_ZARR = Path("/gpfs/work4/0/prjs1222/globgm_output/steady_state/ss.zarr")
DIFF_DIR = Path("/gpfs/work4/0/prjs1222/globgm_port/output/run_globgm/post/diff")
NAME_RE = re.compile(r"s(\d+)_(hds|wtd)\.ss\.\d+_l(\d)\.nc")


def select_window(orig, lat, lon):
    win = orig.sel(latitude=lat, longitude=lon, method="nearest")
    dlat = np.abs(win.latitude.values - lat).max()
    dlon = np.abs(win.longitude.values - lon).max()
    if max(dlat, dlon) > 1e-6:
        raise ValueError(f"grid offset vs zarr lat={dlat:.2e} lon={dlon:.2e}")
    return win


def report(label, a, b, lat, lon, rtol, atol):
    a = a.astype(np.float64)
    b = b.astype(np.float64)
    va, vb = np.isfinite(a), np.isfinite(b)
    both = va & vb
    print(f"\n== {label}  (window {a.shape})")
    print(f"  valid new: {va.sum():,}   orig: {vb.sum():,}   both: {both.sum():,}   "
          f"new-only: {(va & ~vb).sum():,}   orig-only: {(~va & vb).sum():,}")
    if not both.any():
        print("  -> NO OVERLAP")
        return False
    d = a[both] - b[both]
    ad = np.abs(d)
    close = np.isclose(a[both], b[both], rtol=rtol, atol=atol)
    print(f"  mean new / orig: {a[both].mean():.6g} / {b[both].mean():.6g}")
    print(f"  bias: {d.mean():.6g}   MAE: {ad.mean():.6g}   RMSE: {np.sqrt((d * d).mean()):.6g}   max|diff|: {ad.max():.6g}")
    print(f"  |diff| p50/p90/p99: " + " / ".join(f"{q:.4g}" for q in np.percentile(ad, [50, 90, 99])))
    print(f"  exact: {100 * (ad == 0).mean():.4f}%   close (rtol={rtol}, atol={atol}): {100 * close.mean():.4f}%")
    r, c = np.argwhere(both)[ad.argmax()]
    print(f"  worst cell: lat={lat[r]:.5f} lon={lon[c]:.5f} new={a[r, c]:.6g} orig={b[r, c]:.6g}")
    ok = va.sum() == vb.sum() == both.sum() and close.all()
    print(f"  -> {'MATCH' if ok else 'DIFFERS'}")
    return ok


def compare(path, z, rtol, atol, diff_dir):
    m = NAME_RE.fullmatch(path.name)
    if m is None:
        raise ValueError(f"unexpected file name {path.name}")
    var, layer = m.group(2), int(m.group(3))

    new = xr.open_dataset(path)["data"]
    lat, lon = new.lat.values, new.lon.values
    orig = select_window(z[var].sel(layer=layer), lat, lon).values
    a = new.values
    b = np.where(np.isfinite(a), orig, np.nan)
    diff = xr.DataArray((b - a).astype(np.float32), coords={"lat": lat, "lon": lon}, dims=("lat", "lon"),
                        name=f"{var}_old_minus_new", attrs={"long_name": f"{var} layer {layer}: ss.zarr minus port", "units": "m"})
    out = diff_dir / path.name.replace(".nc", ".old_minus_new.nc")
    diff.to_netcdf(out, encoding={diff.name: {"zlib": True, "complevel": 4, "_FillValue": np.float32(np.nan)}})
    print(f"\n  wrote {out}")
    return report(f"{path.name}  ({var}, layer {layer})", a, b, lat, lon, rtol, atol)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--new-dir", type=Path, default=NEW_DIR)
    p.add_argument("--orig", type=Path, default=ORIG_ZARR)
    p.add_argument("--diff-dir", type=Path, default=DIFF_DIR, help="where the old-minus-new rasters go")
    p.add_argument("--rtol", type=float, default=1e-5)
    p.add_argument("--atol", type=float, default=1e-3)
    args = p.parse_args()

    z = xr.open_zarr(args.orig).sel(model="ss")
    files = sorted(args.new_dir.glob("s*_*.ss.*_l*.nc"))
    if not files:
        raise FileNotFoundError(f"no head/wtd files in {args.new_dir}")
    args.diff_dir.mkdir(parents=True, exist_ok=True)

    results = {f.name: compare(f, z, args.rtol, args.atol, args.diff_dir) for f in files}

    print("\n== Summary")
    for name, ok in results.items():
        print(f"  {'MATCH' if ok else 'DIFF':5s} {name}")


if __name__ == "__main__":
    main()
