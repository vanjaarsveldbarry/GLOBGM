"""The twenty fields `mf6ggm` reads, derived from the 30" inputs over the
datamap window: a port of the old PCR-GLOBWB-MODFLOW `.map` writer
(reference/run_initial_conditions/model_tools_src/python/pcr-globwb/globgm/
groundwater_MODFLOW.py; convert.md has the equations), computed in float32 as
PCRaster did and written in the `raster_io` layout of `globgm_raster.write_nc`.

Differences from the old pipeline, all because the inputs are native 30":
discharge, recharge and abstraction are used as given (no runoff routing, no
recharge correction factor); waterBodyIds are used as given (the old
relabelling only renumbers them, and only `ids > 0` reaches the fields).
Deliberate departure: the drain elevation is the DEM (the model top), and
static. The old one interpolated PCR-GLOBWB's 5' satAreaFrac over the 3"
sub-grid relief (dzRel, dem_minimum), which at 30" mismatches scales and, with
the old interpolation's use of sat rather than its offset in the level
interval, lifted drains a median 13 m above the land surface.
Likewise the river stage and bed are capped at the DEM: the channel data's
floodplain and riverbed lie above the 30" mean DEM in places, which held
heads up to 30 m above the land surface.

steady-state: forcing is the day-weighted mean over every forcing month,
abstraction zero; all twenty fields go to <out>/steady-state/.
transient: the [time] months. The fields the forcing drives get a time axis
in <out>/transient/; the static ones are hard links to the steady-state ones.

The window of every input is loaded before the workers fork (~125 GB for the
global window); workers compute and compress row bands, the main process
writes the chunks (h5py direct chunk write).

Usage: make_fields.py <fields.json> <out_dir>
with fields.json written by globgm_config.py.
"""
import calendar
import datetime
import json
import multiprocessing
import os
import sys
import zlib
from pathlib import Path

import h5py
import netCDF4
import numpy as np

from globgm_raster import CHUNK

f4 = np.float32
CHAN = ("bankfull_width", "bankfull_depth", "gradient", "dem_floodplain", "dem_riverbed")
INPUTS = {   # name: (fields.json input, variable; None for the file's only data variable)
    "ldd": ("ldd", None), "area": ("cell_area", None), "dem": ("dem", None),
    "conf": ("confining", None), "thick": ("thickness", None),
    "ksat": ("ksat", None), "sy": ("specific_yield", None), "alpha": ("recession", None),
    "khuncon": ("unconsolidated", None), "khcon": ("consolidated", None), "khcar": ("carbonate", None),
    "width": ("channel", "bankfull_width"), "depth": ("channel", "bankfull_depth"),
    "gradient": ("channel", "gradient"), "z_fpl": ("channel", "dem_floodplain"),
    "z_rb": ("channel", "dem_riverbed"),
    "frac_wat": ("lakes", "fracWaterInp"), "wb_ids": ("lakes", "waterBodyIds"),
}
# mf6ggm key -> field
STATIC_KEYS = {
    "TOP": "top", "BOT_L1": "bot_up", "BOT_L2": "bot_lo", "K_L1": "k_up", "K_L2": "k_lo",
    "K_33_L1": "k33_up", "K_33_L2": "k33_lo", "PRIM_STO_L1": "sto_up", "PRIM_STO_L2": "sto_lo",
    "STRT_L1": "top", "STRT_L2": "top", "RIV_COND_L1": "c_riv", "DRN_COND_L1:2": "c_drn",
    "DRN_ELEV_L1": "drn_up", "DRN_ELEV_L2": "drn_lo"}
FORCED_KEYS = {
    "RECHARGE": "rch", "RIV_STAGE_L1": "stage", "RIV_RBOT_L1": "rbot",
    "WEL_Q_L1": "wel_up", "WEL_Q_L2": "wel_lo"}

C = {}         # fields.json; LOADED and DAYS are set before the pool forks
LOADED = {}    # name -> window of a static input
DAYS = None    # days per period
OPEN = {}      # path -> netCDF4.Dataset; closed before the pool forks


