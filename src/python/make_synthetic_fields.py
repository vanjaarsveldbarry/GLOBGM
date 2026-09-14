"""Stand-in for the PCR-GLOBWB fields `mf6ggm` reads, over the datamap window,
in the "Forcing interface" layout of design.md: one NetCDF per field, monthly
fields on a `time` axis. Values are placeholders; only the layout, the domain
and the nodata pattern are meant.

Needs nothing from stage 1. `mf6ggm` reads top/bot for every node, the sea
boundary cells datamap adds included, and errors on nodata there; which sea
cells those are is datamap's decision, so geometry, properties and initial
heads are valid on every cell of the window. River, drain and well fields
cover land only (nodata on sea, which the `ib = 2` reads skip anyway), and the
river network is nodata off-channel because that nodata is what selects the
RIV cells. Land is where the ldd holds a direction, PCR-GLOBWB's own domain.

Usage: make_synthetic_fields.py <synthetic.json> <out_dir>
with synthetic.json written by globgm_config.py from the [synthetic] table.
"""
import json
import sys
from datetime import datetime
from pathlib import Path

import netCDF4
import numpy as np

from globgm_raster import Header, write_nc

TIME_UNITS = "days since 1901-01-01"

# ldd keypad code -> (drow, dcol); 5 is a pit
LDD = {1: (1, -1), 2: (1, 0), 3: (1, 1), 4: (0, -1), 6: (0, 1), 7: (-1, -1), 8: (-1, 0), 9: (-1, 1)}


def read_window(path, name, r0, r1, c0, c1):
    d = netCDF4.Dataset(path)
    v = d[name]
    v.set_auto_maskandscale(False)
    if d["lat"][0] < d["lat"][-1]:
        raise ValueError(f"{path}: expected row 0 = north")
    return np.array(v[r0:r1, c0:c1]), v.getncattr("_FillValue")


def flow_accumulation(ldd):
    """Upstream cell count within the window; flow leaving the window is dropped."""
    nrow, ncol = ldd.shape
    idx = np.arange(nrow * ncol).reshape(nrow, ncol)
    down = np.full(nrow * ncol, -1, np.int64)
    for code, (dr, dc) in LDD.items():
        r, c = np.nonzero(ldd == code)
        tr, tc = r + dr, c + dc
        ok = (tr >= 0) & (tr < nrow) & (tc >= 0) & (tc < ncol)
        down[idx[r[ok], c[ok]]] = idx[tr[ok], tc[ok]]
    valid = (ldd >= 1) & (ldd <= 9)
    acc = valid.ravel().astype(np.int64)
    indeg = np.bincount(down[down >= 0], minlength=down.size)
    front = np.nonzero(valid.ravel() & (indeg == 0))[0]
    while front.size:
        front = front[down[front] >= 0]
        tgt = down[front]
        np.add.at(acc, tgt, acc[front])
        np.subtract.at(indeg, tgt, 1)
        front = np.unique(tgt[indeg[tgt] == 0])
    return acc.reshape(nrow, ncol)


