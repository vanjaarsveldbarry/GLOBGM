"""The two GLOBGM configuration files, turned into what the tools read.

  globgm_config.py run <globgm.toml> <output>
      writes the mf6ggm / mf6ggmpost .inp files, fields.json and
      params.json (read by main.nf) into <output>/config and empties the
      rest of <output>, the published view Nextflow refills from its cache
  globgm_config.py build-env <build.toml>
      prints KEY='value' lines for `eval` in src/scripts/build_*.sh

Paths in either file are relative to the file's own directory and come out
absolute in params.json and the build env; main.nf calls `run` with the
output root from nextflow.config. fields.json names the inputs by absolute
path; the .inp files instead name files relative to the Nextflow task directory that runs the tool,
in the layout stages.nf stages them (see TREE_UP below), so that they are the
same on every machine and change only with the configuration. Every generated
file is a build artefact: edit the TOML instead.
"""
import json
import math
import shlex
import shutil
import sys
import tomllib
from pathlib import Path

PHASES = ("steady-state", "spin-up", "transient")
RUN = {"steady-state": "ss", "spin-up": "spu", "transient": "tr"}
HDS = {"steady-state": "ss.hds", "spin-up": "tr.spu.hds", "transient": "tr.hds"}

IMS_KEYS = (
    "OUTER_HCLOSE", "OUTER_MAXIMUM", "UNDER_RELAXATION", "UNDER_RELAXATION_THETA",
    "UNDER_RELAXATION_KAPPA", "UNDER_RELAXATION_GAMMA", "UNDER_RELAXATION_MOMENTUM",
    "BACKTRACKING_NUMBER", "BACKTRACKING_TOLERANCE", "BACKTRACKING_REDUCTION_FACTOR",
    "BACKTRACKING_RESIDUAL_LIMIT", "INNER_MAXIMUM", "INNER_HCLOSE", "INNER_RCLOSE",
    "LINEAR_ACCELERATION", "RELAXATION_FACTOR", "PRECONDITIONER_LEVELS",
    "PRECONDITIONER_DROP_TOLERANCE", "NUMBER_ORTHOGONALIZATIONS", "SCALING_METHOD",
    "REORDERING_METHOD",
)
COMPLEXITY = ("SIMPLE", "MODERATE", "COMPLEX")
PRINT_OPTION = ("NONE", "SUMMARY", "ALL", "ALLITER")
RCLOSE_OPTION = ("", "STRICT", "L2NORM_RCLOSE", "RELATIVE_RCLOSE")
PACKAGES = ("sto", "riv", "wel", "chd", "chd2")
MF6GGM_WRITE = ("all", "solutions")
# [inputs] files; make_fields.py reads all but the first four from fields.json
INPUT_KEYS = ("ldd", "dem", "confining", "lakes", "cell_area", "channel", "thickness",
              "ksat", "specific_yield", "recession", "unconsolidated", "consolidated", "carbonate",
              "recharge", "abstraction", "discharge")
CALIBRATION = ("khuncon", "khcon", "khcar", "kvconf", "riverres")
# the [fields.files] keys make_fields.py writes
DERIVED_KEYS = ("TOP", "BOT_L1", "BOT_L2", "K_L1", "K_L2", "K_33_L1", "K_33_L2", "PRIM_STO_L1",
                "PRIM_STO_L2", "STRT_L1", "STRT_L2", "RECHARGE", "RIV_STAGE_L1", "RIV_RBOT_L1",
                "RIV_COND_L1", "DRN_ELEV_L1", "DRN_ELEV_L2", "DRN_COND_L1:2", "WEL_Q_L1", "WEL_Q_L2")

# The mf6ggm field keys (mf6_module.f90 `keys`) the generator appends the
# _P<1>:<nper> range to, after a [fields.files] key's _L<n>[:<m>] layer and
# _S<n> system suffixes. DRN_COND is static data under a periodic key, as
# upstream wrote it.
PERIODIC_FIELDS = ("RECHARGE", "RIV_STAGE", "RIV_COND", "RIV_RBOT", "DRN_ELEV", "DRN_COND", "WEL_Q")


def field_base(key):
    """'DRN_COND_L1:2_S2' -> 'DRN_COND', as mf6ggm's strip_range_suffix does."""
    words = key.split("_")
    while len(words) > 1 and words[-1][:1] in "LS" and words[-1][1:] \
            and all(c in "0123456789:" for c in words[-1][1:]):
        words.pop()
    return "_".join(words)