def var(path, name=None):
    if path not in OPEN:
        OPEN[path] = netCDF4.Dataset(path)
    ds = OPEN[path]
    if name is None:
        name, = (k for k, v in ds.variables.items() if k not in ds.dimensions)
    v = ds[name]
    v.set_auto_maskandscale(False)
    return v


def as_f4(a, fill):
    a = a.astype(f4)
    a[(a == fill) | ~np.isfinite(a)] = np.nan
    return a


def read(v, rows, cols):
    """North-up window of a (time,) lat, lon variable, float32 with NaN missing."""
    a = v[(0,) * (v.ndim - 2) + (rows, cols)]
    return as_f4(a, v._FillValue)


def cover(a, v):
    """PCRaster cover; non-finite counts as missing, as x/0 is in PCRaster."""
    return np.where(np.isfinite(a), a, v).astype(f4)


def mm(a):
    return np.floor(a * f4(1000)) / f4(1000)


def static(b0, b1):
    """Inputs and static fields of window rows [b0, b1); convert.md 4.1-4.5, 4.7, 4.8."""
    pf = C["calibration"]
    s = {k: LOADED[k][b0:b1] for k in INPUTS}
    ldd = s["ldd"]
    s["land"] = (ldd > 0) & (ldd < 10)
    a = s["area"] = cover(s["area"], 0)
    s["F"] = a / f4(C["grid"]["cellsize"] ** 2)
    dem = s["dem"] = cover(s["dem"], 0)
    ksat = s["ksat"] = np.maximum(f4(0.01), cover(s["ksat"], 0))
    sy = s["sy"] = np.maximum(f4(0.01), np.minimum(f4(1), cover(s["sy"], 0)))
    alpha = np.maximum(f4(0.00025), np.minimum(f4(0.9999), cover(s["alpha"], 0)))
    D_aq = s["D_aq"] = np.minimum(f4(1000), np.maximum(f4(50), cover(s["thick"], 0)))
    conf = cover(s["conf"], 0)
    confined = conf > 0
    m = np.ones_like(a)
    for c in ("khuncon", "khcon", "khcar"):
        m *= np.where(s[c] > 0, f4(pf[c]), f4(1))

    # layer geometry
    thk_up = np.maximum(f4(0.1), dem - (dem - conf))   # float32 cancellation as the old code
    thk_lo = np.maximum(f4(5), np.maximum(D_aq, conf + f4(50)) - thk_up)
    bot_up = s["bot_up"] = dem - thk_up
    bot_lo = s["bot_lo"] = bot_up - thk_lo

    # horizontal conductivities, transmissivity in [10, M * 1e5]
    def clamp_t(k, thk):
        k = np.maximum(f4(10), k * thk) / thk
        return np.minimum(m * f4(1e5), k * thk) / thk
    k_up = clamp_t(m * np.where(confined, f4(0.008476), ksat), thk_up)
    k_lo = clamp_t(m * ksat, thk_lo)
    s["T_up"], s["T_lo"] = k_up * thk_up, k_lo * thk_lo

    # vertical conductivities, resistance in [1, 1e5] d; aquitard below the confining layer
    kv = np.where(confined, f4(0.008476 * pf["kvconf"]), ksat)
    kv = np.minimum(thk_up / f4(1), np.maximum(thk_up / f4(1e5), kv))
    with np.errstate(over="ignore"):
        k33_lo = np.where(confined, ksat, f4(1e99)) * s["F"]   # inf, as the old maps

    def sto(x):
        return np.maximum(f4(1e-20), cover(np.minimum(f4(0.5), np.maximum(f4(1e-10), x)) * s["F"], 0))

    # water bodies and river fractions
    lake = cover(s["wb_ids"], 0) > 0
    frac_wat = np.minimum(f4(1), np.maximum(f4(0), cover(s["frac_wat"], 0)))
    width = s["width"] = np.maximum(f4(5), cover(s["width"], 0))
    dy = f4(C["grid"]["cellsize"] * 60 * 1852)
    with np.errstate(divide="ignore", invalid="ignore"):
        length = np.sqrt((a / dy) ** 2 + dy ** 2)
        f_r_cell = cover(width * length / a, 0)
        tot = frac_wat + f_r_cell
        f_lr = np.minimum(f4(1), np.where(tot > 0, frac_wat / tot, f4(0)))
    f_r = np.maximum(f4(0), f4(1) - f_lr)
    s["f_lr"] = np.where(tot > 0, f_lr, f4(0))
    s["f_r"] = np.where(tot > 0, f_r, f4(0))
    s["z_rb"] = cover(s["z_rb"], 0)
    s["rbot0"] = mm(s["f_lr"] * np.where(lake, dem, f4(0)) + s["f_r"] * s["z_rb"])

    # river bed conductance: bed resistance from riverbed thickness 0.1 m and K <= 0.1 m/d
    c_b = np.maximum(f4(1), f4(0.1) / np.minimum(f4(0.1), ksat))
    c_riv = cover(frac_wat * a / c_b, 0) + cover(np.maximum(np.maximum(f4(2), width) * length / c_b,
                                                            f_r_cell * a / c_b), 0)
    c_riv = np.where(s["land"], cover(c_riv, 0), f4(0)) * f4(1 / pf["riverres"])

    # drain conductance: linear reservoir, scaled by the water fraction in lakes
    c_drn = alpha * sy * a * np.where(lake, frac_wat, f4(1))
    c_drn = np.where(s["land"], cover(c_drn, 0), f4(0))

    return s, {
        "top": dem, "bot_up": bot_up, "bot_lo": bot_lo, "k_up": k_up, "k_lo": k_lo,
        "k33_up": f4(0.5) * kv * s["F"], "k33_lo": k33_lo,
        "sto_up": sto(sy), "sto_lo": sto(np.where(confined, f4(0.003), sy)),
        "c_riv": c_riv, "c_drn": c_drn,
        # drain elevation: the land surface, never above the top
        "drn_up": np.maximum(dem, bot_up), "drn_lo": np.maximum(dem, bot_lo)}


