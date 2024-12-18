import os
SIMULATION = config["simulation"]
OUTPUTDIRECTORY = config["outputDirectory"]
RUN_GLOBGM_DIR = config["run_globgm_dir"]

MODELROOT_TR=f"{OUTPUTDIRECTORY}/{SIMULATION}/tr_no_pump"
SLURMDIR_TR=f"{MODELROOT_TR}/slurm_logs"
DATA_DIR = config["data_dir"]

STARTYEAR = 1960
ENDYEAR = 1960

rule all:
    input:
        f"{SLURMDIR_TR}/sim_done"

#TODO once a fuill run has been tested adda clean up part to the post processing script to get rid of
#unecssary files
#TODO make sure sta are fraction is on for transient
#This won't run without the initial steady state folder being present but this will probably change is we use a singel initial condition
#TODO change post processing to genoa fat node
#check that abstraction is truely off for this part
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
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/1_prepare_model_partitioning/1_prep_model_part.slurm",
        slurm_log_file=f"{SLURMDIR_TR}/1_prepare_model_partitioning/1_prep_model_part.out"

    shell:
        '''
        sbatch -o {params.slurm_log_file} {params.run_script} {MODELROOT_TR} {DATA_DIR} {output.outFile}
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
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/2_write_model_input/tr/_writeInput_setup.slurm",
        slurm_log_file=f"{SLURMDIR_TR}/2_write_model_input/_writeInput/writeInput_setup.out"
    shell:
        '''
        sbatch -o {params.slurm_log_file} {params.run_script} {MODELROOT_TR} {STARTYEAR} {ENDYEAR} {DATA_DIR} {output.outFile}
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
        sbatch -o {params.slurm_log_file} --array=1-2 {params.run_script} {MODELROOT_TR} {STARTYEAR} {ENDYEAR} {DATA_DIR} {output.outFile1}
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

    params:
        nSpin=1,
        startyear1=1960, endyear1=1960, label1=1,
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/2_write_model_input/tr/_writeModels_setup_tr.slurm",
        slurm_log_file1=f"{SLURMDIR_TR}/2_write_model_input/_writeModels/_setup_1.out",

    shell:
        '''
        sbatch -o {params.slurm_log_file1} {params.run_script} {MODELROOT_TR} {params.startyear1} {params.endyear1} {params.nSpin} {output.outFile1} {DATA_DIR} {params.label1} {params.iniStatesFolder}
        while [ ! -e {output.outFile1} ]; do
            sleep 10
        done
        '''
rule write_model_input_maps:
    input:
        rules.write_model_input_setup.output.outFile1,
    output:
        outFile=f"{SLURMDIR_TR}/2_write_model_input/_writeModels_map_complete"

    params:
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/2_write_model_input/tr/_writeModels_map.slurm",
        slurm_log_file=f"{SLURMDIR_TR}/2_write_model_input/_writeModels/_writeModels_map.out",
        label=rules.write_model_input_setup.params.label1,
        solution=3,
        runType="start",

    shell:
        '''
        sbatch -o {params.slurm_log_file} {params.run_script} {MODELROOT_TR} {params.label} {params.solution} {params.runType} {DATA_DIR} {output.outFile}
        while [ ! -e {output.outFile} ]; do
            sleep 10
        done
        '''