# What stages.nf puts into the task directory of each process, by name; the
# .inp lines below and the process scripts must agree:
#   datamap/map_glob.*.bin                 map_glob output
#   fields/{steady-state,transient}/*.nc   preprocess_inputs output
#   <phase>/                               the mf6ggm tree of the phase
#   ./                                     mf6ggmpost writes here
# mf6 runs from <phase>/solutions/run_output and reads the starting heads from
# the path mf6ggm copied verbatim into the .ic files, hence TREE_UP on those two.
TREE_UP = Path("../../..")

BUILD_PATHS = {("build", "dir"), ("tools", "bindir"), ("metis", "src"),
               ("metis", "prefix"), ("mf6", "src"), ("mf6", "patch")}


def fail(msg):
    raise ValueError(msg)


def load_run(path):
    cfg = tomllib.loads(path.read_text())
    validate_run(cfg)
    base = path.parent
    run = cfg["run"]
    run["binaries"] = (base / run["binaries"]).resolve()
    for sol in cfg["partition"]["solutions"]:
        if "partition_file" in sol:
            sol["partition_file"] = (base / sol["partition_file"]).resolve()
    cfg["inputs"]["dir"] = (base / cfg["inputs"]["dir"]).resolve()
    i = cfg["inputs"]
    for k in INPUT_KEYS:
        f = i["dir"] / i[k]
        if not f.is_file():
            fail(f"inputs.{k}: {f} does not exist")
    cfg["_file"] = path
    return cfg


def validate_run(cfg):
    run, grid, win, t, p = cfg["run"], cfg["grid"], cfg["window"], cfg["time"], cfg["post"]
    phases = run["phases"]
    if not phases or any(x not in PHASES for x in phases) or len(set(phases)) != len(phases):
        fail(f"run.phases: must be a non-empty ordered subset of {PHASES}")
    if [x for x in PHASES if x in phases] != phases:
        fail(f"run.phases: order must follow {PHASES}")
    if phases[0] != "steady-state":
        fail("run.phases: spin-up and transient need steady-state for their starting heads")
    if run["mf6_mode"] not in ("ser", "par"):
        fail("run.mf6_mode: ser or par")
    if grid["nlay"] != 2:
        fail("grid.nlay: the tools are written for two layers")
    if grid["ncol"] < 1 or grid["nrow"] < 1 or grid["cellsize"] <= 0:
        fail("grid: ncol, nrow and cellsize must be positive")
    xmax, ymax = grid["xmin"] + grid["ncol"] * grid["cellsize"], grid["ymin"] + grid["nrow"] * grid["cellsize"]
    if not grid["ymin"] <= win["south"] < win["north"] <= ymax:
        fail(f"window: must satisfy {grid['ymin']} <= south < north <= {ymax}")
    if not grid["xmin"] <= win["west"] < win["east"] <= xmax:
        fail(f"window: must satisfy {grid['xmin']} <= west < east <= {xmax}")
    if cfg["subbasins"]["area"] <= 0:
        fail("subbasins.area: positive, km2")
    dm = cfg["datamap"]
    if dm["layer_threshold"] <= 0:
        fail("datamap.layer_threshold: positive, m")
    if dm["max_neighbours"] < 1:
        fail("datamap.max_neighbours: at least 1")
    s = t["start"]
    if len(s) != 7 or s[4] != "-" or not (s[:4] + s[5:]).isdigit() or not 1 <= int(s[5:]) <= 12:
        fail("time.start: YYYY-MM")
    if t["months"] < 1:
        fail("time.months: at least 1")
    if not 1 <= t["start_day"] <= 28:
        fail("time.start_day: 1 to 28")
    if t["time_units"] not in ("UNKNOWN", "SECONDS", "MINUTES", "HOURS", "DAYS", "YEARS"):
        fail("time.time_units: a MODFLOW 6 TDIS TIME_UNITS value")
    if len(phases) > 1:
        if t["spinup_months"] < 1:
            fail("time.spinup_months: at least 1 for a spin-up or transient")
        if t["months"] < t["spinup_months"]:
            fail("time.months: the spin-up cycles spinup_months months of forcing, "
                 "so months must be at least that (design.md, Known traps)")
    pt = cfg["partition"]
    sols = pt["solutions"]
    if not sols:
        fail("partition.solutions: empty")
    for i, sol in enumerate(sols, 1):
        if "partition_file" in sol:
            if set(sol) - {"active", "partition_file"}:
                fail(f"partition.solutions[{i}]: partition_file replaces submodels and mpi_ranks")
        elif sol["submodels"] < 1 or not 1 <= sol["mpi_ranks"] <= sol["submodels"]:
            fail(f"partition.solutions[{i}]: need submodels >= 1 and 1 <= mpi_ranks <= submodels")
    if pt["single_model_solutions"] < 0:
        fail("partition.single_model_solutions: 0 or more")
    if pt["metis_imbalance"] < 1.0:
        fail("partition.metis_imbalance: at least 1.0")
    w = pt["mf6ggm_write"]
    if not (w in MF6GGM_WRITE or (isinstance(w, list) and len(w) == 2 and 1 <= w[0] <= w[1])):
        fail(f"partition.mf6ggm_write: one of {MF6GGM_WRITE} or [first model id, last model id]")
    sv = cfg["solver"]
    if sv["complexity"] not in COMPLEXITY:
        fail(f"solver.complexity: one of {COMPLEXITY}")
    if sv["print_option"] not in PRINT_OPTION:
        fail(f"solver.print_option: one of {PRINT_OPTION}")
    if sv["rclose_option"] not in RCLOSE_OPTION:
        fail(f"solver.rclose_option: one of {RCLOSE_OPTION}")
    for k in sv["ims"]:
        if k not in IMS_KEYS:
            fail(f"solver.ims.{k}: not an IMS keyword mf6ggm knows ({', '.join(IMS_KEYS)})")
    m = cfg["model"]
    if m["icelltype"] not in (0, 1):
        fail("model.icelltype: 0 or 1")
    if m["nstp_fac"] < 1:
        fail("model.nstp_fac: at least 1")
    if tuple(m["packages"]) != PACKAGES:
        fail(f"model.packages: exactly the keys {PACKAGES}")
    if m["drain_systems"] < 1 or m["river_systems"] < 1:
        fail("model.drain_systems, model.river_systems: at least 1")
    files = cfg["fields"]["files"]
    if set(files) != set(DERIVED_KEYS):
        fail(f"fields.files: exactly the keys {', '.join(DERIVED_KEYS)}")
    cal = cfg["fields"]["calibration"]
    if set(cal) != set(CALIBRATION) or any(v <= 0 for v in cal.values()):
        fail(f"fields.calibration: positive values for exactly {', '.join(CALIBRATION)}")
    for k in INPUT_KEYS:
        if k not in cfg["inputs"]:
            fail(f"inputs.{k}: missing")
    for table in ("multiply", "add"):
        for k in cfg["fields"][table]:
            if k not in files:
                fail(f"fields.{table}.{k}: not a key of fields.files")
    if any(x not in phases for x in p["phases"]) or "spin-up" in p["phases"]:
        fail("post.phases: a subset of run.phases without spin-up")
    if not p["outputs"] or any(x not in ("wtd", "hds") for x in p["outputs"]):
        fail("post.outputs: non-empty subset of wtd, hds")
    if not 0 <= p["layers"][0] <= p["layers"][1] <= grid["nlay"]:
        fail(f"post.layers: 0 <= min <= max <= {grid['nlay']}")


