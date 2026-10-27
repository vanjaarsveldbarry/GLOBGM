// fields.json names the inputs of the fields by absolute path.
process preprocess_inputs {
  publishDir "${params.output}/preprocess_inputs", mode: 'link', pattern: '{*.nc,fields}'
  publishDir params.logs, mode: 'link', pattern: '*.log'
  input:
    val c
    path ldd
    path lakes
    path dem
    path confining
    path cfg
    path tools, stageAs: 'tools/*'
  output:
    path 'subbasins.nc', emit: subbasins
    path 'd_top_2.nc', emit: d_top_2
    path 'fields', emit: fields
    path '*.log'
  script:
  """
  python "\$(readlink -f tools/make_subbasins.py)" ${ldd} ${lakes} ${c.area} subbasins.nc > make_subbasins.log 2>&1 \\
    || { tail -n 40 make_subbasins.log >&2; exit 1; }
  python tools/make_d_top_2.py ${dem} ${confining} d_top_2.nc
  python tools/make_fields.py ${cfg} fields > make_fields.log 2>&1 \\
    || { tail -n 40 make_fields.log >&2; exit 1; }
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
    path 'datamap', emit: datamap
    path '*.log'
  script:
  """
  mkdir -p datamap
  tools/datamap ${c.sea_boundary} datamap/map_glob ${cat} ${d_top_2} \\
    ${c.layer_threshold} ${c.max_neighbours} ${c.window} > datamap.log 2>&1 \\
    || { tail -n 40 datamap.log >&2; exit 1; }
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

// One solution in a hard-linked copy of the tree; `strt` is the previous phase's
// tree, `np` the nam's MPI ranks. Only its outputs leave, as an overlay for mf6_tree.
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

def cfg(c, name) { file("${c.config_dir}/${name}") }
def tool(c, name) { file("${c.binaries}/${name}") }

// One [solution, MPI ranks] per nam mf6ggm wrote, so an inactive solution is absent.
def solutions(tree, c, ph) {
  tree.flatMap { t -> files("${t}/solutions/run_input/s*.${c.mf6.mode}.mfsim.${c.nam[ph]}.nam") }
      .map { nam ->
        def dd = nam.readLines()*.trim().find { it.startsWith('DOMAIN_DECOMPOSITION') }
        [nam.name.tokenize('.')[0], dd ? dd.tokenize()[1] as int : 1]
      }
}

// mf6ggm input -> mf6 per solution -> merged tree -> post; `strt` is [] for the first phase.
workflow phase {
  take:
    c
    ph
    datamap
    fl
    strt
  main:
    def run = c.sim[ph]
    mf6_input(datamap, fl, [run, ph], cfg(c, "mf6ggm_${run}.inp"), cfg(c, "mf6_mod_${run}.inp"), c.mf6_input.mf6ggm_args, tool(c, 'mf6ggm'))
    def tree_in = mf6_input.out.tree
    mf6(tree_in, strt, [ph, c.nam[ph], c.hds[ph]], solutions(tree_in, c, ph), c.mf6, tool(c, c.mf6.mode == 'par' ? 'mf6_par' : 'mf6'))
    mf6_tree(tree_in, mf6.out.overlay.collect(), ph)
    if (ph in c.post_phases)
      post(mf6_tree.out, fl, [run, ph], Channel.fromList(c.post_jobs.collect { [it, cfg(c, "mf6ggmpost_${run}.${it}.inp")] }), tool(c, 'mf6ggmpost'))
  emit:
    mf6_tree.out
}
