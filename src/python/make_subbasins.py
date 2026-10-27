"""Sub-basins from the PCR-GLOBWB ldd: the catchment raster datamap reads.

Going downstream, a cell becomes an outlet once the area draining to it that
no upstream outlet has claimed reaches `area` km2; ldd outlets (pits, cells
draining to sea or off the grid) always are. A sub-basin under half of `area`
is then merged into the larger neighbour it shares the longest border with,
which absorbs the many tiny coastal ones.
Lakes (waterBodyIds) are never split: no outlet inside a lake, every cell
where water leaves one is an outlet, and sub-basins sharing a lake are merged.

Usage: make_subbasins.py <ldd.nc> <lakes.nc> <area km2> <out.nc>
"""
import sys

import netCDF4
import numpy as np
from numba import njit, prange

from globgm_raster import Header, write_nc

R = 6371.0072  # km, authalic Earth radius
DR = np.array([0, 1, 1, 1, 0, 0, 0, -1, -1, -1])  # ldd keypad code -> row step (row 0 north)
DC = np.array([0, -1, 0, 1, -1, 0, 1, -1, 0, 1])


@njit(cache=True)
def down(ldd, r, c):
    k = ldd[r, c]
    i, j = r + DR[k], c + DC[k]
    if k == 5 or i < 0 or i >= ldd.shape[0] or j < 0 or j >= ldd.shape[1] or not 1 <= ldd[i, j] <= 9:
        return -1, -1
    return i, j


@njit(parallel=True, cache=True)
def indegree(ldd):
    nrow, ncol = ldd.shape
    indeg = np.zeros((nrow, ncol), np.uint8)
    for r in prange(nrow):
        for c in range(ncol):
            for k in range(1, 10):
                i, j = r - DR[k], c - DC[k]
                if k != 5 and 0 <= i < nrow and 0 <= j < ncol and ldd[i, j] == k:
                    indeg[r, c] += 1
    return indeg


@njit(cache=True)
def outlets(ldd, indeg, cell, area, lake):
    """Walk down from every source, on into each cell whose upstream is done.
    Returns lab (>0 outlet id, -1 drains to an outlet) and each outlet's
    sub-basin area: the unclaimed area it accumulated."""
    nrow, ncol = ldd.shape
    acc = np.zeros((nrow, ncol), np.float32)
    lab = np.zeros((nrow, ncol), np.int32)
    size = [0.0]
    for r in range(nrow):
        for c in range(ncol):
            if lab[r, c] != 0 or indeg[r, c] != 0 or not 1 <= ldd[r, c] <= 9:
                continue
            i, j = r, c
            while True:
                a = acc[i, j] + cell[i]
                di, dj = down(ldd, i, j)
                inside = lake[i, j] > 0 and di >= 0 and lake[di, dj] == lake[i, j]
                if di < 0 or (not inside and (a >= area or lake[i, j] > 0)):
                    lab[i, j] = len(size)
                    size.append(a)
                    a = 0.0
                else:
                    lab[i, j] = -1
                if di < 0:
                    break
                acc[di, dj] += a
                indeg[di, dj] -= 1
                if indeg[di, dj] != 0:
                    break
                i, j = di, dj
    return lab, np.array(size)


@njit(cache=True)
def follow(ldd, lab, r, c):
    i, j = r, c
    while lab[i, j] == -1:
        i, j = down(ldd, i, j)
    k = lab[i, j]
    i, j = r, c
    while lab[i, j] == -1:
        lab[i, j] = k
        i, j = down(ldd, i, j)


@njit(parallel=True, cache=True)
def label(ldd, lab):
    """Give every -1 cell the id of the outlet it drains to; threads racing on
    a shared path write the same id."""
    for r in prange(lab.shape[0]):
        for c in range(lab.shape[1]):
            if lab[r, c] == -1:
                follow(ldd, lab, np.int64(r), c)   # prange index is unsigned


def route(ldd, cell, area, lake):
    lab, size = outlets(ldd, indegree(ldd), cell, area, lake)
    label(ldd, lab)
    return lab, size


def join_lakes(lab, size, lake):
    """Merge the sub-basins of each lake with several exits into one and
    renumber 1..n, in place; returns the areas."""
    m = (lake > 0) & (lab > 0)
    lk, lb = np.unique(np.stack([lake[m], lab[m]]), axis=1)
    lk = np.unique(lk, return_inverse=True)[1]
    p = np.arange(size.size)
    while True:   # every label to the smallest label sharing a lake with it
        low = np.full(lk.max() + 1, size.size)
        np.minimum.at(low, lk, p[lb])
        q = p.copy()
        np.minimum.at(q, lb, low[lk])
        while not np.array_equal(r := q[q], q):
            q = r
        if np.array_equal(q, p):
            break
        p = q
    used = np.zeros(size.size, bool)
    used[p[1:]] = True
    newid = np.zeros(size.size, np.int32)
    newid[used] = np.arange(1, used.sum() + 1)
    relabel(lab, newid[p])
    return np.bincount(newid[p], weights=size)


