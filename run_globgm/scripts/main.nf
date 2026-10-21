// GLOBGM on one window: the four stages as processes in stages.nf, a
// separate file because Nextflow invokes a process once per file unless it
// is included under an alias, and a file cannot include itself. The
// workflow first runs globgm_config.py on params.config (globgm.toml), which
// writes the .inp files and params.json under <output>/config and empties
// the rest of the output root; every value below then comes from that
// params.json. Every edge carries the files themselves; the products are
// published under the output root.

include { preprocess_inputs; map_glob; fields } from './stages'
include { mf6_input as mf6_input_ss; mf6_input as mf6_input_spu; mf6_input as mf6_input_tr } from './stages'
include { mf6 as mf6_ss; mf6 as mf6_spu; mf6 as mf6_tr } from './stages'
include { mf6_tree as mf6_tree_ss; mf6_tree as mf6_tree_spu; mf6_tree as mf6_tree_tr } from './stages'
include { post as post_ss; post as post_tr } from './stages'

def src(name)       { file("${projectDir.parent.parent}/src/python/${name}") }
def cfg(c, name)    { file("${c.config_dir}/${name}") }
def raster(c, name) { file("${c.inputs_dir}/${name}") }
def tool(c, name)   { file("${c.binaries}/${name}") }
def inp(c, ph)      { Channel.value([c.sim[ph] as String, ph as String]) }
def simv(c, ph)     { Channel.value([ph as String, c.nam[ph] as String, c.hds[ph] as String]) }
// one post task per (solution, output): [job, its one-job .inp]
def post_inps(c, ph) { Channel.fromList(c.post_jobs.collect { [it as String, cfg(c, "mf6ggmpost_${c.sim[ph]}.${it}.inp")] }) }

// One [solution, MPI ranks] per simulation nam mf6ggm wrote into the tree, so
// an inactive solution is simply absent and each task is sized from its nam.
def solutions(tree, c, ph) {
  tree.flatMap { t -> files("${t}/solutions/run_input/s*.${c.mf6.mode}.mfsim.${c.nam[ph]}.nam") }
      .map { nam ->
        def dd = nam.readLines()*.trim().find { it.startsWith('DOMAIN_DECOMPOSITION') }
        [nam.name.tokenize('.')[0], dd ? dd.tokenize()[1] as int : 1]
      }
}

def generate() {
  def p = ['python', src('globgm_config.py').toString(), 'run', params.config, params.output].execute()
  def out = new StringBuffer()
  def err = new StringBuffer()
  p.waitForProcessOutput(out, err)
  if (p.exitValue() != 0) error("globgm_config.py failed:\n${err}")
  log.info out.toString().trim()
  return new groovy.json.JsonSlurper().parse(file("${params.output}/config/params.json"))
}

// Up to three phases, each mf6ggm input -> mf6 in its own tree: steady state,
// spin-up from the steady-state heads, transient from the spin-up heads (or
// from the steady-state heads when there is no spin-up).
workflow {
  def c = generate()
  def phases = c.phases as List
  def ldd = raster(c, c.ldd)
  def dem = raster(c, c.dem)
  def confining = raster(c, c.confining)

  def mf6ggm = tool(c, 'mf6ggm')
  def mf6exe = tool(c, c.mf6.mode == 'par' ? 'mf6_par' : 'mf6')
  def mf6ggmpost = tool(c, 'mf6ggmpost')
  def raster_py = src('globgm_raster.py')   // imported by the other scripts

  // Needs nothing from stage 1 (design.md, "Synthetic fields until
  // PCR-GLOBWB delivers"), so it runs first: [fields] source = "synthetic"
  // triggers it and publishes to [fields] dir; "external" reads dir as-is.
  def fl = c.fields_source == 'synthetic'
    ? fields(cfg(c, 'synthetic.json'), ldd, dem, confining, [raster_py, src('make_synthetic_fields.py')])
    : Channel.value(file(c.fields_dir))

  preprocess_inputs(Channel.value(c.preprocess_inputs), ldd, dem, confining,
           [raster_py, src('make_landmask.py'), src('make_d_top_2.py'),
            tool(c, 'process_hydbas')])
  def cat    = preprocess_inputs.out[0]
  def d_top_2 = preprocess_inputs.out[1]

  map_glob(Channel.value(c.map_glob), cat, d_top_2, [tool(c, 'datamap')])
  def dm = map_glob.out[0]

  def ggm_args = Channel.value(c.mf6_input.mf6ggm_args as String)
  def mf6cfg   = Channel.value(c.mf6)
  mf6_input_ss(dm, fl, inp(c, 'steady-state'), cfg(c, 'mf6ggm_ss.inp'), cfg(c, 'mf6_mod_ss.inp'), ggm_args, mf6ggm)

  def ss_in = mf6_input_ss.out.tree
  mf6_ss(ss_in, [], simv(c, 'steady-state'), solutions(ss_in, c, 'steady-state'), mf6cfg, mf6exe)
  def ss = mf6_tree_ss(ss_in, mf6_ss.out.overlay.collect(), 'steady-state')
  def prev = ss

  if (phases.contains('spin-up')) {
    mf6_input_spu(dm, fl, inp(c, 'spin-up'), cfg(c, 'mf6ggm_spu.inp'), cfg(c, 'mf6_mod_spu.inp'), ggm_args, mf6ggm)
    def spu_in = mf6_input_spu.out.tree
    mf6_spu(spu_in, prev, simv(c, 'spin-up'), solutions(spu_in, c, 'spin-up'), mf6cfg, mf6exe)
    prev = mf6_tree_spu(spu_in, mf6_spu.out.overlay.collect(), 'spin-up')
  }
  def tr = null
  if (phases.contains('transient')) {
    mf6_input_tr(dm, fl, inp(c, 'transient'), cfg(c, 'mf6ggm_tr.inp'), cfg(c, 'mf6_mod_tr.inp'), ggm_args, mf6ggm)
    def tr_in = mf6_input_tr.out.tree
    mf6_tr(tr_in, prev, simv(c, 'transient'), solutions(tr_in, c, 'transient'), mf6cfg, mf6exe)
    tr = mf6_tree_tr(tr_in, mf6_tr.out.overlay.collect(), 'transient')
  }

  def post_phases = c.post_phases as List
  if (post_phases.contains('steady-state')) post_ss(ss, fl, inp(c, 'steady-state'), post_inps(c, 'steady-state'), mf6ggmpost)
  if (post_phases.contains('transient'))    post_tr(tr, fl, inp(c, 'transient'), post_inps(c, 'transient'), mf6ggmpost)
}


  // return   // DEV: delete this line to run the rest of the pipeline again