# #Run solution 3 for the set 1
rule write_model_input_solution3:
    input:
        rules.write_model_input_maps.output.outFile,
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
        sbatch -o {params.slurm_log_file} {params.run_script} {MODELROOT_TR} {params.label} {params.solution} {params.runType} {DATA_DIR} {output.outFile}
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
        sbatch -o {params.slurm_log_file} {params.run_script} {MODELROOT_TR} {params.runType} {params.solution} {STARTYEAR} {ENDYEAR} {params.label} {DATA_DIR} {output.outFile}
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
        sbatch --partition=genoa -o {params.slurm_log_file1} {params.run_script} {MODELROOT_TR} wtd {params.solution} {params.startyear} {params.endyear} {params.modDir} {DATA_DIR} {output.outFile1}
        sbatch --partition=genoa -o {params.slurm_log_file2} {params.run_script} {MODELROOT_TR} hds {params.solution} {params.startyear} {params.endyear} {params.modDir} {DATA_DIR} {output.outFile2}
        while [ ! -e {output.outFile1} ] || [ ! -e {output.outFile2} ] ; do
            sleep 10
        done
        '''

# # #Run solution 4 for the set 1
use rule write_model_input_solution3 as write_model_input_solution4 with:
    input:
        rules.write_model_input_maps.output.outFile,
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


# Run solution 2 for the set 1
use rule write_model_input_solution3 as write_model_input_solution2 with:
    input:
        rules.write_model_input_maps.output.outFile,
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

# Run solution 1 for the set 1
use rule write_model_input_solution3 as write_model_input_solution1 with:
    input:
        rules.write_model_input_maps.output.outFile,
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


################################################################################################
# RUN REPEATS
################################################################################################
use rule run_model_solution3 as run_model_solution3_rep with:
    input:
        rules.post_model_solution4.output.outFile1,
        rules.post_model_solution4.output.outFile2,
        rules.post_model_solution3.output.outFile1,
        rules.post_model_solution3.output.outFile2,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/_runModels_complete3_1_rep",

    params:
        label=rules.write_model_input_setup.params.label1,
        runType="subRun",
        solution=3,
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/3_run_model/transient/mf6_s03_tr.slurm",
        slurm_log_file=f"{SLURMDIR_TR}/3_run_model/run_globgm_3_1_rep.out"

use rule post_model_solution3 as post_model_solution3_rep with:
    input:
        rules.run_model_solution3_rep.output.outFile,
    output:
        outFile1=f"{SLURMDIR_TR}/4_post-processing/_post_complete3_1_wtd_rep",
        outFile2=f"{SLURMDIR_TR}/4_post-processing/_post_complete3_1_hds_rep",

    params:
        solution=3,
        startyear=rules.write_model_input_setup.params.startyear1,
        endyear=rules.write_model_input_setup.params.endyear1,
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/4_post-processing/transient/_zarrWriter.slurm",
        slurm_log_file1=f"{SLURMDIR_TR}/4_post-processing/_s03_zarrWriter/3_1_wtd_rep.out",
        slurm_log_file2=f"{SLURMDIR_TR}/4_post-processing/_s03_zarrWriter/3_1_hds_rep.out",
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_1/glob_tr"

use rule run_model_solution4 as run_model_solution4_rep with:
    input:
        rules.post_model_solution4.output.outFile1,
        rules.post_model_solution4.output.outFile2,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/_runModels_complete4_1_rep",

    params:
        label=rules.write_model_input_setup.params.label1,
        runType="subRun",
        solution=4,
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/3_run_model/transient/mf6_s04_tr.slurm",
        slurm_log_file=f"{SLURMDIR_TR}/3_run_model/run_globgm_4_1_rep.out"

use rule post_model_solution4 as post_model_solution4_rep with:
    input:
        rules.run_model_solution4_rep.output.outFile,
    output:
        outFile1=f"{SLURMDIR_TR}/4_post-processing/_post_complete4_1_wtd_rep",
        outFile2=f"{SLURMDIR_TR}/4_post-processing/_post_complete4_1_hds_rep",

    params:
        solution=4,
        startyear=rules.write_model_input_setup.params.startyear1,
        endyear=rules.write_model_input_setup.params.endyear1,
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/4_post-processing/transient/_zarrWriter.slurm",
        slurm_log_file1=f"{SLURMDIR_TR}/4_post-processing/_s04_zarrWriter/4_1_wtd_rep.out",
        slurm_log_file2=f"{SLURMDIR_TR}/4_post-processing/_s04_zarrWriter/4_1_hds_rep.out",
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_1/glob_tr"
use rule run_model_solution2 as run_model_solution2_rep with:
    input:
        rules.post_model_solution4.output.outFile1,
        rules.post_model_solution4.output.outFile2,
        rules.post_model_solution2.output.outFile1,
        rules.post_model_solution2.output.outFile2,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/_runModels_complete2_1_rep",

    params:
        label=rules.write_model_input_setup.params.label1,
        runType="subRun",
        solution=2,
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/3_run_model/transient/mf6_s02_tr.slurm",
        slurm_log_file=f"{SLURMDIR_TR}/3_run_model/run_globgm_2_1_rep.out"

use rule post_model_solution2 as post_model_solution2_rep with:
    input:
        rules.run_model_solution2_rep.output.outFile,
    output:
        outFile1=f"{SLURMDIR_TR}/4_post-processing/_post_complete2_1_wtd_rep",
        outFile2=f"{SLURMDIR_TR}/4_post-processing/_post_complete2_1_hds_rep",

    params:
        solution=2,
        startyear=rules.write_model_input_setup.params.startyear1,
        endyear=rules.write_model_input_setup.params.endyear1,
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/4_post-processing/transient/_zarrWriter.slurm",
        slurm_log_file1=f"{SLURMDIR_TR}/4_post-processing/_s02_zarrWriter/2_1_wtd_rep.out",
        slurm_log_file2=f"{SLURMDIR_TR}/4_post-processing/_s02_zarrWriter/2_1_hds_rep.out",
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_1/glob_tr"
use rule run_model_solution1 as run_model_solution1_rep with:
    input:
        rules.post_model_solution4.output.outFile1,
        rules.post_model_solution4.output.outFile2,
        rules.post_model_solution1.output.outFile1,
        rules.post_model_solution1.output.outFile2,
    output:
        outFile=f"{SLURMDIR_TR}/3_run_model/_runModels_complete1_1_rep",

    params:
        label=rules.write_model_input_setup.params.label1,
        runType="subRun",
        solution=1,
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/3_run_model/transient/mf6_s01_tr.slurm",
        slurm_log_file=f"{SLURMDIR_TR}/3_run_model/run_globgm_1_1_rep.out"

use rule post_model_solution1 as post_model_solution1_rep with:
    input:
        rules.run_model_solution1_rep.output.outFile,
    output:
        outFile1=f"{SLURMDIR_TR}/4_post-processing/_post_complete1_1_wtd_rep",
        outFile2=f"{SLURMDIR_TR}/4_post-processing/_post_complete1_1_hds_rep",

    params:
        solution=1,
        startyear=rules.write_model_input_setup.params.startyear1,
        endyear=rules.write_model_input_setup.params.endyear1,
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/4_post-processing/transient/_zarrWriter.slurm",
        slurm_log_file1=f"{SLURMDIR_TR}/4_post-processing/_s01_zarrWriter/1_1_wtd_rep.out",
        slurm_log_file2=f"{SLURMDIR_TR}/4_post-processing/_s01_zarrWriter/1_1_hds_rep.out",
        modDir=f"{MODELROOT_TR}/mf6_mod/mf6_mod_1/glob_tr"

rule wrap_up:
    input:
        rules.post_model_solution3_rep.output.outFile1,
        rules.post_model_solution4_rep.output.outFile1,
        rules.post_model_solution2_rep.output.outFile1,
        rules.post_model_solution1_rep.output.outFile1,

        rules.post_model_solution3_rep.output.outFile2,
        rules.post_model_solution4_rep.output.outFile2,
        rules.post_model_solution2_rep.output.outFile2,
        rules.post_model_solution1_rep.output.outFile2,
    output:
        outFile=f"{SLURMDIR_TR}/sim_done"
    shell:
        '''
        touch {output.outFile}
        '''