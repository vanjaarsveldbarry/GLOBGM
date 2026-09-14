#!/bin/bash
# Everything the pipeline executes: METIS and mf6 when missing, the four tools
# via CMake, all into the tools bindir (METIS into the build tree). Runs inside
# `pixi run`; every choice comes from build.toml.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$root"
eval "$(python src/python/globgm_config.py build-env build.toml)"

# pixi's cctools ld rejects the 27.0 SDK; the newest earlier one wins
if [[ -n $BUILD_SDK_GLOB ]]; then
  export SDKROOT=$(ls -d $BUILD_SDK_GLOB | sort -V | tail -1)
fi

[[ $BUILD_REBUILD_DEPS == 0 && -f $METIS_PREFIX/include/metis.h ]] || bash src/scripts/build_metis.sh
cmake -S src/fortran -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
  -DCMAKE_Fortran_COMPILER="$BUILD_FC" -DMETIS_ROOT="$METIS_PREFIX"
cmake --build "$BUILD_DIR" -j "$BUILD_JOBS"
mkdir -p "$TOOLS_BINDIR"
# an unchanged tool keeps its mtime, which Nextflow's cache keys on
for f in "$BUILD_DIR"/bin/*; do
  cmp -s "$f" "$TOOLS_BINDIR/$(basename "$f")" || cp "$f" "$TOOLS_BINDIR"/
done
[[ $BUILD_REBUILD_DEPS == 0 && -x $TOOLS_BINDIR/mf6 && -x $TOOLS_BINDIR/mf6_par ]] || bash src/scripts/build_mf6.sh
