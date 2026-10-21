#!/bin/bash
# Benchmark one mf6ggm phase on the published inputs: wall/CPU/peak RSS from
# /usr/bin/time, rchar/wchar/RSS sampled once a second from /proc, a perf
# profile, per-model times from the done_* sentinels. Everything lands in
# <root>/<label>/<phase>/ (default root ../output/run_globgm/bench); the output tree
# there is the reference compare_mf6ggm_tree.py checks later runs against.
#   bench_mf6ggm.sh <label> <ss|spu|tr> [root]
#   bench_mf6ggm.sh --summary <dir>        rewrite summary.md of a finished run
# MF6GGM=<binary> overrides ../output/run_globgm/binaries/mf6ggm; BENCH_PERF=0 skips perf.
set -euo pipefail
here="$(cd "$(dirname "$0")/../.." && pwd)"

summarize() {
  cd "$1"
  local tree wall user sys cpu rss written io models
  tree=$(awk 'NR==2' mf6ggm_*.inp | tr -d '/')
  if [ -f perf.data ]; then
    perf report -i perf.data --no-children --sort dso --stdio 2>/dev/null \
      | awk '!/^#/ && /%/ && !/^ *[|-]/' > perf_dso.txt
    perf report -i perf.data --no-children --sort dso,symbol --stdio 2>/dev/null \
      | awk '!/^#/ && /%/ && !/^ *[|-]/ && n++ < 25' > perf_symbols.txt
  fi
  wall=$(awk -F': ' '/Elapsed/{print $2}' time.txt)
  user=$(awk -F': ' '/User time/{print $2}' time.txt)
  sys=$(awk -F': ' '/System time/{print $2}' time.txt)
  cpu=$(awk -F': ' '/Percent of CPU/{print $2}' time.txt)
  rss=$(awk -F': ' '/Maximum resident/{printf "%.2f GB", $2/1048576}' time.txt)
  written=$(du -sb "$tree" | awk '{printf "%.2f GB", $1/1e9}')
  io=$(tail -1 samples.tsv | awk -F'\t' '{printf "rchar %.2f GB, wchar %.2f GB", $3/1e9, $4/1e9}')
  models=$(stat -c %Y "$tree"/log/done_* | sort -n | awk '
    NR>1 {d[NR-1]=$1-p; s+=$1-p} {p=$1}
    END {n=asort(d); printf "%d models, write loop %ds, median %ds, max %ds", n+1, s, d[int((n+1)/2)], d[n]}')
  {
    echo "# mf6ggm bench: $(basename "$(dirname "$PWD")") / $(basename "$PWD")"
    echo
    echo "- host $(hostname), fs $(df -T . | awk 'NR==2{print $2, $1}'), binary sha256 $(sha256sum mf6ggm | cut -c1-12)"
    echo "- wall $wall, user ${user}s, sys ${sys}s, cpu $cpu, peak rss $rss"
    echo "- output $written, $io"
    echo "- $models"
    if [ -f perf_dso.txt ]; then
      echo; echo "## cpu by library"; echo; sed 's/^ */    /' perf_dso.txt
      echo; echo "## top symbols"; echo; sed 's/^ */    /' perf_symbols.txt
    fi
  } > summary.md
  cat summary.md
}

if [ "$1" = --summary ]; then
  summarize "$2"
  exit 0
fi

label=$1; phase=$2; root=${3:-$here/../output/run_globgm/bench}
case $phase in
  ss|spu|tr) ;;
  *) echo "phase must be ss, spu or tr" >&2; exit 2 ;;
esac
bin=${MF6GGM:-$here/../output/run_globgm/binaries/mf6ggm}
cfg=$here/../output/run_globgm/config
d=$root/$label/$phase
[ -e "$d" ] && { echo "$d exists: pick another label or remove it" >&2; exit 1; }
mkdir -p "$d"; cd "$d"
ln -s "$here/../output/run_globgm/datamap" datamap
ln -s "$here/../output/run_globgm/fields" fields
cp "$cfg/mf6ggm_$phase.inp" "$cfg/mf6_mod_$phase.inp" .
cp "$bin" mf6ggm

perf_cmd=()
if [ "${BENCH_PERF:-1}" = 1 ]; then perf_cmd=(perf record -F 499 -g -o perf.data --); fi

t0=$(date +%s)
( /usr/bin/time -v -o time.txt "${perf_cmd[@]}" ./mf6ggm "mf6ggm_$phase.inp" > mf6ggm.log 2>&1 ) &
runner=$!

pid=
for _ in $(seq 1 100); do
  for p in $(pgrep -x mf6ggm); do
    case "$(readlink "/proc/$p/cwd" 2>/dev/null)" in "$d"*) pid=$p ;; esac
  done
  [ -n "$pid" ] && break
  sleep 0.1
done
[ -n "$pid" ] || { echo "mf6ggm did not start" >&2; wait $runner; exit 1; }

printf 't_s\trss_kb\trchar\twchar\tread_bytes\twrite_bytes\n' > samples.tsv
while kill -0 "$pid" 2>/dev/null; do
  rss=$(awk '/^VmRSS/{print $2}' "/proc/$pid/status" 2>/dev/null) || break
  io=$(awk '/^rchar/{a=$2} /^wchar/{b=$2} /^read_bytes/{c=$2} /^write_bytes/{d=$2} END{print a"\t"b"\t"c"\t"d}' "/proc/$pid/io" 2>/dev/null) || break
  printf '%s\t%s\t%s\n' "$(( $(date +%s) - t0 ))" "$rss" "$io" >> samples.tsv
  sleep 1
done
wait $runner
summarize "$d"