def forced(s, q, r, abst):
    """Fields driven by discharge q (m3/s), recharge r and abstraction abst
    (m/d); convert.md 4.6, 4.7, 4.9."""
    dem, width = s["dem"], s["width"]
    r = np.maximum(f4(0), cover(r, 0))
    rch = cover(r * s["F"], 0)
    rch[np.abs(rch) < f4(1e-20)] = 0

    # river stage from discharge (Manning), overbank water spread over the cell
    q = np.maximum(f4(0), cover(q, 0))
    grad = np.where(s["land"], np.maximum(f4(5e-5), cover(s["gradient"], 5e-5)), np.nan)
    z_fpl, depth = cover(s["z_fpl"], 0), cover(s["depth"], 0)
    with np.errstate(divide="ignore", invalid="ignore"):
        z_r = s["z_rb"] + width ** f4(-0.6) * q ** f4(0.6) * grad ** f4(-0.3) * f4(0.04) ** f4(0.6)
        above = np.maximum(f4(0), z_r - z_fpl) * depth * width / s["area"]
    z_r = np.where(z_r > z_fpl, z_fpl + above, z_r)
    f_lr, f_r, rbot = s["f_lr"], s["f_r"], mm(s["rbot0"])   # rounded twice, as the old code
    stage = np.maximum(mm(dem * f_lr + cover(z_r, dem) * f_r), rbot)
    rbot = f_lr * rbot + f_r * np.where(width >= 10, rbot, stage)       # no infiltration below 10 m
    rbot = mm(cover(rbot, dem))
    stage = np.maximum(mm(cover(stage, dem)), rbot)
    # never above the land surface: the stiff river bed would hold heads over the top
    rbot, stage = np.minimum(rbot, dem), np.minimum(stage, dem)

    # abstraction: lower layer in productive aquifers, else upper up to recharge, rest by transmissivity
    abst = np.maximum(f4(0), cover(abst, 0))
    q_lo = np.where(s["ksat"] * s["D_aq"] > 50, abst, f4(0))
    rest = np.maximum(f4(0), abst - q_lo)
    q_up = np.minimum(r, rest)
    rest = np.maximum(f4(0), rest - q_up)
    t = s["T_lo"] + s["T_up"]
    with np.errstate(divide="ignore", invalid="ignore"):
        q_lo = q_lo + rest * cover(np.where(t > 0, s["T_lo"] / t, f4(0)), 0)
    q_up = np.maximum(f4(0), abst - q_lo)

    return {"rch": rch, "stage": stage, "rbot": rbot,
            "wel_up": -q_up * s["area"], "wel_lo": -q_lo * s["area"]}


