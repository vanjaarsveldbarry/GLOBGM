import os
SIMULATION = config["simulation"]
OUTPUTDIRECTORY = config["outputDirectory"]
RUN_GLOBGM_DIR = config["run_globgm_dir"]
DATA_DIR = config["data_dir"]
CALIB_STR = config["calib_str"]

MODELROOT_SS=f"{OUTPUTDIRECTORY}/{CALIB_STR}/{SIMULATION}/ss"
SLURMDIR_SS=f"{MODELROOT_SS}/slurm_logs"
SAVEDIR="/scratch-shared/bvjaarsv/calibrationOut"

rule all:
    input:
        f"{OUTPUTDIRECTORY}/{CALIB_STR}_done"

rule setup_simulation:
    output:
        outFile=f"{SLURMDIR_SS}/1_prepare_model_partitioning/setup_complete"
    params:
        dir1 = MODELROOT_SS,
        dir2 = f"{SLURMDIR_SS}/1_prepare_model_partitioning",
        dir3 = f"{SLURMDIR_SS}/2_write_model_input",
        dir4 = f"{SLURMDIR_SS}/3_run_model",
        dir5 = f"{SLURMDIR_SS}/4_post-processing",

        model_input_dir = f"{RUN_GLOBGM_DIR}/model_input",
        modelroot_ss = MODELROOT_SS,
    shell:
        '''
        mkdir -p {params.dir1} {params.dir2} {params.dir3} {params.dir4} {params.dir5}
        touch {output.outFile}
        '''

rule prepare_model_partitioning:
    input:
        rules.setup_simulation.output.outFile
    output:
        outFile=f"{SLURMDIR_SS}/1_prepare_model_partitioning/prepare_model_partitioning_complete"

    params:
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/1_prepare_model_partitioning/1_prep_model_part.slurm",
        slurm_log_file=f"{SLURMDIR_SS}/1_prepare_model_partitioning/1_prep_model_part.out"

    shell:
        '''
        sbatch -o {params.slurm_log_file} {params.run_script} {MODELROOT_SS} {DATA_DIR} {output.outFile}
        while [ ! -e {output.outFile} ]; do
             sleep 10
        done
        '''

rule write_model_input_setup:
    input:
        rules.prepare_model_partitioning.output.outFile
    output:
        outFile=f"{SLURMDIR_SS}/2_write_model_input/write_model_input_setup_complete"

    params:
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/2_write_model_input/ss/_setup_ss.slurm",
        slurm_log_file=f"{SLURMDIR_SS}/2_write_model_input/_setup_ss.out"
    shell:
        '''
        sbatch -o {params.slurm_log_file} {params.run_script} {MODELROOT_SS} {DATA_DIR} {RUN_GLOBGM_DIR} {output.outFile}
        while [ ! -e {output.outFile} ]; do
            sleep 10
        done
        '''

rule write_model_input:
    input:
        rules.write_model_input_setup.output.outFile
    output:
        outFile=f"{SLURMDIR_SS}/2_write_model_input/_writeModels_ss_complete"

    params:
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/2_write_model_input/ss/_writeModels_ss.slurm",
        slurm_log_file=f"{SLURMDIR_SS}/2_write_model_input/_writeModels_ss.out", 
        calib_str=f"{CALIB_STR}"

    shell:
        '''
        sbatch -o {params.slurm_log_file} {params.run_script} {MODELROOT_SS} {DATA_DIR} {output.outFile} {params.calib_str}
        while [ ! -e {output.outFile} ]; do
            sleep 10
        done
        '''

rule run_models:
    input:
        rules.write_model_input.output.outFile
    output:
        outFile1=f"{SLURMDIR_SS}/4_post-processing/_runModels_complete_1",
        outFile2=f"{SLURMDIR_SS}/4_post-processing/_runModels_complete_2",
        outFile3=f"{SLURMDIR_SS}/4_post-processing/_runModels_complete_3",
        outFile4=f"{SLURMDIR_SS}/4_post-processing/_runModels_complete_4"

    params:
        run_script=f"{RUN_GLOBGM_DIR}/model_job_scripts/3_run_model/steady-state/_runall.sh",
        model_job_scripts=f"{RUN_GLOBGM_DIR}/model_job_scripts",
        slurm_log_file=f"{SLURMDIR_SS}",
        outFile=f"{SLURMDIR_SS}/4_post-processing/_runModels_complete",
        errorFile=f"{SLURMDIR_SS}/4_post-processing/_runModels_complete_ERROR"

    shell:
        '''
        bash {params.run_script} {MODELROOT_SS} {params.model_job_scripts} {params.slurm_log_file} {params.outFile} {DATA_DIR}
        while [ ! -e {output.outFile1} ] || [ ! -e {output.outFile2} ] || [ ! -e {output.outFile3} ] || [ ! -e {output.outFile4} ]; do
            if [ -e {params.errorFile} ]; then
                exit 1
            fi
            sleep 10
        done
        '''

rule move_data:
    input:
        rules.run_models.output.outFile1,
        rules.run_models.output.outFile2,
        rules.run_models.output.outFile3,
        rules.run_models.output.outFile4,
    output:
        outFile=f"{SLURMDIR_SS}/move_done"
    params:
        save_dir=f"{SAVEDIR}/{CALIB_STR}", 
        input_dir=f"{MODELROOT_SS}/mf6_post/",
    shell:
        '''
        mkdir -p {params.save_dir}
        cp -r {params.input_dir} {params.save_dir}
        wait 
        touch {output.outFile}
        '''

rule wrap_up:
    input:
        rules.move_data.output.outFile,
    output:
        outFile=f"{OUTPUTDIRECTORY}/{CALIB_STR}_done"
    params:
        rootFolder=f"{OUTPUTDIRECTORY}/{CALIB_STR}"
    shell:
        '''
        rm -r {params.rootFolder}
        wait
        touch {output.outFile}
        '''