@njit(cache=True)
def row_edges(lab, small, r, out, m):
    """(small id, neighbour id) per 4-neighbour face of row r with a small
    side, written from out[m] when out is not empty; returns the count."""
    nrow, ncol = lab.shape
    fill = out.shape[0] > 0
    n = 0
    for c in range(ncol):
        x = lab[r, c]
        if x == 0:
            continue
        for i, j in ((r, c + 1), (r + 1, c)):
            if i == nrow or j == ncol:
                continue
            y = lab[i, j]
            if y == 0 or y == x:
                continue
            if small[x]:
                if fill:
                    out[m + n, 0], out[m + n, 1] = x, y
                n += 1
            if small[y]:
                if fill:
                    out[m + n, 0], out[m + n, 1] = y, x
                n += 1
    return n


@njit(parallel=True, cache=True)
def small_edges(lab, small):
    nrow = lab.shape[0]
    none = np.empty((0, 2), np.int64)
    cnt = np.zeros(nrow + 1, np.int64)
    for r in prange(nrow):
        cnt[r + 1] = row_edges(lab, small, np.int64(r), none, 0)
    off = np.cumsum(cnt)
    out = np.empty((off[-1], 2), np.int64)
    for r in prange(nrow):
        row_edges(lab, small, np.int64(r), out, off[r])
    return out


@njit(parallel=True, cache=True)
def relabel(lab, newid):
    for r in prange(lab.shape[0]):
        for c in range(lab.shape[1]):
            lab[r, c] = newid[lab[r, c]]


def merge_small(lab, size, area):
    """Merge sub-basins under area/2 into larger neighbours and renumber
    1..n, in place; returns the final areas."""
    n = size.size
    e = small_edges(lab, size < area / 2)
    k, cnt = np.unique(e[:, 0] << 32 | e[:, 1], return_counts=True)
    a, b = k >> 32, k & 0xFFFFFFFF
    parent = np.arange(n)
    while True:
        # only into a strictly larger (area, id) neighbour, so no merge cycles
        m = (size[a] < area / 2) & ((size[b] > size[a]) | ((size[b] == size[a]) & (b > a)))
        if not m.any():
            break
        ea, eb = a[m], b[m]
        o = np.lexsort((cnt[m], ea))
        ea, eb = ea[o], eb[o]
        last = np.r_[ea[1:] != ea[:-1], True]   # longest border per small one
        p = np.arange(n)
        p[ea[last]] = eb[last]
        while not np.array_equal(q := p[p], p):
            p = q
        parent = p[parent]
        size = np.bincount(p, weights=size, minlength=n)
        a, b = p[a], p[b]
        keep = a != b
        k, inv = np.unique(a[keep] << 32 | b[keep], return_inverse=True)
        cnt = np.bincount(inv, weights=cnt[keep])
        a, b = k >> 32, k & 0xFFFFFFFF
    used = np.zeros(n, bool)
    used[parent[1:]] = True
    newid = np.zeros(n, np.int32)
    newid[used] = np.arange(1, used.sum() + 1)
    relabel(lab, newid[parent])
    return size[used]


def main(ldd_nc, lakes_nc, area, out_nc):
    v = netCDF4.Dataset(ldd_nc)["Band1"]
    v.set_auto_maskandscale(False)
    ldd = v[:].astype(np.uint8)
    nrow, ncol = ldd.shape
    edges = np.radians(90.0 - np.arange(nrow + 1) * 180.0 / nrow)
    cell = R * R * np.radians(360.0 / ncol) * (np.sin(edges[:-1]) - np.sin(edges[1:]))

    w = netCDF4.Dataset(lakes_nc)["waterBodyIds"]
    w.set_auto_maskandscale(False)
    lake = w[0]
    lake = np.where(lake < 1e19, lake, 0).astype(np.int32)   # 1e20 fill -> 0

    lab, size = route(ldd, cell, area, lake)
    del ldd
    size = join_lakes(lab, size, lake)
    del lake
    size = merge_small(lab, size, area)

    dx = 360.0 / ncol
    write_nc(out_nc, Header(ncol, nrow, -180.0, -90.0, 180.0, 90.0, dx, dx, 0, "<i4"), lab, zlib=False)
    print(f"{out_nc}: {size.size} sub-basins; km2 median {np.median(size):.0f}, mean {size.mean():.0f}, "
          f"5-95% {np.percentile(size, 5):.0f}-{np.percentile(size, 95):.0f}")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], float(sys.argv[3]), sys.argv[4])
