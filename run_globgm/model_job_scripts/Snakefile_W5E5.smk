import os
SIMULATION = config["simulation"]
OUTPUTDIRECTORY = config["outputDirectory"]
RUN_GLOBGM_DIR = config["run_globgm_dir"]

MODELROOT_TR=f"{OUTPUTDIRECTORY}/{SIMULATION}/tr"
SLURMDIR_TR=f"{MODELROOT_TR}/slurm_logs"

STARTYEAR = 1960
ENDYEAR = 1962

rule all:
    input:
        f"{SLURMDIR_TR}/sim_done"

#TODO once a fuill run has been tested adda clean up part to the post processing script to get rid of
#unecssary files
#TODO make sure sta are fraction is on for transient
#This won't run without the initial steady state folder being present but this will probably change is we use a singel initial condition
#TODO change post processing to genoa fat node
rule setup_simulation:
    output:
        outFile=f"{SLURMDIR_TR}/1_prepare_model_partitioning/setup_complete"
    params:
        dir1 = MODELROOT_TR,
        dir2 = f"{SLURMDIR_TR}/1_prepare_model_partitioning",
        dir3 = f"{SLURMDIR_TR}/2_write_model_input",
        dir4 = f"{SLURMDIR_TR}/3_run_model",
        dir5 = f"{SLURMDIR_TR}/4_post-processing",

        model_input_dir = f"{RUN_GLOBGM_DIR}/model_input",
        modelroot_tr = MODELROOT_TR,
    shell:
        '''
        mkdir -p {params.dir1} {params.dir2} {params.dir3} {params.dir4} {params.dir5}
        cp -r {params.model_input_dir} {params.modelroot_tr}
        touch {output.outFile}
        '''

rule prepare_model_partitioning:
    input:
        rules.setup_simulation.output.outFile
    output:
        outFile=f"{SLURMDIR_TR}/1_prepare_model_partitioning/prepare_model_partitioning_complete"

    params:
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/1_prepare_model_partitioning/01_prep_model_part.slurm",
        slurm_log_file=f"{SLURMDIR_TR}/1_prepare_model_partitioning/1_prep_model_part.out"

    shell:
        '''
        sbatch -o {params.slurm_log_file} {params.run_script} {MODELROOT_TR} {output.outFile}
        while [ ! -e {output.outFile} ]; do
             sleep 10
        done
        '''

rule write_model_forcing_setup:
    input:
        rules.prepare_model_partitioning.output.outFile
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/write_model_input_setup_complete"

    params:
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/2_write_model_input/tr/_writeInput_ini.slurm",
        slurm_log_file=f"{SLURMDIR_TR}/2_write_model_input/_writeInput/writeInput_ini.out"
    shell:
        '''
        sbatch -o {params.slurm_log_file} {params.run_script} {MODELROOT_TR} {STARTYEAR} {ENDYEAR} {output.outFile}
        while [ ! -e {output.outFile} ]; do
            sleep 10
        done
        '''

rule write_model_forcing:
    input:
        rules.write_model_forcing_setup.output.outFile
    output:
        outFile1=f"{SLURMDIR_TR}/2_write_model_input/_writeModels_forcing_complete_1",
        outFile2=f"{SLURMDIR_TR}/2_write_model_input/_writeModels_forcing_complete_2"

    params:
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/2_write_model_input/tr/_writeInput.slurm ",
        slurm_log_file=f"{SLURMDIR_TR}/2_write_model_input/_writeInput/_writeInput_%a.out"

    shell:
        '''
        sbatch -o {params.slurm_log_file} --array=1-2 {params.run_script} {MODELROOT_TR} {STARTYEAR} {ENDYEAR} {output.outFile1}
        while [ ! -e {output.outFile1} ] || [ ! -e {output.outFile2} ]; do
            sleep 10
        done
        '''
