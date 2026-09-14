#!/bin/bash
# Parallel MODFLOW 6 (github.com/verkaik/modflow6-parallel), serial and MPI.
# Stock mf6 cannot run what mf6ggm writes: its `OPEN/CLOSE f (BINARY) p0 p1`
# byte-range reads of one packed .bin per model are a fork extension. The
# fork's own makefiles are ifort/mpiifort only and its serial (#else) branches
# never compiled; mf6_serial.patch is the minimum that makes them. Upstream's
# production binary was gfortran + OpenMPI (mf6_rel_openmpi-4.1.4-gcc-11.3.0),
# which is what the MPI build here is. Repo, commit, source and install
# directories, compilers and flags come from build.toml.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
export PATH="$root/.pixi/envs/default/bin:$PATH"
eval "$(python "$root/src/python/globgm_config.py" build-env "$root/build.toml")"
src=$MF6_SRC
work="$BUILD_DIR/mf6-build"
bindir=$TOOLS_BINDIR

# pixi's cctools ld rejects the 27.0 SDK's libSystem.tbd ("unknown
# architecture arm64e.x1-macos"); link against the newest SDK it accepts.
if [[ -n $BUILD_SDK_GLOB ]]; then
  export SDKROOT=$(ls -d $BUILD_SDK_GLOB | sort -V | tail -1)
fi

mkdir -p "$work" "$bindir"
if [[ ! -d $src/.git ]]; then
  git clone -q "$MF6_REPO" "$src"
fi
git -C "$src" fetch -q origin
git -C "$src" checkout -q --force "$MF6_REV"
git -C "$src" apply "$MF6_PATCH"

# compile order is the reference makefile's object list, which is the
# module dependency order; the fork ships no other complete one
ref="$root/reference/run_simulation/model_tools_src/fortran/modflow6/makefile"
objects=$(sed -n '/^OBJECTS/,/mf6\.o/p' "$ref" | grep -o '[A-Za-z0-9_]*\.o')
rm -f "$bindir/mf6" "$bindir/mf6_par"
cd "$src"

build() {  # build <exe name> <compiler> [<extra flags>]
  local exe=$1 fc=$2 flags=${3:-} obj="$work/obj_$1" n=0
  rm -rf "$obj"; mkdir -p "$obj"
  for o in $objects; do
    b=${o%.o}
    f=$(find src -name "$b.f90" -o -name "$b.fpp" | head -1)
    [[ -n $f ]] || { echo "no source for $o" >&2; exit 1; }
    $fc $MF6_FLAGS $flags -J"$obj" -I"$obj" -c "$f" -o "$obj/$o"
    n=$((n+1))
  done
  $fc -o "$bindir/$exe" "$obj"/*.o
  echo "$exe $("$bindir/$exe" --version | cut -d: -f2 | xargs), $n objects, installed in $bindir"
}

build mf6 "$MF6_FC"
build mf6_par "$MF6_MPIFC" "$MF6_MPI_FLAGS"