def fortran_e(x):
    m, e = f"{x:.12E}".split("E")
    return f"{m}E{int(e):+04d}"


def grid_line(cfg):
    g = cfg["grid"]
    return f"{g['ncol']} {g['nrow']} {g['nlay']} {g['xmin']:g} {g['ymin']:g} {fortran_e(g['cellsize'])}"


def fields_dir(phase):
    """The spin-up reads the transient fields."""
    return Path("fields") / ("steady-state" if phase == "steady-state" else "transient")


def heads_dir(phase):
    return f"{TREE_UP / phase}/models/run_output_bin/"


def start_yyyymm(cfg):
    return cfg["time"]["start"].replace("-", "")


def solution_line(cfg, sol):
    active = int(sol.get("active", True))
    if "partition_file" in sol:
        return f"{active} -1\n{sol['partition_file']}"
    return f"{active} {sol['submodels']} {sol['mpi_ranks']} {int(cfg['partition']['write_model_ids'])}"


def mf6ggm_args(cfg):
    w = cfg["partition"]["mf6ggm_write"]
    return "" if w == "all" else "0" if w == "solutions" else f"{w[0]} {w[1]}"


def end_yyyymm(cfg):
    y, m = int(cfg["time"]["start"][:4]), int(cfg["time"]["start"][5:])
    n = m - 1 + cfg["time"]["months"] - 1
    return f"{y + n // 12:04d}{n % 12 + 1:02d}"


