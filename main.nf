#!/usr/bin/env nextflow

/*
 * Copyright (c) 2020-2021 Centre for Genomic Regulation (CRG)
 * and the authors, Jose Espinosa-Carrasco, Paolo Di Tommaso.
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

/*
========================================================================================
                         nf-benchmark
========================================================================================
 nf-benchmark Benchmarking Pipeline.
 Authors:
 Jose Espinosa-Carrasco <espinosacarrascoj@gmail.com>
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl = 2

////////////////////////////////////////////////////
/* --               PRINT HELP                 -- */
////////////////////////////////////////////////////

def json_schema = "$projectDir/nextflow_schema.json"
if (params.help) {
    def command = "nextflow run nf-benchmark --pipeline tcoffee profile docker,test_nfb"
    log.info Schema.params_help(workflow, params, json_schema, command)
    exit 0
}

////////////////////////////////////////////////////
/* --         PRINT PARAMETER SUMMARY          -- */
////////////////////////////////////////////////////

def summary_params = Schema.params_summary_map(workflow, params, json_schema)
log.info Schema.params_summary_log(workflow, params, json_schema)

// Check whether pipeline profiles are called    
ChecksNfb.check_profiles(params, workflow, log)
ChecksNfb.check_pipeline_config(params, log)

////////////////////////////////////////////////////
/* --          PARAMETER CHECKS                -- */
////////////////////////////////////////////////////

// Check that conda channels are set-up correctly
if (params.enable_conda) {
    Checks.check_conda_channels(log)
}

// Check AWS batch settings
Checks.aws_batch(workflow, params)

// Check the hostnames against configured profiles
Checks.hostname(workflow, params, log)

// Check genome key exists if provided
// Checks.genome_exists(params, log)

////////////////////////////////////////////////////
/* --          VALIDATE INPUTS                 -- */
////////////////////////////////////////////////////

// checkPathParamList = [ params.input, params.multiqc_config, params.fasta ]
// for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters
// if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }
// if (params.fasta) { ch_fasta = file(params.fasta) } else { exit 1, 'Genome fasta file not specified!' }

pipeline_module = file( "${params.pipeline_path}/main.nf" )
if( !pipeline_module.exists() ) exit 1, "ERROR: The selected pipeline is not correctly included in nf-benchmark: ${params.pipeline}"

// Include functions
path_functions = "${workflow.projectDir}/modules/assets/functions.nf"
include { setBenchmark; setInputParam; getData } from path_functions

// Pipeline meta-information from the pipeline
yamlPathPipeline = "${params.pipeline_path}/meta.yml" //TODO check if exists

csvPathMethods = "${workflow.projectDir}/assets/methods2benchmark.csv"
csvPathBenchmarker = "${workflow.projectDir}/assets/dataFormat2benchmark.csv"
csvPathReference = "${workflow.projectDir}/assets/referenceData.csv"

// Dictionary?? //TODO
// Think on cases where it might be more than one input (described on the YAML) //TODO
input_pipeline_param = setInputParam(yamlPathPipeline)

infoBenchmark = setBenchmark(yamlPathPipeline, csvPathMethods, params.pipeline, input_pipeline_param)
// log.info (infoBenchmark) // [benchmarker:bali_score, operation:operation_0492, input_data:data_1233, input_format:format_1929, output_data:data_1384, output_format:format_1984]

/*
 * Get name of the input parameter of pipeline
 */
// include setReference from './resources/functions.nf'
benchmark_module = ""
input_benchmark_param = ""

if (!params.skip_benchmark) {
  benchmark_path = "${params.benchmarker_path}/${infoBenchmark.benchmarker}"
  benchmark_module = file( "${benchmark_path}/main.nf" )
  if( !benchmark_module.exists() ) exit 1, "[ERROR]: The selected benchmark is not correctly included in nf-benchmark: ${infoBenchmark.benchmarker}"

  // yamlPathBenchmark = "${baseDir}/modules/benchmarkers/${infoBenchmark.benchmarker}/meta.yml"
  yamlPathBenchmark = "${benchmark_path}/meta.yml"
  input_benchmark_param = setInputParam(yamlPathBenchmark)
}
else {
    log.info "INFO: Skip benchmark set to true\n"
}

