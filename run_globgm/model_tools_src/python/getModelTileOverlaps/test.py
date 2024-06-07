# import imod
# ds = imod.idf.open("/projects/0/einf4705/workflow/GLOBGM/run_globgm/_data/globgm_input/inp_idf/d_top_2.idf")
# ds.to_netcdf("/projects/0/einf4705/workflow/GLOBGM/run_globgm/_data/globgm_input/inp_idf/test.nc")

import xarray as xr
import numpy as np
ds = xr.open_dataset('/projects/0/einf4705/workflow/GLOBGM/run_globgm/_data/globgm_input/inp_idf/test.nc')
print(ds)
vals = ds.d_top_2.values
print(len(np.unique(vals)))