rule write_model_input_setup:
    input:
        rules.write_model_forcing.output.outFile1,
        rules.write_model_forcing.output.outFile2
    output:
        outFile1=f"{SLURMDIR_TR}/2_write_model_input/_writeModels_tr_setup_complete1",
        outFile2=f"{SLURMDIR_TR}/2_write_model_input/_writeModels_tr_setup_complete2",
        outFile3=f"{SLURMDIR_TR}/2_write_model_input/_writeModels_tr_setup_complete3"

    params:
        nSpin=1,
        startyear1=1960, endyear1=1960, label1=1,
        startyear2=1961, endyear2=1961, label2=2,
        startyear3=1962, endyear3=1962, label3=3,
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/2_write_model_input/tr/_writeModels_setup_tr.slurm",
        slurm_log_file1=f"{SLURMDIR_TR}/2_write_model_input/_writeModels/_setup_1.out",
        slurm_log_file2=f"{SLURMDIR_TR}/2_write_model_input/_writeModels/_setup_2.out",
        slurm_log_file3=f"{SLURMDIR_TR}/2_write_model_input/_writeModels/_setup_3.out"

    shell:
        '''
        sbatch -o {params.slurm_log_file1} {params.run_script} {MODELROOT_TR} {params.startyear1} {params.endyear1} {params.nSpin} {output.outFile1} {params.label1}
        sbatch -o {params.slurm_log_file2} {params.run_script} {MODELROOT_TR} {params.startyear2} {params.endyear2} {params.nSpin} {output.outFile2} {params.label2}
        sbatch -o {params.slurm_log_file3} {params.run_script} {MODELROOT_TR} {params.startyear3} {params.endyear3} {params.nSpin} {output.outFile3} {params.label3}
        while [ ! -e {output.outFile1} ] || [ ! -e {output.outFile2} ] || [ ! -e {output.outFile3} ]; do
            sleep 10
        done
        '''

#Run solution 3 for the set 1
rule write_model_input_solution3:
    input:
        rules.write_model_input_setup.output.outFile1,
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/3_writeModels_tr_complete1"

    params:
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/2_write_model_input/tr/_writeModels_tr.slurm",
        slurm_log_file=f"{SLURMDIR_TR}/2_write_model_input/_writeModels/3_wMod_1.out",
        label=rules.write_model_input_setup.params.label1,
        solution=3,
        runType="start",

    shell:
        '''
        sbatch -o {params.slurm_log_file} {params.run_script} {MODELROOT_TR} {params.label} {params.solution} {params.runType} {output.outFile}
        while [ ! -e {output.outFile} ]; do
            sleep 10
        done
        '''
rule run_model_solution3:
    input:
        rules.write_model_input_solution3.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/_runModels_complete3_1",

    params:
        label=rules.write_model_input_setup.params.label1,
        runType="start",
        solution=3,
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/3_run_model/transient/mf6_s03_tr.slurm",
        slurm_log_file=f"{SLURMDIR_TR}/3_run_model/run_globgm_3_1.out"

    shell:
        '''
        sbatch -o {params.slurm_log_file} {params.run_script} {MODELROOT_TR} {params.runType} {params.solution} {STARTYEAR} {ENDYEAR} {params.label} {output.outFile}
        while [ ! -e {output.outFile} ] ; do
            sleep 10
        done
        '''
rule post_model_solution3:
    input:
        rules.run_model_solution3.output.outFile,
    output:
        outFile1=f"{SLURMDIR_TR}/4_post-processing/_post_complete3_1_wtd",
        outFile2=f"{SLURMDIR_TR}/4_post-processing/_post_complete3_1_hds",

    params:
        solution=3,
        startyear=rules.write_model_input_setup.params.startyear1,
        endyear=rules.write_model_input_setup.params.endyear1,
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/4_post-processing/transient/_zarrWriter.slurm",
        slurm_log_file1=f"{SLURMDIR_TR}/4_post-processing/_s03_zarrWriter/3_1_wtd.out",
        slurm_log_file2=f"{SLURMDIR_TR}/4_post-processing/_s03_zarrWriter/3_1_hds.out",
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_1/glob_tr"

    shell:
        '''
        sbatch --partition=genoa -o {params.slurm_log_file1} {params.run_script} {MODELROOT_TR} wtd {params.solution} {params.startyear} {params.endyear} {params.modDir} {output.outFile1}
        sbatch --partition=genoa -o {params.slurm_log_file2} {params.run_script} {MODELROOT_TR} hds {params.solution} {params.startyear} {params.endyear} {params.modDir} {output.outFile2}
        while [ ! -e {output.outFile1} ] || [ ! -e {output.outFile2} ] ; do
            sleep 10
        done
        '''

#Run solution 3 for the set 2
use rule write_model_input_solution3 as write_model_input_solution3_run2 with:
    input:
        rules.write_model_input_setup.output.outFile2,
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/3_writeModels_tr_complete2"

    params:
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/2_write_model_input/tr/_writeModels_tr.slurm",
        slurm_log_file=f"{SLURMDIR_TR}/2_write_model_input/_writeModels/3_wMod_2.out",
        label=rules.write_model_input_setup.params.label2,
        solution=3,
        runType="subRun"

