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
/* --          VALIDATE INPUTS                 -- */
////////////////////////////////////////////////////

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

/*
 * Hardcodes for testing - aligment BB11001 // #del
 */
// params[input_pipeline_param] = "${baseDir}/reference_dataset/BB11001.fa"
// params['reference'] = "${baseDir}/reference_dataset/BB11001.xml"
// benchmarker = "bali_base"

////////////////////////////////////////////////////
/* --           RUN MAIN WORKFLOW              -- */
////////////////////////////////////////////////////

// pipeline is the generic name
// hacer un wrapper por encima?
include { pipeline } from pipeline_module params(params)

if (!params.skip_benchmark) {
    include { benchmark } from benchmark_module params(params)
}
include { mean_benchmark_score } from "${baseDir}/modules/benchmarkers/mean_benchmark_score/main.nf" //TODO make it generic
//The previous include should be a module included in the benchmark pipeline

params.pipeline_output_name = false
// params.pipeline_output_name = 'alignment_regressive'
// params.pipeline_output_name = 'alignment_progressive'


// TODO move to the correct place
// Header log info

def summary = [:]

// Run the workflow
workflow {

    pipeline()
    
    // By default take ".out" if provided (or exists) then used the named output (params.pipeline_output_name)    
    if (!params.skip_benchmark) {

        // By default take ".out" if provided (or exists) then used the named output (params.pipeline_output_name)
        if (!params.pipeline_output_name) {
            output_to_benchmark = pipeline.out[1]          
        }
        else {
            output_to_benchmark = pipeline.out."$params.pipeline_output_name"                   
        }
    
        log.info """
        Benchmark: ${infoBenchmark.benchmarker}
        """.stripIndent()

        benchmark (output_to_benchmark)

        benchmark.out \
             | map { it.text } \
             | collectFile (name: 'scores.csv', newLine: false) \
             | set { scores }
        // TODO: output sometimes could be more than just a single score, refactor to be compatible with these cases
        mean_benchmark_score(scores) | view
    }

}

////////////////////////////////////////////////////
/* --              COMPLETION EMAIL            -- */
////////////////////////////////////////////////////

// Before uncomment include Completion.groovy into lib folder!!!
// workflow.onComplete {
//     Completion.email(workflow, params, params.summary_params, projectDir, log, multiqc_report, fail_percent_mapped)
//     Completion.summary(workflow, params, log, fail_percent_mapped, pass_percent_mapped)
// }

////////////////////////////////////////////////////
/* --                  THE END                 -- */
////////////////////////////////////////////////////