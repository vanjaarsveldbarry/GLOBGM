#!/bin/bash
# METIS with 64-bit idx_t, which `metis_module.f90` requires and no packaged
# build provides: conda-forge and Homebrew both ship IDXTYPEWIDTH 32, which
# links cleanly, returns METIS_OK and partitions into garbage. Version, URL,
# checksum, source and install directories come from build.toml.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
export PATH="$root/.pixi/envs/default/bin:$PATH"
eval "$(python "$root/src/python/globgm_config.py" build-env "$root/build.toml")"
ver=$METIS_VERSION
src="$METIS_SRC/metis-$ver"
build="$BUILD_DIR/metis-build"
prefix=$METIS_PREFIX

mkdir -p "$METIS_SRC"
tar="$METIS_SRC/metis-$ver.tar.gz"
[[ -s $tar ]] || curl -sSfL --retry 3 -o "$tar" "$METIS_URL"
echo "$METIS_SHA256  $tar" | shasum -a 256 -c -

rm -rf "$src" "$build" "$prefix"
tar xzf "$tar" -C "$METIS_SRC"
cd "$src"

# REALTYPEWIDTH stays 32: metis_module declares tpwgts/ubvec real(r4b)
sed -i '' 's/^#define IDXTYPEWIDTH 32/#define IDXTYPEWIDTH 64/' include/metis.h
grep -q '^#define IDXTYPEWIDTH 64' include/metis.h
grep -q '^#define REALTYPEWIDTH 32' include/metis.h

cmake -S . -B "$build" -DCMAKE_BUILD_TYPE=Release -DGKLIB_PATH="$PWD/GKlib" \
  -DCMAKE_INSTALL_PREFIX="$prefix" -DSHARED=OFF -DCMAKE_POLICY_VERSION_MINIMUM=3.5
cmake --build "$build" -j "$BUILD_JOBS"
cmake --install "$build"

# link-and-run proof: a 32-bit library reaches this point and fails here
"$BUILD_FC" "$root/src/fortran/metis_check.f90" -I"$prefix/include" \
  "$prefix/lib/libmetis.a" -o "$build/metis_check"
"$build/metis_check"
echo "METIS $ver (idx_t 64-bit) installed in $prefix"