use rule run_model_solution3 as run_model_solution3_run2 with:
    input:
        rules.run_model_solution3.output.outFile,
        rules.write_model_input_solution3_run2.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/_runModels_complete3_2",

    params:
        label=rules.write_model_input_setup.params.label2,
        runType="subRun",
        solution=3,
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/3_run_model/transient/mf6_s03_tr.slurm",
        slurm_log_file=f"{SLURMDIR_TR}/3_run_model/run_globgm_3_2.out"
use rule post_model_solution3 as post_model_solution3_run2 with:
    input:
        rules.run_model_solution3_run2.output.outFile,
    output:
        outFile1=f"{SLURMDIR_TR}/4_post-processing/_post_complete3_2_wtd",
        outFile2=f"{SLURMDIR_TR}/4_post-processing/_post_complete3_2_hds",

    params:
        solution=3,
        startyear=rules.write_model_input_setup.params.startyear2,
        endyear=rules.write_model_input_setup.params.endyear2,
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/4_post-processing/transient/_zarrWriter.slurm",
        slurm_log_file1=f"{SLURMDIR_TR}/4_post-processing/_s03_zarrWriter/3_2_wtd.out",
        slurm_log_file2=f"{SLURMDIR_TR}/4_post-processing/_s03_zarrWriter/3_2_hds.out",
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_2/glob_tr"

#Run solution 3 for the set 3
use rule write_model_input_solution3 as write_model_input_solution3_run3 with:
    input:
        rules.write_model_input_setup.output.outFile3,
        rules.post_model_solution3.output.outFile1,
        rules.post_model_solution3.output.outFile2,
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/3_writeModels_tr_complete3"

    params:
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/2_write_model_input/tr/_writeModels_tr.slurm",
        slurm_log_file=f"{SLURMDIR_TR}/2_write_model_input/_writeModels/3_wMod_3.out",
        label=rules.write_model_input_setup.params.label3,
        solution=3,
        runType="subRun"

use rule run_model_solution3 as run_model_solution3_run3 with:
    input:
        rules.write_model_input_solution3_run3.output.outFile,
        rules.run_model_solution3_run2.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/_runModels_complete3_3",

    params:
        label=rules.write_model_input_setup.params.label3,
        runType="subRun",
        solution=3,
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/3_run_model/transient/mf6_s03_tr.slurm",
        slurm_log_file=f"{SLURMDIR_TR}/3_run_model/run_globgm_3_3.out"
use rule post_model_solution3 as post_model_solution3_run3 with:
    input:
        rules.run_model_solution3_run3.output.outFile,
    output:
        outFile1=f"{SLURMDIR_TR}/4_post-processing/_post_complete3_3_wtd",
        outFile2=f"{SLURMDIR_TR}/4_post-processing/_post_complete3_3_hds",

    params:
        solution=3,
        startyear=rules.write_model_input_setup.params.startyear3,
        endyear=rules.write_model_input_setup.params.endyear3,
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/4_post-processing/transient/_zarrWriter.slurm",
        slurm_log_file1=f"{SLURMDIR_TR}/4_post-processing/_s03_zarrWriter/3_3_wtd.out",
        slurm_log_file2=f"{SLURMDIR_TR}/4_post-processing/_s03_zarrWriter/3_3_hds.out",
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_3/glob_tr"

# # #Run solution 4 for the set 1
use rule write_model_input_solution3 as write_model_input_solution4 with:
    input:
        rules.write_model_input_setup.output.outFile1,
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/4_writeModels_tr_complete1"

    params:
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/2_write_model_input/tr/_writeModels_tr.slurm",
        slurm_log_file=f"{SLURMDIR_TR}/2_write_model_input/_writeModels/4_wMod_1.out",
        label=rules.write_model_input_setup.params.label1,
        solution=4,
        runType="start",

use rule run_model_solution3 as run_model_solution4 with:
    input:
        rules.write_model_input_solution4.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/_runModels_complete4_1",

    params:
        label=rules.write_model_input_setup.params.label1,
        runType="start",
        solution=4,
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/3_run_model/transient/mf6_s04_tr.slurm",
        slurm_log_file=f"{SLURMDIR_TR}/3_run_model/run_globgm_4_1.out"