def main(cfg, out_dir):
    gir0, gir1, gic0, gic1 = cfg["window"]
    nper, start = cfg["nper"], cfg["start"]
    dem_nc, conf_nc, ldd_nc = cfg["dem"], cfg["confining"], cfg["ldd"]
    NODATA, THICK_L2, THR = cfg["nodata"], cfg["thickness_l2"], cfg["layer_threshold"]
    K_L1, K_L2, STO_L1, STO_L2 = cfg["k_l1"], cfg["k_l2"], cfg["sto_l1"], cfg["sto_l2"]
    RCH, RIV_MIN_ACC = cfg["recharge"], cfg["river_min_accumulation"]
    RIV_COND, DRN_COND = cfg["river_conductance"], cfg["drain_conductance"]
    WEL_Q_L1, WEL_Q_L2, N_WELLS = cfg["well_q_l1"], cfg["well_q_l2"], cfg["n_wells"]
    g = cfg["grid"]
    dx, x0, y1 = g["cellsize"], g["xmin"], g["ymin"] + g["nrow"] * g["cellsize"]
    nrow, ncol = gir1 - gir0 + 1, gic1 - gic0 + 1
    hdr = Header(ncol=ncol, nrow=nrow, xmin=x0 + (gic0 - 1) * dx, ymin=y1 - gir1 * dx,
                 xmax=x0 + gic1 * dx, ymax=y1 - (gir0 - 1) * dx, dx=dx, dy=dx,
                 nodata=NODATA, dtype="<f4")

    win = (gir0 - 1, gir1, gic0 - 1, gic1)
    dem, dem_fill = read_window(dem_nc, "dem_average", *win)
    conf, conf_fill = read_window(conf_nc, "thickness_deklaag", *win)
    ldd, _ = read_window(ldd_nc, "Band1", *win)
    dem[~np.isfinite(dem) | (dem == dem_fill)] = 0.0
    conf[~np.isfinite(conf) | (conf == conf_fill)] = 0.0
    dem = dem.astype("<f4")
    conf = conf.astype("<f4")
    t2 = np.maximum(np.float32(0.1), dem - (dem - conf))
    d_top_2 = dem - (dem - t2)              # as make_d_top_2.py, so nlay agrees
    land = (ldd >= 1) & (ldd <= 9)
    two = d_top_2 > THR
    every = np.ones((nrow, ncol), bool)

    top = dem
    bot1 = top - d_top_2
    bot2 = bot1 - np.float32(THICK_L2)
    riv = land & (flow_accumulation(ldd) >= RIV_MIN_ACC)
    well = np.zeros((nrow, ncol), bool)
    cand = np.nonzero(land & two)
    pick = np.linspace(0, cand[0].size - 1, N_WELLS).astype(int)
    well[cand[0][pick], cand[1][pick]] = True

    def on(mask, values):
        a = np.full((nrow, ncol), NODATA, "<f4")
        a[mask] = np.broadcast_to(np.asarray(values, "<f4"), (nrow, ncol))[mask]
        return a

    static = {
        "TOP": on(every, top),
        "BOT_L1": on(every, bot1),
        "BOT_L2": on(every, bot2),
        "K_L1": on(every, K_L1),
        "K_L2": on(every, K_L2),
        "K_33_L1": on(every, K_L1 / 10),
        "K_33_L2": on(every, K_L2 / 10),
        "PRIM_STO_L1": on(every, STO_L1),
        "PRIM_STO_L2": on(every, STO_L2),
        "STRT_L1": on(every, top),
        "STRT_L2": on(every, top),
        "DRN_COND_L1:2": on(land, DRN_COND),
    }

    def monthly(m):                          # m = 0-based month since start
        season = np.float32(np.cos(2 * np.pi * ((int(start[4:]) - 1 + m) % 12) / 12))
        return {
            "RECHARGE": on(land, RCH * (1 + 0.5 * season)),
            "RIV_STAGE_L1": on(riv, top - 1 + 0.5 * season),
            "RIV_RBOT_L1": on(riv, top - 3),
            "RIV_COND_L1": on(riv, RIV_COND),
            "DRN_ELEV_L1": on(land, top),
            "DRN_ELEV_L2": on(land, top),
            "WEL_Q_L1": on(well, WEL_Q_L1),
            "WEL_Q_L2": on(well, WEL_Q_L2),
        }

    files = cfg["files"]
    unknown = set(files) - set(static) - set(monthly(0))
    if unknown:
        raise ValueError(f"synthetic fields exist only for the twenty-field contract; cannot make {sorted(unknown)}")

    ss = Path(out_dir) / "steady-state"
    tr = Path(out_dir) / "transient"
    ss.mkdir(parents=True, exist_ok=True)
    tr.mkdir(parents=True, exist_ok=True)
    for key, a in static.items():
        if key in files:
            write_nc(ss / f"{files[key]}.nc", hdr, a)
            write_nc(tr / f"{files[key]}.nc", hdr, a)

    y, mo = int(start[:4]), int(start[4:])
    months = [(y + (mo - 1 + m) // 12, (mo - 1 + m) % 12 + 1) for m in range(nper)]
    ends = [netCDF4.date2num(datetime(yy + mm // 12, mm % 12 + 1, 1), TIME_UNITS) - 1
            for yy, mm in months]           # month end, as PCR-GLOBWB stamps it
    stack = {k: np.empty((nper, nrow, ncol), "<f4") for k in monthly(0) if k in files}
    for m in range(nper):
        for k, a in monthly(m).items():
            if k in stack:
                stack[k][m] = a
    for k, a in stack.items():
        write_nc(tr / f"{files[k]}.nc", hdr, a, times=(ends, TIME_UNITS))
        mean = a.mean(axis=0, dtype="<f8").astype("<f4")
        mean[a[0] == NODATA] = NODATA
        write_nc(ss / f"{files[k]}.nc", hdr, mean)

    print(f"{nrow * ncol} cells, {land.sum()} land, {riv.sum()} river cells, "
          f"{well.sum()} wells; {nper} months from {start} into {out_dir}")


if __name__ == "__main__":
    main(json.loads(Path(sys.argv[1]).read_text()), sys.argv[2])
