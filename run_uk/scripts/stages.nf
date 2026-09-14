// The GLOBGM stages as processes; see main.nf. Every value a process uses
// is an input, from the params.json globgm_config.py writes from globgm.toml
// (only the output root is a param, from nextflow.config), so a changed key
// reruns exactly the tasks it feeds. Each process works in its task directory: inputs are staged under the names the
// generated .inp files expect (TASK_LAYOUT in globgm_config.py), outputs are
// the files themselves, and publishDir hard-links the products under the
// output root. The Fortran tools and Python scripts a process runs are path
// inputs too, so a rebuild or an edit reruns what depends on it; only the
// pixi environment (python, gdal, mpirun) is ambient. Every tool's stdout is
// a `*.log` at the task's top level, published flat under params.logs.

process map_glob {
  publishDir params.output, mode: 'link', pattern: '{datamap,tiles}'
  publishDir params.logs, mode: 'link', pattern: '*.log'
  input:
    val c
    path ldd
    path dem
    path confining
    path tools, stageAs: 'tools/*'
  output:
    path 'datamap'
    path 'tiles'
    path '*.log'
  script:
  def zips  = c.hydrobasins_cache   // only thing kept between runs
  def g     = c.grid
  def regs  = c.regions.split(' ').collect { "hybas_lake_${it}_lev${c.level}_v1c" }
  def cat   = "hybas_lake_lev${c.level}_v1c_filt"
  """
  mkdir -p ${zips} shp datamap tiles

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
  tools/process_hydbas landmask ${cat} ${regs.join(' ')} > process_hydbas.log
  python tools/make_tiles.py landmask.nc tiles ${c.tile_prefix} ${c.window}
  tile_txt=\$(echo tiles/${c.tile_prefix}*.txt)
  python tools/make_d_top_2.py ${dem} ${confining} \$tile_txt d_top_2.nc

  tools/datamap ${c.sea_boundary} datamap/map_glob ${cat}.nc d_top_2.nc \$tile_txt tiles/${c.tile_prefix} \\
    ${c.layer_threshold} ${c.max_neighbours} ${c.window} > datamap.log

  rm -rf shp *.flt *.hdr *.prj *.aux.xml   # ~30 GB of global rasterize scratch
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
  ./${mf6ggm} ${ggm} ${args} > mf6ggm.${phase}.log
  """
}

// One simulation, run from its solution's run_output/ as the reference job
// scripts do. The tree is a hard-linked copy of the mf6_input output so that
// the results land beside the inputs without writing into that task; `strt`
// is the previous phase's tree, staged under its phase name where the .ic
// files point, or [] for the steady state. `par` is one MPI rank per submodel
// through mf6ggm's DOMAIN_DECOMPOSITION; `ser` runs the same submodels in
// one process.
process mf6 {
  tag "${phase}/${sim}/${c.mode}"
  publishDir "${params.output}/mf6ggm", mode: 'link', saveAs: { it.endsWith('.log') ? null : it }
  publishDir params.logs, mode: 'link', pattern: '*.log'
  input:
    path tree, stageAs: 'input'
    path strt
    tuple val(phase), val(sim), val(hds)
    val c
    path exe
  output:
    path "${phase}", emit: tree
    path '*.log'
  script:
  def nam = "../run_input/s01.${c.mode}.mfsim.${sim}.nam"
  def launch = c.mode == 'par'
    ? "mpirun -np \$(awk '\$1 == \"DOMAIN_DECOMPOSITION\" {print \$2}' ${nam}) ${c.mpirun_args} \$exe"
    : "\$exe"
  """
  exe=\$PWD/${exe}
  log=\$PWD/mf6.${phase}.log
  cp -RLl input ${phase}
  cd ${phase}/solutions/run_output
  ${launch} -s ${nam} > \$log 2>&1
  grep -q 'Normal termination' \$log
  ls ../../models/run_output_bin/*.${hds} > /dev/null
  """
}

process post {
  tag "${run}"
  publishDir "${params.output}/post", mode: 'link', pattern: '*.nc', saveAs: { "${phase}/${it}" }
  publishDir params.logs, mode: 'link', pattern: '*.log'
  input:
    path tree
    path fields, stageAs: 'fields'
    tuple val(run), val(phase)
    path inp
    path mf6ggmpost
  output:
    path '*.nc'
    path '*.log'
  script:
  """
  ./${mf6ggmpost} ${inp} > mf6ggmpost.${phase}.log
  """
}