use rule post_model_solution3 as post_model_solution4 with:
    input:
        rules.run_model_solution4.output.outFile,
    output:
        outFile1=f"{SLURMDIR_TR}/4_post-processing/_post_complete4_1_wtd",
        outFile2=f"{SLURMDIR_TR}/4_post-processing/_post_complete4_1_hds",

    params:
        solution=4,
        startyear=rules.write_model_input_setup.params.startyear1,
        endyear=rules.write_model_input_setup.params.endyear1,
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/4_post-processing/transient/_zarrWriter.slurm",
        slurm_log_file1=f"{SLURMDIR_TR}/4_post-processing/_s04_zarrWriter/4_1_wtd.out",
        slurm_log_file2=f"{SLURMDIR_TR}/4_post-processing/_s04_zarrWriter/4_1_hds.out",
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_1/glob_tr"

# #Run solution 4 for the set 2
use rule write_model_input_solution4 as write_model_input_solution4_run2 with:
    input:
        rules.write_model_input_setup.output.outFile2,
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/4_writeModels_tr_complete2"

    params:
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/2_write_model_input/tr/_writeModels_tr.slurm",
        slurm_log_file=f"{SLURMDIR_TR}/2_write_model_input/_writeModels/4_wMod_2.out",
        label=rules.write_model_input_setup.params.label2,
        solution=4,
        runType="subRun"

use rule run_model_solution4 as run_model_solution4_run2 with:
    input:
        rules.run_model_solution4.output.outFile,
        rules.write_model_input_solution4_run2.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/_runModels_complete4_2",

    params:
        label=rules.write_model_input_setup.params.label2,
        runType="subRun",
        solution=4,
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/3_run_model/transient/mf6_s04_tr.slurm",
        slurm_log_file=f"{SLURMDIR_TR}/3_run_model/run_globgm_4_2.out"
use rule post_model_solution4 as post_model_solution4_run2 with:
    input:
        rules.run_model_solution4_run2.output.outFile,
    output:
        outFile1=f"{SLURMDIR_TR}/4_post-processing/_post_complete4_2_wtd",
        outFile2=f"{SLURMDIR_TR}/4_post-processing/_post_complete4_2_hds",

    params:
        solution=4,
        startyear=rules.write_model_input_setup.params.startyear2,
        endyear=rules.write_model_input_setup.params.endyear2,
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/4_post-processing/transient/_zarrWriter.slurm",
        slurm_log_file1=f"{SLURMDIR_TR}/4_post-processing/_s04_zarrWriter/4_2_wtd.out",
        slurm_log_file2=f"{SLURMDIR_TR}/4_post-processing/_s04_zarrWriter/4_2_hds.out",
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_2/glob_tr"
#Run solution 4 for the set 3
use rule write_model_input_solution4 as write_model_input_solution4_run3 with:
    input:
        rules.write_model_input_setup.output.outFile3,
        rules.post_model_solution4.output.outFile1,
        rules.post_model_solution4.output.outFile2,
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/4_writeModels_tr_complete3"

    params:
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/2_write_model_input/tr/_writeModels_tr.slurm",
        slurm_log_file=f"{SLURMDIR_TR}/2_write_model_input/_writeModels/4_wMod_3.out",
        label=rules.write_model_input_setup.params.label3,
        solution=4,
        runType="subRun"

use rule run_model_solution4 as run_model_solution4_run3 with:
    input:
        rules.write_model_input_solution4_run3.output.outFile,
        rules.run_model_solution4_run2.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/_runModels_complete4_3",

    params:
        label=rules.write_model_input_setup.params.label3,
        runType="subRun",
        solution=4,
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/3_run_model/transient/mf6_s04_tr.slurm",
        slurm_log_file=f"{SLURMDIR_TR}/3_run_model/run_globgm_4_3.out"
