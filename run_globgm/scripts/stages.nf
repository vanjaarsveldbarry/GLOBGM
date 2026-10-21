// The GLOBGM stages as processes; see main.nf. Every value a process uses
// is an input, from the params.json globgm_config.py writes from globgm.toml
// (only the output root is a param, from nextflow.config), so a changed key
// reruns exactly the tasks it feeds. Each process works in its task directory: inputs are staged under the names the
// generated .inp files expect (TASK_LAYOUT in globgm_config.py), outputs are
// the files themselves, and publishDir hard-links the products under the
// output root. The Fortran tools and Python scripts a process runs are path
// inputs too, so a rebuild or an edit reruns what depends on it; only the
// pixi environment (python, gdal, mpirun) is ambient. Every tool's stdout and
// stderr is a `*.log` at the task's top level, published flat under
// params.logs; publishDir skips a failed task, so on failure the log's tail
// goes to stderr, where Nextflow's error report shows it.

// Builds every intermediate map_glob's datamap call needs: rasterised
// HydroBASINS regions, the filtered catchment raster and d_top_2.
process preprocess_inputs {
  publishDir params.logs, mode: 'link', pattern: '*.log'
  input:
    val c
    path ldd
    path dem
    path confining
    path tools, stageAs: 'tools/*'
  output:
    path 'hybas_lake_lev*_v1c_filt.nc'
    path 'd_top_2.nc'
    path '*.log'
  script:
  def zips  = c.hydrobasins_cache   // only thing kept between runs
  def g     = c.grid
  def regs  = c.regions.split(' ').collect { "hybas_lake_${it}_lev${c.level}_v1c" }
  def cat   = "hybas_lake_lev${c.level}_v1c_filt"
  """
  mkdir -p ${zips} shp

  for r in ${c.regions}; do
    z=hybas_lake_\${r}_lev01-12_v1c.zip
    n=hybas_lake_\${r}_lev${c.level}_v1c
    [[ -s ${zips}/\$z ]] || curl -sSfL -C - --retry ${c.curl_retries} -o ${zips}/\$z ${c.hydrobasins_url}\$z
    unzip -q -o -j ${zips}/\$z "*lev${c.level}_v1c.*" -d shp
    gdal_rasterize -l \$n -a ${c.rasterize_attribute} -ts ${g.ncol} ${g.nrow} -a_nodata ${c.rasterize_nodata} \\
      -te ${c.rasterize_te} -ot Int32 -of EHdr shp/\$n.shp \$n.flt
    python tools/globgm_raster.py \$n.flt \$n.nc
  done

  python tools/make_landmask.py ${ldd} landmask.nc ${regs.collect { it + '.nc' }.join(' ')}
  tools/process_hydbas landmask ${cat} ${regs.join(' ')} > process_hydbas.log 2>&1 \\
    || { tail -n 40 process_hydbas.log >&2; exit 1; }
  python tools/make_d_top_2.py ${dem} ${confining} d_top_2.nc

  rm -rf shp *.flt *.hdr *.prj *.aux.xml   # ~30 GB of global rasterize scratch
  """
}

process map_glob {
  publishDir params.output, mode: 'link', pattern: 'datamap'
  publishDir params.logs, mode: 'link', pattern: '*.log'
  input:
    val c
    path cat
    path d_top_2
    path tools, stageAs: 'tools/*'
  output:
    path 'datamap'
    path '*.log'
  script:
  """
  mkdir -p datamap
  tools/datamap ${c.sea_boundary} datamap/map_glob ${cat} ${d_top_2} \\
    ${c.layer_threshold} ${c.max_neighbours} ${c.window} > datamap.log 2>&1 \\
    || { tail -n 40 datamap.log >&2; exit 1; }
  """
}

process fields {
  publishDir params.output, mode: 'link'
  input:
    path synthetic
    path ldd
    path dem
    path confining
    path tools, stageAs: 'tools/*'
  output: path 'fields'
  script:
  """
  python tools/make_synthetic_fields.py ${synthetic} fields
  """
}

process mf6_input {
  tag "${run}"
  publishDir params.logs, mode: 'link', pattern: '*.log'
  input:
    path datamap
    path fields, stageAs: 'fields'
    tuple val(run), val(phase)
    path ggm
    path mod
    val args
    path mf6ggm
  output:
    path "${phase}", emit: tree
    path '*.log'
  script:
  """
  mkdir ${phase}
  ./${mf6ggm} ${ggm} ${args} > mf6ggm.${phase}.log 2>&1 \\
    || { tail -n 40 mf6ggm.${phase}.log >&2; exit 1; }
  """
}

// One solution of one simulation, run from the tree's solutions/run_output/
// as the reference job scripts do, in a hard-linked copy of the mf6_input
// output so that nothing is written into that task. `strt` is the previous
// phase's merged tree, staged under its phase name where the .ic files point,
// or [] for the steady state. `np` is the nam's DOMAIN_DECOMPOSITION (main.nf
// reads it), one MPI rank per submodel group; a `ser` nam has none and runs
// its submodels in one process. Only what the run wrote leaves the task, as
// an overlay of the tree for mf6_tree; every file in it carries its
// solution's or model's name, so overlays never collide.
process mf6 {
  tag "${phase}/${sol}"
  publishDir params.logs, mode: 'link', pattern: '*.log'
  input:
    path tree, stageAs: 'input'
    path strt
    tuple val(phase), val(sim), val(hds)
    tuple val(sol), val(np)
    val c
    path exe
  output:
    path "overlay.${sol}", emit: overlay
    path '*.log'
  script:
  def nam = "../run_input/${sol}.${c.mode}.mfsim.${sim}.nam"
  def launch = c.mode == 'par'
    ? "mpirun -np ${np} ${c.mpirun_args} \$exe"
    : "\$exe"
  """
  exe=\$PWD/${exe}
  log=\$PWD/mf6.${phase}.${sol}.log
  cp -RLl input ${phase}
  cd ${phase}/solutions/run_output
  { ${launch} -s ${nam} > \$log 2>&1 && grep -q 'Normal termination' \$log; } \\
    || { tail -n 40 \$log >&2; exit 1; }
  ls ../../models/run_output_bin/*.${hds} > /dev/null
  cd ../../..
  mkdir -p overlay.${sol}/models overlay.${sol}/solutions
  mv ${phase}/models/run_output_bin ${phase}/models/run_output_lst overlay.${sol}/models/
  mv ${phase}/solutions/run_output overlay.${sol}/solutions/
  """
}

// The phase's tree with every solution's results in it: what post reads and
// what the next phase starts from.
process mf6_tree {
  tag "${phase}"
  publishDir "${params.output}/mf6ggm", mode: 'link'
  input:
    path tree, stageAs: 'input'
    path overlays
    val phase
  output:
    path "${phase}"
  script:
  """
  cp -RLl input ${phase}
  for o in ${overlays}; do cp -RLl \$o/. ${phase}/; done
  """
}

process post {
  tag "${run}/${job}"
  publishDir "${params.output}/post", mode: 'link', pattern: '*.nc', saveAs: { "${phase}/${it}" }
  publishDir params.logs, mode: 'link', pattern: '*.log'
  input:
    path tree
    path fields, stageAs: 'fields'
    tuple val(run), val(phase)
    tuple val(job), path(inp)
    path mf6ggmpost
  output:
    path '*.nc'
    path '*.log'
  script:
  """
  ./${mf6ggmpost} ${inp} > mf6ggmpost.${phase}.${job}.log 2>&1 \\
    || { tail -n 40 mf6ggmpost.${phase}.${job}.log >&2; exit 1; }
  """
}
