import xarray as xr
import numpy as np
from numba import njit, prange
from numba_progress import ProgressBar
import numba
import os 
numba.set_num_threads(190)
print("Default number of threads:", numba.config.NUMBA_NUM_THREADS)
print(f"Number of CPU cores: {os.cpu_count()}")
def main():
    
    for scenario in ["historical", "ssp126", "ssp370", "ssp585"]:
        ds = xr.open_zarr(f'/scratch-shared/globgm_scratch/temp/data/{scenario}/s03_wtd.zarr')['l2_wtd'].compute()
        data = ds#.resample(time='YE').mean()
        data = data.values
        print(ds)
        
        total_iterations = data.shape[1] * data.shape[2]
        
        @njit(parallel=True, nogil=True)
        def calculate_theil_sen_slope(data, progress_proxy):
            medslope = np.empty(data.shape[1:], dtype=np.float64)
            n = data.shape[0]
            num_slopes = (n * (n - 1)) // 2
        
            for i in prange(data.shape[1]):
                for j in prange(data.shape[2]):
                    y = data[:, i, j]
                    if np.isnan(y[0]):
                        medslope[i, j] = np.nan
                        progress_proxy.update(1)
                        continue
                    slopes = np.empty(num_slopes, dtype=np.float64)
                    k = 0
                    for ii in range(n - 1):
                        for jj in range(ii + 1, n):
                            slopes[k] = (y[jj] - y[ii]) / (jj - ii)
                            k += 1
                    slopes.sort()
                    medslope[i, j] = np.median(slopes)
                    progress_proxy.update(1)
        
            return medslope
        with ProgressBar(total=total_iterations) as progress:
            medslope = calculate_theil_sen_slope(data, progress)
            print(medslope.shape)
            result_ds = xr.Dataset({"medslope": (("latitude", "longitude"), medslope)},coords={"latitude": ds.coords["latitude"],"longitude": ds.coords["longitude"]})
            print(result_ds)
            result_ds.to_netcdf(f'/scratch-shared/globgm_scratch/temp/data/{scenario}/s03_wtd_medslope.nc')        
if __name__ == "__main__":
    medslope = main()