use rule post_model_solution4 as post_model_solution4_run3 with:
    input:
        rules.run_model_solution4_run3.output.outFile,
    output:
        outFile1=f"{SLURMDIR_TR}/4_post-processing/_post_complete4_3_wtd",
        outFile2=f"{SLURMDIR_TR}/4_post-processing/_post_complete4_3_hds",

    params:
        solution=4,
        startyear=rules.write_model_input_setup.params.startyear3,
        endyear=rules.write_model_input_setup.params.endyear3,
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/4_post-processing/transient/_zarrWriter.slurm",
        slurm_log_file1=f"{SLURMDIR_TR}/4_post-processing/_s04_zarrWriter/4_3_wtd.out",
        slurm_log_file2=f"{SLURMDIR_TR}/4_post-processing/_s04_zarrWriter/4_3_hds.out",
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_3/glob_tr"
# # Run solution 2 for the set 1
use rule write_model_input_solution3 as write_model_input_solution2 with:
    input:
        rules.write_model_input_setup.output.outFile1,
    output: 
        outFile=f"{SLURMDIR_TR}/2_write_model_input/2_writeModels_tr_complete1"

    params:
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/2_write_model_input/tr/_writeModels_tr.slurm",
        slurm_log_file=f"{SLURMDIR_TR}/2_write_model_input/_writeModels/2_wMod_1.out",
        label=rules.write_model_input_setup.params.label1,
        solution=2,
        runType="start",

use rule run_model_solution3 as run_model_solution2 with:
    input:
        rules.write_model_input_solution2.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/_runModels_complete2_1",

    params:
        label=rules.write_model_input_setup.params.label1,
        runType="start",
        solution=2,
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/3_run_model/transient/mf6_s02_tr.slurm",
        slurm_log_file=f"{SLURMDIR_TR}/3_run_model/run_globgm_2_1.out"

use rule post_model_solution3 as post_model_solution2 with:
    input:
        rules.run_model_solution2.output.outFile,
    output:
        outFile1=f"{SLURMDIR_TR}/4_post-processing/_post_complete2_1_wtd",
        outFile2=f"{SLURMDIR_TR}/4_post-processing/_post_complete2_1_hds",

    params:
        solution=2,
        startyear=rules.write_model_input_setup.params.startyear1,
        endyear=rules.write_model_input_setup.params.endyear1,
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/4_post-processing/transient/_zarrWriter.slurm",
        slurm_log_file1=f"{SLURMDIR_TR}/4_post-processing/_s02_zarrWriter/2_1_wtd.out",
        slurm_log_file2=f"{SLURMDIR_TR}/4_post-processing/_s02_zarrWriter/2_1_hds.out",
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_1/glob_tr"

# #Run solution 2 for the set 2
use rule write_model_input_solution2 as write_model_input_solution2_run2 with:
    input:
        rules.write_model_input_setup.output.outFile2,
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/2_writeModels_tr_complete2"

    params:
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/2_write_model_input/tr/_writeModels_tr.slurm",
        slurm_log_file=f"{SLURMDIR_TR}/2_write_model_input/_writeModels/2_wMod_2.out",
        label=rules.write_model_input_setup.params.label2,
        solution=2,
        runType="subRun"

use rule run_model_solution2 as run_model_solution2_run2 with:
    input:
        rules.run_model_solution2.output.outFile,
        rules.write_model_input_solution2_run2.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/_runModels_complete2_2",

    params:
        label=rules.write_model_input_setup.params.label2,
        runType="subRun",
        solution=2,
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/3_run_model/transient/mf6_s02_tr.slurm",
        slurm_log_file=f"{SLURMDIR_TR}/3_run_model/run_globgm_2_2.out"
use rule post_model_solution2 as post_model_solution2_run2 with:
    input:
        rules.run_model_solution2_run2.output.outFile,
    output:
        outFile1=f"{SLURMDIR_TR}/4_post-processing/_post_complete2_2_wtd",
        outFile2=f"{SLURMDIR_TR}/4_post-processing/_post_complete2_2_hds",

    params:
        solution=2,
        startyear=rules.write_model_input_setup.params.startyear2,
        endyear=rules.write_model_input_setup.params.endyear2,
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/4_post-processing/transient/_zarrWriter.slurm",
        slurm_log_file1=f"{SLURMDIR_TR}/4_post-processing/_s02_zarrWriter/2_2_wtd.out",
        slurm_log_file2=f"{SLURMDIR_TR}/4_post-processing/_s02_zarrWriter/2_2_hds.out",
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_2/glob_tr"
#Run solution 2 for the set 3
use rule write_model_input_solution2 as write_model_input_solution2_run3 with:
    input:
        rules.write_model_input_setup.output.outFile3,
        rules.post_model_solution2.output.outFile1,
        rules.post_model_solution2.output.outFile2,
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/2_writeModels_tr_complete3"

    params:
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/2_write_model_input/tr/_writeModels_tr.slurm",
        slurm_log_file=f"{SLURMDIR_TR}/2_write_model_input/_writeModels/2_wMod_3.out",
        label=rules.write_model_input_setup.params.label3,
        solution=2,
        runType="subRun"

