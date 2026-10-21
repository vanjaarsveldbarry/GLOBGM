"""Check that two mf6ggm output trees are the same model input.

Every file must exist in both. Text files are compared line by line; an
``OPEN/CLOSE <bin> (BINARY) p0 p1`` line is compared with its byte range
resolved and the payload sliced out of the named binary, so the packed
per-model ``models/run_input/m*/m*.bin`` may be laid out differently between
the trees and is never compared whole. A ``.nc`` raster is compared by
content: dimensions, every variable's values and attributes, the global
attributes (HDF5 lays the chunks out in writing order, so the bytes may
differ between writers). Any other file, nodmap.bin included, must be
byte-identical.

    compare_mf6ggm_tree.py <reference tree> <candidate tree>
"""
import mmap
import re
import sys
from pathlib import Path

import netCDF4
import numpy as np

OPEN_CLOSE = re.compile(r"^(\s*OPEN/CLOSE\s+)(\S+)(\s+\(BINARY\)\s+)(\d+)\s+(\d+)\s*$")
CWD = Path("solutions/run_input")


class Tree:
    def __init__(self, root):
        self.root = Path(root)
        self.bins = {}

    def files(self):
        return {
            p.relative_to(self.root)
            for p in self.root.rglob("*")
            if p.is_file() and p.relative_to(self.root).parts[0] != "log"
        }

    def payload(self, ref, p0, p1):
        path = (self.root / CWD / ref).resolve()
        if path not in self.bins:
            fh = open(path, "rb")
            self.bins[path] = mmap.mmap(fh.fileno(), 0, access=mmap.ACCESS_READ)
        return self.bins[path][p0 - 1:p1 - 1]


def is_text(rel):
    return rel.suffix not in {".bin", ".nc"}


def is_packed_bin(rel):
    return rel.suffix == ".bin" and rel.parts[:2] == ("models", "run_input")


def compare_text(ta, tb, rel):
    la = (ta.root / rel).read_text().splitlines()
    lb = (tb.root / rel).read_text().splitlines()
    if len(la) != len(lb):
        return [f"{rel}: {len(la)} vs {len(lb)} lines"]
    bad = []
    for i, (x, y) in enumerate(zip(la, lb), 1):
        mx, my = OPEN_CLOSE.match(x), OPEN_CLOSE.match(y)
        if mx and my:
            if mx.group(1, 2, 3) != my.group(1, 2, 3):
                bad.append(f"{rel}:{i}: {x!r} vs {y!r}")
                continue
            px = ta.payload(mx.group(2), int(mx.group(4)), int(mx.group(5)))
            py = tb.payload(my.group(2), int(my.group(4)), int(my.group(5)))
            if px != py:
                bad.append(f"{rel}:{i}: payload differs ({len(px)} vs {len(py)} bytes)")
        elif x != y:
            bad.append(f"{rel}:{i}: {x!r} vs {y!r}")
    return bad


def compare_nc(a, b, rel):
    bad = []
    with netCDF4.Dataset(a) as da, netCDF4.Dataset(b) as db:
        for d in set(da.dimensions) | set(db.dimensions):
            if d not in da.dimensions or d not in db.dimensions or len(da.dimensions[d]) != len(db.dimensions[d]):
                bad.append(f"{rel}: dimension {d} differs")
        for k in set(da.ncattrs()) | set(db.ncattrs()):
            if k not in da.ncattrs() or k not in db.ncattrs() or np.any(da.getncattr(k) != db.getncattr(k)):
                bad.append(f"{rel}: global attribute {k} differs")
        for v in set(da.variables) | set(db.variables):
            if v not in da.variables or v not in db.variables:
                bad.append(f"{rel}: variable {v} missing")
                continue
            va, vb = da.variables[v], db.variables[v]
            va.set_auto_mask(False); vb.set_auto_mask(False)
            if va.dtype != vb.dtype or va.dimensions != vb.dimensions:
                bad.append(f"{rel}: variable {v} type or shape differs")
                continue
            for k in set(va.ncattrs()) | set(vb.ncattrs()):
                if k not in va.ncattrs() or k not in vb.ncattrs() or np.any(va.getncattr(k) != vb.getncattr(k)):
                    bad.append(f"{rel}: attribute {v}:{k} differs")
            if not np.array_equal(va[...], vb[...]):
                bad.append(f"{rel}: variable {v} values differ")
    return bad


def main(ref, cand):
    ta, tb = Tree(ref), Tree(cand)
    fa, fb = ta.files(), tb.files()
    bad = [f"only in reference: {p}" for p in sorted(fa - fb)]
    bad += [f"only in candidate: {p}" for p in sorted(fb - fa)]
    checked = 0
    for rel in sorted(fa & fb):
        if is_packed_bin(rel):
            continue
        if is_text(rel):
            bad += compare_text(ta, tb, rel)
        elif rel.suffix == ".nc":
            bad += compare_nc(ta.root / rel, tb.root / rel, rel)
        elif (ta.root / rel).read_bytes() != (tb.root / rel).read_bytes():
            bad.append(f"{rel}: bytes differ")
        checked += 1
    for line in bad:
        print(line)
    print(f"{checked} files checked, {len(bad)} differences")
    return 1 if bad else 0


if __name__ == "__main__":
    ref, cand = sys.argv[1:]
    sys.exit(main(ref, cand))