def window():
    """0-based row and column slices of the window."""
    r0, r1, c0, c1 = C["window"]
    return slice(r0 - 1, r1), slice(c0 - 1, c1)


def forcing(name, t, b0, b1):
    """Window rows [b0, b1) of forcing month t."""
    rows, cols = window()
    v = var(C["inputs"][name])
    return as_f4(v[t, rows.start + b0:rows.start + b1, cols], v._FillValue)


def chunks(a, t, b0):
    """Compressed (shuffle + deflate 1) chunks of window rows [b0, b0+CHUNK)."""
    nodata = f4(C["nodata"])
    a = np.where(np.isnan(a), nodata, a).astype("<f4")
    out = []
    for c in range(0, a.shape[1], CHUNK):
        blk = np.full((CHUNK, CHUNK), nodata, "<f4")   # edge chunks are padded
        part = a[:, c:c + CHUNK]
        blk[:part.shape[0], :part.shape[1]] = part
        off = (b0, c) if t is None else (t, b0, c)
        out.append((off, zlib.compress(blk.view("u1").reshape(-1, 4).T.tobytes(), 1)))
    return out


def unit_ss(b0):
    b1 = min(b0 + CHUNK, C["window_rows"])
    s, fields = static(b0, b1)
    q = np.zeros((b1 - b0, C["window_cols"]), "f8")
    r = np.zeros_like(q)
    for t in range(len(DAYS)):
        q += cover(forcing("discharge", t, b0, b1), 0) * DAYS[t]
        r += cover(forcing("recharge", t, b0, b1), 0)
    q, r = f4(q / DAYS.sum()), f4(r / DAYS.sum())
    fields |= forced(s, q, r, np.zeros_like(q))
    return [(k, chunks(fields[f], None, b0)) for k, f in (STATIC_KEYS | FORCED_KEYS).items()]


def unit_tr(args):
    i, b0 = args
    t = C["months"][i]
    b1 = min(b0 + CHUNK, C["window_rows"])
    s, _ = static(b0, b1)
    fields = forced(s, forcing("discharge", t, b0, b1),
                    forcing("recharge", t, b0, b1) / f4(DAYS[i]),
                    forcing("abstraction", t, b0, b1) / f4(DAYS[i]))
    return [(k, chunks(fields[f], i, b0)) for k, f in FORCED_KEYS.items()]


def skeleton(path, times=None):
    """The file globgm_raster.write_nc writes, without the data."""
    g, (rows, cols) = C["grid"], window()
    d = g["cellsize"]
    ymax = g["ymin"] + g["nrow"] * d - rows.start * d
    xmin = g["xmin"] + cols.start * d
    nrow, ncol = C["window_rows"], C["window_cols"]
    with netCDF4.Dataset(path, "w", format="NETCDF4") as ds:
        ds.createDimension("lat", nrow)
        ds.createDimension("lon", ncol)
        vlat = ds.createVariable("lat", "f8", ("lat",))
        vlon = ds.createVariable("lon", "f8", ("lon",))
        vlat.units, vlon.units = "degrees_north", "degrees_east"
        vlat[:] = ymax - (np.arange(nrow) + 0.5) * d
        vlon[:] = xmin + (np.arange(ncol) + 0.5) * d
        dims, chunk = ("lat", "lon"), (CHUNK, CHUNK)
        if times is not None:
            ds.createDimension("time", len(times[0]))
            vt = ds.createVariable("time", "f8", ("time",))
            vt.units, vt.calendar = times[1], "standard"
            vt[:] = times[0]
            dims, chunk = ("time",) + dims, (1,) + chunk
        ds.createVariable("data", "<f4", dims, zlib=True, complevel=1, shuffle=True,
                          chunksizes=chunk, fill_value=f4(C["nodata"]))
        for k, v in (("xmin", xmin), ("ymin", ymax - nrow * d), ("xmax", xmin + ncol * d),
                     ("ymax", ymax), ("dx", d), ("dy", d)):
            ds.setncattr(k, np.float64(v))
        ds.setncattr("nrow", np.int32(nrow))
        ds.setncattr("ncol", np.int32(ncol))
        ds.Conventions = "CF-1.8"
        ds.source = "globgm_raster.write_nc"


