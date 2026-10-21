#!/bin/bash
# Convert the steady-state zarr to the twenty NetCDF fields under
# ../output/input_data/steady-state. The GLOBGM pixi env has no zarr, so this
# runs with chapter2's.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
prj=/gpfs/work4/0/prjs1222

"$prj/chapter2/chapter2_code/.pixi/envs/default/bin/python" "$here/ss_zarr_to_fields.py" \
  "$prj/globgm_output/steady_state/ss.zarr" \
  "$prj/globgm_port/output/input_data/steady-state"