use rule run_model_solution2 as run_model_solution2_run3 with:
    input:
        rules.write_model_input_solution2_run3.output.outFile,
        rules.run_model_solution2_run2.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/_runModels_complete2_3",

    params:
        label=rules.write_model_input_setup.params.label3,
        runType="subRun",
        solution=2,
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/3_run_model/transient/mf6_s02_tr.slurm",
        slurm_log_file=f"{SLURMDIR_TR}/3_run_model/run_globgm_2_3.out"
use rule post_model_solution2 as post_model_solution2_run3 with:
    input:
        rules.run_model_solution2_run3.output.outFile,
    output:
        outFile1=f"{SLURMDIR_TR}/4_post-processing/_post_complete2_3_wtd",
        outFile2=f"{SLURMDIR_TR}/4_post-processing/_post_complete2_3_hds",

    params:
        solution=2,
        startyear=rules.write_model_input_setup.params.startyear3,
        endyear=rules.write_model_input_setup.params.endyear3,
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/4_post-processing/transient/_zarrWriter.slurm",
        slurm_log_file1=f"{SLURMDIR_TR}/4_post-processing/_s02_zarrWriter/2_3_wtd.out",
        slurm_log_file2=f"{SLURMDIR_TR}/4_post-processing/_s02_zarrWriter/2_3_hds.out",
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_3/glob_tr"
# Run solution 1 for the set 1
use rule write_model_input_solution3 as write_model_input_solution1 with:
    input:
        rules.write_model_input_setup.output.outFile1,
    output: 
        outFile=f"{SLURMDIR_TR}/2_write_model_input/1_writeModels_tr_complete1"

    params:
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/2_write_model_input/tr/_writeModels_tr.slurm",
        slurm_log_file=f"{SLURMDIR_TR}/2_write_model_input/_writeModels/1_wMod_1.out",
        label=rules.write_model_input_setup.params.label1,
        solution=1,
        runType="start",

use rule run_model_solution3 as run_model_solution1 with:
    input:
        rules.write_model_input_solution1.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/_runModels_complete1_1",

    params:
        label=rules.write_model_input_setup.params.label1,
        runType="start",
        solution=1,
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/3_run_model/transient/mf6_s01_tr.slurm",
        slurm_log_file=f"{SLURMDIR_TR}/3_run_model/run_globgm_1_1.out"

use rule post_model_solution3 as post_model_solution1 with:
    input:
        rules.run_model_solution1.output.outFile,
    output:
        outFile1=f"{SLURMDIR_TR}/4_post-processing/_post_complete1_1_wtd",
        outFile2=f"{SLURMDIR_TR}/4_post-processing/_post_complete1_1_hds",

    params:
        solution=1,
        startyear=rules.write_model_input_setup.params.startyear1,
        endyear=rules.write_model_input_setup.params.endyear1,
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/4_post-processing/transient/_zarrWriter.slurm",
        slurm_log_file1=f"{SLURMDIR_TR}/4_post-processing/_s01_zarrWriter/1_1_wtd.out",
        slurm_log_file2=f"{SLURMDIR_TR}/4_post-processing/_s01_zarrWriter/1_1_hds.out",
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_1/glob_tr"

# #Run solution 1 for the set 2
use rule write_model_input_solution1 as write_model_input_solution1_run2 with:
    input:
        rules.write_model_input_setup.output.outFile2,
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/1_writeModels_tr_complete2"

    params:
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/2_write_model_input/tr/_writeModels_tr.slurm",
        slurm_log_file=f"{SLURMDIR_TR}/2_write_model_input/_writeModels/1_wMod_2.out",
        label=rules.write_model_input_setup.params.label2,
        solution=1,
        runType="subRun"

use rule run_model_solution1 as run_model_solution1_run2 with:
    input:
        rules.run_model_solution1.output.outFile,
        rules.write_model_input_solution1_run2.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/_runModels_complete1_2",

    params:
        label=rules.write_model_input_setup.params.label2,
        runType="subRun",
        solution=1,
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/3_run_model/transient/mf6_s01_tr.slurm",
        slurm_log_file=f"{SLURMDIR_TR}/3_run_model/run_globgm_1_2.out"