def write(out, names, fn, work, times=None):
    for n in names:
        skeleton(out / f"{n}.nc", times)
    files = {n: h5py.File(out / f"{n}.nc", "r+") for n in names}
    dsets = {n: f["data"] for n, f in files.items()}
    n = min(48, len(os.sched_getaffinity(0)), len(work))
    with multiprocessing.get_context("fork").Pool(n) as p:
        i = 0
        # batches bound the finished units waiting here to be written
        for b in range(0, len(work), 2 * n):
            for res in p.imap_unordered(fn, work[b:b + 2 * n]):
                for key, chs in res:
                    for off, data in chs:
                        dsets[C["files"][key]].id.write_direct_chunk(off, data, filter_mask=0)
                i += 1
                if i % 50 == 0 or i == len(work):
                    print(f"{datetime.datetime.now():%H:%M:%S} {out.name}: {i} out of {len(work)} units",
                          flush=True)
    for f in files.values():
        f.close()


def main(cfg_path, out_dir):
    global DAYS
    C.update(json.loads(Path(cfg_path).read_text()))
    rows, cols = window()
    C["window_rows"], C["window_cols"] = rows.stop - rows.start, cols.stop - cols.start
    v = var(C["inputs"]["discharge"], "time")
    tv, tu = v[:].astype("f8"), v.units
    dates = [(d.year, d.month) for d in netCDF4.num2date(tv, tu)]
    for k in ("recharge", "abstraction"):
        tk = var(C["inputs"][k], "time")
        if [(d.year, d.month) for d in netCDF4.num2date(tk[:], tk.units)] != dates:
            raise ValueError(f"{C['inputs'][k]}: months differ from {C['inputs']['discharge']}")
    days = np.array([calendar.monthrange(*d)[1] for d in dates], "f8")
    y, mo = map(int, C["start"].split("-"))
    want = [(y + (mo - 1 + i) // 12, (mo - 1 + i) % 12 + 1) for i in range(C["nper"])]
    if "transient" in C["phases"] and not set(want) <= set(dates):
        raise ValueError(f"[time] months {want[0]}..{want[-1]} are not all in the forcing "
                         f"({dates[0]}..{dates[-1]})")

    for k, (name, vn) in INPUTS.items():
        LOADED[k] = read(var(C["inputs"][name], vn), rows, cols)
        print(f"loaded {k}", flush=True)
    for ds in OPEN.values():
        ds.close()
    OPEN.clear()

    out = Path(out_dir)
    bands = list(range(0, C["window_rows"], CHUNK))
    DAYS = days
    (out / "steady-state").mkdir(parents=True, exist_ok=True)
    write(out / "steady-state", [C["files"][k] for k in STATIC_KEYS | FORCED_KEYS], unit_ss, bands)
    if "transient" in C["phases"]:
        C["months"] = [dates.index(d) for d in want]
        DAYS = days[C["months"]]
        tr = out / "transient"
        tr.mkdir(parents=True, exist_ok=True)
        for k in STATIC_KEYS:
            link = tr / f"{C['files'][k]}.nc"
            link.unlink(missing_ok=True)
            os.link(out / "steady-state" / link.name, link)
        write(tr, [C["files"][k] for k in FORCED_KEYS], unit_tr,
              [(i, b) for i in range(C["nper"]) for b in bands], (tv[C["months"]], tu))


if __name__ == "__main__":
    main(*sys.argv[1:3])
