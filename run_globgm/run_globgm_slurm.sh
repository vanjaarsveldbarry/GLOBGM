#!/usr/bin/env bash
# Builds the binaries (build.toml), then launches the GLOBGM pipeline
# (run_globgm/scripts) with the slurm profile.
# Nextflow stays in the foreground for the whole run and submits each stage
# as its own job, so start this inside tmux/screen or with nohup.
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")/.."
pixi run build_globgm
pixi run run_globgm_slurm