def write_text(path, text):
    """Leave an unchanged file alone so Nextflow's mtime-based cache holds."""
    if not path.is_file() or path.read_text() != text:
        path.write_text(text)
    return path


def write(path, lines):
    return write_text(path, "\n".join(str(x) for x in lines) + "\n")


def write_mf6ggm_inp(cfg, phase, out):
    run = RUN[phase]
    pt = cfg["partition"]
    sols = pt["solutions"]
    return write(out / f"mf6ggm_{run}.inp", [
        grid_line(cfg),
        f"{phase}/",
        "datamap/map_glob",
        f"{-len(sols) if pt['last_takes_remaining'] else len(sols)} {pt['single_model_solutions']}",
        *(solution_line(cfg, s) for s in sols),
        f"mf6_mod_{run}.inp",
        pt["metis_imbalance"],
    ])


def write_mf6_mod_inp(cfg, phase, out):
    run = RUN[phase]
    t, sv, m = cfg["time"], cfg["solver"], cfg["model"]
    nper = 1 if run == "ss" else t["months"]
    lines = [f"# generated from {cfg['_file'].name}; edit that file, not this one", f"NPER {nper}"]
    if run != "ss":
        lines += [f"NMONTH_SPINUP {t['spinup_months']}", f"SS_STRT_DIR {heads_dir('steady-state')}"]
    if run == "tr" and "spin-up" in cfg["run"]["phases"]:
        lines.append(f"SPU_STRT_DIR {heads_dir('spin-up')}")
    lines += [f"STARTDATE {start_yyyymm(cfg)}{t['start_day']:02d}", f"TIME_UNITS {t['time_units']}", ""]
    per = "_P1" if nper == 1 else f"_P1:{nper}"
    fields = fields_dir(phase)
    mult, add = cfg["fields"]["multiply"], cfg["fields"]["add"]
    for key, name in cfg["fields"]["files"].items():
        line = f"{key}{per if field_base(key) in PERIODIC_FIELDS else ''} {fields / name}.nc"
        # word 3 is upstream's DIST slot; mf6_raw_init reads the operator from word 4
        if key in mult or key in add:
            line += " -"
        if key in mult:
            line += f" * {mult[key]}"
        if key in add:
            line += f" + {add[key]}"
        lines.append(line)
    lines += ["", "# solver settings"]
    lines += [f"{k} {v}" for k, v in sv["ims"].items()]
    lines += [f"COMPLEXITY {sv['complexity']}", f"PRINT_OPTION {sv['print_option']}"]
    if sv["rclose_option"]:
        lines.append(f"RCLOSE_OPTION {sv['rclose_option']}")
    lines += [f"NEWTON {int(sv['newton'])}", f"EXCHANGE_NEWTON {int(sv['exchange_newton'])}"]
    lines += ["", "# model", f"ICELLTYPE {m['icelltype']}", f"FORCE_SEA {int(m['force_sea'])}",
              f"NSTP_FAC {m['nstp_fac']}", f"NDRNSYS {m['drain_systems']}", f"NRIVSYS {m['river_systems']}"]
    lines += [f"ACT_{k.upper()} {int(v)}" for k, v in m["packages"].items()]
    return write(out / f"mf6_mod_{run}.inp", lines)


# mf6ggmpost is serial, so each (solution, output) is its own .inp of one job
# and its own Nextflow task.
def post_jobs(cfg):
    return [(isol, o) for isol in range(1, len(cfg["partition"]["solutions"]) + 1)
            for o in cfg["post"]["outputs"]]


def write_mf6ggmpost_inps(cfg, phase, out):
    run = RUN[phase]
    p = cfg["post"]
    beg = start_yyyymm(cfg)
    end = beg if run == "ss" else end_yyyymm(cfg)
    return [write(out / f"mf6ggmpost_{run}.s{isol:02d}_{o}.inp", [
        grid_line(cfg), beg, fields_dir(phase) / f"{cfg['fields']['files']['TOP']}.nc",
        int(p["include_sea"]), cfg["globals"]["nodata"], 1,
        f"{phase}/ s {isol} .{run}.hds {int(o == 'wtd')} {p['layers'][0]} {p['layers'][1]} "
        f"{beg} {end} nc ./ {o}.{run}.",
    ]) for isol, o in post_jobs(cfg)]


