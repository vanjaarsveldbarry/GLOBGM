#!/usr/bin/env bash
# Builds the binaries (build.toml), then launches the GLOBGM pipeline
# (run_globgm/scripts) with the local profile.
# Every stage runs on this machine inside the Nextflow process, so run it on
# a node with enough cores/memory, inside tmux/screen or with nohup.
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")/.."
pixi run build_globgm
pixi run run_globgm "$@"
