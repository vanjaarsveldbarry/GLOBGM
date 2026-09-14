// GLOBGM on one window: the four stages as processes in stages.nf, a
// separate file because Nextflow invokes a process once per file unless it
// is included under an alias, and a file cannot include itself. The
// workflow first runs globgm_config.py on params.config (globgm.toml), which
// writes the .inp files and params.json under <output>/config and empties
// the rest of the output root; every value below then comes from that
// params.json. Every edge carries the files themselves; the products are
// published under the output root.

include { map_glob; fields } from './stages'
include { mf6_input as mf6_input_ss; mf6_input as mf6_input_spu; mf6_input as mf6_input_tr } from './stages'
include { mf6 as mf6_ss; mf6 as mf6_spu; mf6 as mf6_tr } from './stages'
include { post as post_ss; post as post_tr } from './stages'

def src(name)       { file("${projectDir.parent.parent}/src/python/${name}") }
def cfg(c, name)    { file("${c.config_dir}/${name}") }
def raster(c, name) { file("${c.inputs_dir}/${name}") }
def tool(c, name)   { file("${c.binaries}/${name}") }
def inp(c, ph)      { Channel.value([c.sim[ph] as String, ph as String]) }
def simv(c, ph)     { Channel.value([ph as String, c.nam[ph] as String, c.hds[ph] as String]) }

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
// from the steady-state heads when there is no spin-up). The spin-up saves
// heads for its last period only, as the transient's initial condition;
// mf6ggmpost reads periods by position, so it is never post-processed.
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

  map_glob(Channel.value(c.map_glob), ldd, dem, confining,
           [raster_py, src('make_landmask.py'), src('make_tiles.py'), src('make_d_top_2.py'),
            tool(c, 'process_hydbas'), tool(c, 'datamap')])
  def dm = map_glob.out[0]
  def fl = c.fields_source == 'synthetic'
    ? fields(cfg(c, 'synthetic.json'), ldd, dem, confining, [raster_py, src('make_synthetic_fields.py')])
    : Channel.value(file(c.fields_source))

  def ggm_args = Channel.value(c.mf6_input.mf6ggm_args as String)
  def mf6cfg   = Channel.value(c.mf6)
  mf6_input_ss(dm, fl, inp(c, 'steady-state'), cfg(c, 'mf6ggm_ss.inp'), cfg(c, 'mf6_mod_ss.inp'), ggm_args, mf6ggm)
  mf6_ss(mf6_input_ss.out.tree, [], simv(c, 'steady-state'), mf6cfg, mf6exe)
  def ss = mf6_ss.out.tree
  def prev = ss
  if (phases.contains('spin-up')) {
    mf6_input_spu(dm, fl, inp(c, 'spin-up'), cfg(c, 'mf6ggm_spu.inp'), cfg(c, 'mf6_mod_spu.inp'), ggm_args, mf6ggm)
    mf6_spu(mf6_input_spu.out.tree, prev, simv(c, 'spin-up'), mf6cfg, mf6exe)
    prev = mf6_spu.out.tree
  }
  def tr = null
  if (phases.contains('transient')) {
    mf6_input_tr(dm, fl, inp(c, 'transient'), cfg(c, 'mf6ggm_tr.inp'), cfg(c, 'mf6_mod_tr.inp'), ggm_args, mf6ggm)
    mf6_tr(mf6_input_tr.out.tree, prev, simv(c, 'transient'), mf6cfg, mf6exe)
    tr = mf6_tr.out.tree
  }

  def post_phases = c.post_phases as List
  if (post_phases.contains('steady-state')) post_ss(ss, fl, inp(c, 'steady-state'), cfg(c, 'mf6ggmpost_ss.inp'), mf6ggmpost)
  if (post_phases.contains('transient'))    post_tr(tr, fl, inp(c, 'transient'), cfg(c, 'mf6ggmpost_tr.inp'), mf6ggmpost)
}
