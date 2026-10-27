#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")/.."
pixi run build_globgm
pixi run run_globgm
