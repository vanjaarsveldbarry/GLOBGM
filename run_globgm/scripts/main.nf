include { preprocess_inputs; map_glob; phase as ss; phase as spu; phase as tr } from './stages'

def src(name) { file("${projectDir.parent.parent}/src/python/${name}") }
def raster(c, name) { file("${c.inputs_dir}/${c[name]}") }

def generate() {
  def p = ['python', src('globgm_config.py'), 'run', params.config, params.output].execute()
  p.waitForProcessOutput(System.out, System.err)
  if (p.exitValue() != 0) error('globgm_config.py failed')
  new groovy.json.JsonSlurper().parse(file("${params.output}/config/params.json"))
}

// Steady state, then spin-up and transient, each from the previous phase's heads.
workflow {
  def c = generate()
  def raster_py = src('globgm_raster.py')   // imported by the other scripts

  preprocess_inputs(c.preprocess_inputs, raster(c, 'ldd'), raster(c, 'lakes'), raster(c, 'dem'), raster(c, 'confining'),
    file("${c.config_dir}/fields.json"),
    [raster_py, src('make_subbasins.py'), src('make_d_top_2.py'), src('make_fields.py')])
  def fl = preprocess_inputs.out.fields

  
  map_glob(c.map_glob, preprocess_inputs.out.subbasins, preprocess_inputs.out.d_top_2, [file("${c.binaries}/datamap")])

  def dm = map_glob.out.datamap
  def prev = ss(c, 'steady-state', dm, fl, [])
  if ('spin-up' in c.phases) prev = spu(c, 'spin-up', dm, fl, prev)
  if ('transient' in c.phases) tr(c, 'transient', dm, fl, prev)
}

  // return   // hack: stop a÷fter preprocess_inputs; delete to run the rest