def window(cfg):
    """1-based inclusive [r0, r1, c0, c1] of the cells enclosing the bounds."""
    g, w = cfg["grid"], cfg["window"]
    ymax = g["ymin"] + g["nrow"] * g["cellsize"]
    # rounding to 1e-6 cell stops a bound on a cell edge (61.0 / (1/120) =
    # 3479.9999...) from pulling in an extra row
    cells = lambda x: round(x / g["cellsize"], 6)
    return [math.floor(cells(ymax - w["north"])) + 1, math.ceil(cells(ymax - w["south"])),
            math.floor(cells(w["west"] - g["xmin"])) + 1, math.ceil(cells(w["east"] - g["xmin"]))]


def write_fields_json(cfg, out):
    i, phases = cfg["inputs"], cfg["run"]["phases"]
    inputs = {k: str(i["dir"] / i[k]) for k in INPUT_KEYS}
    return write_text(out / "fields.json", json.dumps({
        "window": window(cfg),
        "grid": cfg["grid"],
        # spin-up reads the transient fields
        "phases": ["steady-state"] + (["transient"] if len(phases) > 1 else []),
        "start": cfg["time"]["start"],
        "nper": cfg["time"]["months"],
        "files": cfg["fields"]["files"],
        "calibration": cfg["fields"]["calibration"],
        "nodata": cfg["globals"]["nodata"],
        "inputs": inputs,
    }, indent=2) + "\n")


# One sub-map per stages.nf process that takes one, holding exactly the
# values its script uses, so a changed key reruns only the tasks it feeds.
def write_params_json(cfg, out):
    r, i, dm = cfg["run"], cfg["inputs"], cfg["datamap"]
    phases = r["phases"]
    return write_text(out / "params.json", json.dumps({
        "config_dir": str(out),
        "binaries": str(r["binaries"]),
        "phases": phases,
        "post_phases": cfg["post"]["phases"],
        "post_jobs": [f"s{isol:02d}_{o}" for isol, o in post_jobs(cfg)],
        "sim": {ph: RUN[ph] for ph in phases},
        "nam": {"steady-state": "ic_sh0", "spin-up": "spu",
                "transient": "ic_spu" if "spin-up" in phases else "ic_ss"},
        "hds": HDS,
        "inputs_dir": str(i["dir"]),
        "ldd": i["ldd"], "dem": i["dem"], "confining": i["confining"], "lakes": i["lakes"],
        "preprocess_inputs": {"area": cfg["subbasins"]["area"]},
        "map_glob": {
            "window": " ".join(str(x) for x in window(cfg)),
            "sea_boundary": int(dm["sea_boundary"]),
            "layer_threshold": dm["layer_threshold"],
            "max_neighbours": dm["max_neighbours"],
        },
        "mf6_input": {"mf6ggm_args": mf6ggm_args(cfg)},
        "mf6": {"mode": r["mf6_mode"], "mpirun_args": r["mpirun_args"]},
    }, indent=2) + "\n")


# what stages.nf publishes under the output root; work/, binaries/ and logs/ live
# beside them and must survive a regenerate
PRODUCTS = ("datamap", "mf6ggm", "post")


def write_run(cfg, out):
    out.mkdir(parents=True, exist_ok=True)
    written = []
    for phase in cfg["run"]["phases"]:
        written += [write_mf6ggm_inp(cfg, phase, out), write_mf6_mod_inp(cfg, phase, out)]
    for phase in cfg["post"]["phases"]:
        written += write_mf6ggmpost_inps(cfg, phase, out)
    written.append(write_fields_json(cfg, out))
    written.append(write_params_json(cfg, out))
    for stale in set(out.iterdir()) - set(written):
        stale.unlink()
    for name in PRODUCTS:
        if (out.parent / name).exists():
            shutil.rmtree(out.parent / name)
    return sorted(f.name for f in written)


def build_env(path):
    cfg = tomllib.loads(path.read_text())
    base = path.parent
    lines = []
    for section, table in cfg.items():
        for key, value in table.items():
            if (section, key) in BUILD_PATHS:
                value = (base / value).resolve()
            elif isinstance(value, bool):
                value = int(value)
            lines.append(f"{section.upper()}_{key.upper()}={shlex.quote(str(value))}")
    return "\n".join(lines)


def main(argv):
    cmd, path = argv[0], Path(argv[1]).resolve()
    if cmd == "run":
        cfg = load_run(path)
        out = Path(argv[2]).resolve() / "config"
        names = write_run(cfg, out)
        r0, r1, c0, c1 = window(cfg)
        print(f"window: rows {r0}-{r1} cols {c0}-{c1}")
        print(f"{out}: {' '.join(names)}")
    elif cmd == "build-env":
        print(build_env(path))
    else:
        raise SystemExit(__doc__)


if __name__ == "__main__":
    main(sys.argv[1:])