// Set input and reference data sets
(input_data, ref_data)  = getData (infoBenchmark, csvPathReference, params.skip_benchmark)

params[input_pipeline_param] = input_data

if (!params.skip_benchmark) {
    params[input_benchmark_param] = ref_data
}

////////////////////////////////////////////////////
/* --          CONFIG FILES                    -- */
////////////////////////////////////////////////////

ch_multiqc_config        = file("$projectDir/assets/multiqc_config.yaml", checkIfExists: true)
ch_multiqc_custom_config = params.multiqc_config ? Channel.fromPath(params.multiqc_config) : Channel.empty()

////////////////////////////////////////////////////
/* --       IMPORT MODULES / SUBWORKFLOWS      -- */
////////////////////////////////////////////////////

// pipeline is the generic name
// hacer un wrapper por encima?
include { PIPELINE } from pipeline_module params(params)

if (!params.skip_benchmark) {
    include { BENCHMARK } from benchmark_module params(params)
}
include { MEAN_BENCHMARK_SCORE } from "${projectDir}/modules/benchmarkers/mean_benchmark_score/main.nf" //TODO make it generic
//The previous include should be a module included in the benchmark pipeline



////////////////////////////////////////////////////
/* --           RUN MAIN WORKFLOW              -- */
////////////////////////////////////////////////////


params.pipeline_output_name = false
// params.pipeline_output_name = 'alignment_regressive'
// params.pipeline_output_name = 'alignment_progressive'


// TODO move to the correct place
// Header log info

def summary = [:]

// Info required for completion email and summary
def multiqc_report = []

// Run the workflow
workflow {

    PIPELINE()
    
    // By default take ".out" if provided (or exists) then used the named output (params.pipeline_output_name)    
    if (!params.skip_benchmark) {

        // By default take ".out" if provided (or exists) then used the named output (params.pipeline_output_name)
        if (!params.pipeline_output_name) {
            output_to_benchmark = PIPELINE.out[1]          
        }
        else {
            output_to_benchmark = PIPELINE.out."$params.pipeline_output_name"                   
        }
    
        log.info """
        Benchmark: ${infoBenchmark.benchmarker}
        """.stripIndent()

        BENCHMARK (output_to_benchmark)

        BENCHMARK.out \
             | map { it.text } \
             | collectFile (name: 'scores.csv', newLine: false) \
             | set { scores }
        // TODO: output sometimes could be more than just a single score, refactor to be compatible with these cases
        MEAN_BENCHMARK_SCORE(scores) | view
    }

    /*
     * MultiQC
     */  
    if (!params.skip_multiqc) {
        workflow_summary    = Schema.params_summary_multiqc(workflow, summary_params)
        ch_workflow_summary = Channel.value(workflow_summary)

        ch_multiqc_files = Channel.empty()
        ch_multiqc_files = ch_multiqc_files.mix(Channel.from(ch_multiqc_config))
        ch_multiqc_files = ch_multiqc_files.mix(ch_multiqc_custom_config.collect().ifEmpty([]))
        ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
        ch_multiqc_files = ch_multiqc_files.mix(GET_SOFTWARE_VERSIONS.out.yaml.collect())
        ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]}.ifEmpty([]))
        
        MULTIQC (
            ch_multiqc_files.collect()
        )
        multiqc_report       = MULTIQC.out.report.toList()
        ch_software_versions = ch_software_versions.mix(MULTIQC.out.version.ifEmpty(null))
    }

}

////////////////////////////////////////////////////
/* --              COMPLETION EMAIL            -- */
////////////////////////////////////////////////////

// Before uncomment include Completion.groovy into lib folder!!!
workflow.onComplete {
    Completion.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    Completion.summary(workflow, params, log)
}

////////////////////////////////////////////////////
/* --                  THE END                 -- */
////////////////////////////////////////////////////