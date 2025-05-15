import sys
from pathlib import Path
import xarray as xr
import numpy as np
import numba
from numba import njit, prange
from numba_progress import ProgressBar
from pathlib import Path
from math import erf, sqrt
import itertools as itt

save_dir = Path(sys.argv[1])
start_year = sys.argv[2]
end_year = sys.argv[3]

save_path=save_dir.parent / f'output/{start_year}/gwRecharge_slope.nc'
save_path.parent.mkdir(parents=True, exist_ok=True)

def _read_recharge():
    ds = xr.open_zarr(save_dir / 'gwRecharge_annual.zarr')['__xarray_dataarray_variable__']
    ds = ds.sel(time=slice(f'{start_year}-01-01', f'{end_year}-12-31'))
    ds = ds.compute()
    lat_coords = ds.coords["latitude"].values
    lon_coords = ds.coords["longitude"].values
    return ds.values.astype(np.float32), lat_coords, lon_coords

ds, lat_coords, lon_coords = _read_recharge()

def precompute_indices(n):
    num_slopes = (n * (n - 1)) // 2
    indices = np.empty((num_slopes, 2), dtype=np.int32)
    k = 0
    for ii in range(n - 1):  # Use range for the outer loop
        for jj in range(ii + 1, n):  # Use range for the inner loop
            indices[k, 0] = ii
            indices[k, 1] = jj
            k += 1
    return indices, num_slopes

def get_valid_indices(ds):
    valid_indices = np.argwhere(~np.isnan(ds[0, :, :]))
    return valid_indices

@njit(parallel=True, nogil=False, fastmath=True)
def calculate_theil_sen_slope(data, valid_indices, time_pairs, time_idx, progress_proxy, number_of_iterations):
    medslope_array = np.full(data.shape[1:], np.nan, dtype=np.float32)
    p_arrray = np.full(data.shape[1:], np.nan, dtype=np.float32)

    n_timepairs = len(time_pairs)
    for iterat in prange(number_of_iterations):
        i, j = valid_indices[iterat]
        y = data[:, i, j]
        n_time = len(y)
        slopes = []
        for _idx in prange(n_timepairs):
            _ii, _jj = time_pairs[_idx]
            slope = (y[_jj] - y[_ii]) / (time_idx[_jj] - time_idx[_ii])
            slopes.append(slope)

        if n_timepairs % 2 == 1:
            medslope = sorted(slopes)[n_timepairs//2]
        else:
            medslope = sum(sorted(slopes)[n_timepairs//2-1:n_timepairs//2+1])/2.0
        medslope_array[i, j] = medslope

        S = 0
        for _i in prange(n_time - 1):
            for _j in prange(_i + 1, n_time):
                S += (1 if y[_j] > y[_i] else -1 if y[_j] < y[_i] else 0)

        unique_y = np.unique(y)
        g = len(unique_y)

        # calculate the var(s)
        if n_time == g:            # there is no tie
            var_s = (n_time*(n_time-1)*(2*n_time+5))/18

        else:                 # there are some ties in data
            tp = np.zeros(unique_y.shape)
            demo = np.ones(n_time)

            for g_i in prange(g):
                tp[g_i] = np.sum(demo[y == unique_y[g_i]])

            var_s = (n_time*(n_time-1)*(2*n_time+5) - np.sum(tp*(tp-1)*(2*tp+5)))/18

        # Compute Z-score
        if S > 0:
            Z = (S - 1) / sqrt(var_s)
        elif S < 0:
            Z = (S + 1) / sqrt(var_s)
        else:
            Z = 0

        p = 2 * (1 - 0.5 * (1 + erf(abs(Z) / sqrt(2))))
        p_arrray[i, j] = p

        progress_proxy.update(1)
    return medslope_array, p_arrray
valid_indices = get_valid_indices(ds)
number_of_iterations = len(valid_indices)
time_pairs = [(i, j) for (i, j) in itt.combinations(range(len(range(ds.shape[0]))), 2)]
time_idx = np.arange(ds.shape[0])
medslope = None
p_barry = None
with ProgressBar(total=number_of_iterations) as progress:
    medslope_barry, p_barry = calculate_theil_sen_slope(ds, valid_indices, time_pairs, time_idx, progress, number_of_iterations)

ds_out = xr.Dataset({"slope": (("latitude", "longitude"), medslope_barry),
                        "p": (("latitude", "longitude"), p_barry),
                    },
                        coords={"latitude": lat_coords,
                                "longitude": lon_coords})
ds_out.to_netcdf(save_path, mode='w')