use rule post_model_solution1 as post_model_solution1_run2 with:
    input:
        rules.run_model_solution1_run2.output.outFile,
    output:
        outFile1=f"{SLURMDIR_TR}/4_post-processing/_post_complete1_2_wtd",
        outFile2=f"{SLURMDIR_TR}/4_post-processing/_post_complete1_2_hds",

    params:
        solution=1,
        startyear=rules.write_model_input_setup.params.startyear2,
        endyear=rules.write_model_input_setup.params.endyear2,
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/4_post-processing/transient/_zarrWriter.slurm",
        slurm_log_file1=f"{SLURMDIR_TR}/4_post-processing/_s01_zarrWriter/1_2_wtd.out",
        slurm_log_file2=f"{SLURMDIR_TR}/4_post-processing/_s01_zarrWriter/1_2_hds.out",
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_2/glob_tr"
#Run solution 1 for the set 3
use rule write_model_input_solution1 as write_model_input_solution1_run3 with:
    input:
        rules.write_model_input_setup.output.outFile3,
        rules.post_model_solution1.output.outFile1,
        rules.post_model_solution1.output.outFile2,
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/1_writeModels_tr_complete3"

    params:
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/2_write_model_input/tr/_writeModels_tr.slurm",
        slurm_log_file=f"{SLURMDIR_TR}/2_write_model_input/_writeModels/1_wMod_3.out",
        label=rules.write_model_input_setup.params.label3,
        solution=1,
        runType="subRun"

use rule run_model_solution1 as run_model_solution1_run3 with:
    input:
        rules.write_model_input_solution1_run3.output.outFile,
        rules.run_model_solution1_run2.output.outFile,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/_runModels_complete1_3",

    params:
        label=rules.write_model_input_setup.params.label3,
        runType="subRun",
        solution=1,
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/3_run_model/transient/mf6_s01_tr.slurm",
        slurm_log_file=f"{SLURMDIR_TR}/3_run_model/run_globgm_1_3.out"
use rule post_model_solution1 as post_model_solution1_run3 with:
    input:
        rules.run_model_solution1_run3.output.outFile,
    output:
        outFile1=f"{SLURMDIR_TR}/4_post-processing/_post_complete1_3_wtd",
        outFile2=f"{SLURMDIR_TR}/4_post-processing/_post_complete1_3_hds",

    params:
        solution=1,
        startyear=rules.write_model_input_setup.params.startyear3,
        endyear=rules.write_model_input_setup.params.endyear3,
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/4_post-processing/transient/_zarrWriter.slurm",
        slurm_log_file1=f"{SLURMDIR_TR}/4_post-processing/_s01_zarrWriter/1_3_wtd.out",
        slurm_log_file2=f"{SLURMDIR_TR}/4_post-processing/_s01_zarrWriter/1_3_hds.out",
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_3/glob_tr"

rule wrap_up:
    input:
        rules.post_model_solution3.output.outFile1,      
        rules.post_model_solution3.output.outFile2,      
        rules.post_model_solution3_run2.output.outFile1, 
        rules.post_model_solution3_run2.output.outFile2, 
        rules.post_model_solution3_run3.output.outFile1, 
        rules.post_model_solution3_run3.output.outFile2, 
        
        rules.post_model_solution4.output.outFile1,
        rules.post_model_solution4.output.outFile2,
        rules.post_model_solution4_run2.output.outFile1,
        rules.post_model_solution4_run2.output.outFile2,
        rules.post_model_solution4_run3.output.outFile1,
        rules.post_model_solution4_run3.output.outFile2,
        
        rules.post_model_solution2.output.outFile1,      
        rules.post_model_solution2.output.outFile2,      
        rules.post_model_solution2_run2.output.outFile1, 
        rules.post_model_solution2_run2.output.outFile2, 
        rules.post_model_solution2_run3.output.outFile1, 
        rules.post_model_solution2_run3.output.outFile2, 
        
        rules.post_model_solution1.output.outFile1,
        rules.post_model_solution1.output.outFile2,
        rules.post_model_solution1_run2.output.outFile1,
        rules.post_model_solution1_run2.output.outFile2,
        rules.post_model_solution1_run3.output.outFile1,
        rules.post_model_solution1_run3.output.outFile2,
    output:
        outFile=f"{SLURMDIR_TR}/sim_done"
    shell:
        '''
        touch {output.outFile}
        '''

