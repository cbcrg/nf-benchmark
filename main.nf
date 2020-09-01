/*
 * Copyright (c) 2020 Centre for Genomic Regulation (CRG)
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
 * Proof of concept of nf-benchmark: An automatic benchmarking pipeline implemented with Nextflow
 *
 * Authors:
 * - Jose Espinosa-Carrasco <espinosacarrascoj@gmail.com>
 */

nextflow.preview.dsl = 2

import org.yaml.snakeyaml.Yaml

@Grab('com.xlson.groovycsv:groovycsv:1.0')
// @Grab('com.xlson.groovycsv:groovycsv:1.3')// slower download
import static com.xlson.groovycsv.CsvParser.parseCsv

log.info """\
===================================
 N F - B E N C H M A R K
===================================
Pipeline: ${params.pipeline}
"""

////////////////////////////////////////////////////
/* --          VALIDATE INPUTS                 -- */
////////////////////////////////////////////////////

pipeline_module = file( "${params.pipeline_path}/main.nf" )
if( !pipeline_module.exists() ) exit 1, "ERROR: The selected pipeline is not correctly included in nf-benchmark: ${params.pipeline}"

projectDir = "${baseDir}"
params.outdir = "${projectDir}/results"
// params.ref_data = ''
// params.sequences = ''
params.skip_benchmark = false

// Include functions
path_functions = "${projectDir}/modules/assets/functions.nf"
include { setBenchmark; set_input_param; setReference } from path_functions

// Pipeline
// Include the pipeline from the modules path if available
// params.path_to_pipelines = "${projectDir}/modules/pipelines" 
// path_to_pipelines =  "${projectDir}/modules/pipelines"

// pipeline_path = "${params.path_to_pipelines}/${params.pipeline}"


// Include pipeline test for nf-benchmark
test_config = file( "${params.pipeline_path}/conf/test_nfb.config", checkIfExists: true ) // TODO params!!!

// Pipeline meta-information from the pipeline
yamlPathPipeline = "${params.pipeline_path}/meta.yml" //TODO check if exists

// Benchmark
// path_to_benchmarks =  "${projectDir}/modules/benchmarks"
// params.path_to_benchmarks = "${projectDir}/modules/benchmarks"

csvPathMethods = "${baseDir}/assets/methods2benchmark.csv"
csvPathBenchmarker = "${baseDir}/assets/dataFormat2benchmark.csv"
csvPathReference = "${baseDir}/assets/referenceData.csv"

// set_input_param(yamlPathPipeline)
// Dictionary?? 
// Think on cases where it might be more than  one input (described on the YAML) //TODO
input_pipeline_param = set_input_param(yamlPathPipeline)
// log.info "Input pipeline param>>>>>>>>> $input_pipeline_param\n" //#del

infoBenchmark = setBenchmark(yamlPathPipeline, csvPathMethods, params.pipeline, input_pipeline_param)
// log.info (infoBenchmark) // [benchmarker:bali_score, operation:operation_0492, input_data:data_1233, input_format:format_1929, output_data:data_1384, output_format:format_1984]

// ref_data = setReferenceOld (infoBenchmark, csvPathBenchmarker, csvPathReference) //#del
// params.ref_data = ref_data //#del

//Interpolate input dataset read from yml
// Can I use a function to override a param?

/*
 * Get name of the input parameter of pipeline
 */
//include setReference from './resources/functions.nf'
// log.info "${params.skip_benchmark}" //del

benchmark_module = ""

if (!params.skip_benchmark) {
  benchmark_path = "${params.path_to_benchmarks}/${infoBenchmark.benchmarker}"
  benchmark_module = file( "${benchmark_path}/main.nf" )
  if( !benchmark_module.exists() ) exit 1, "ERROR: The selected benchmark is not correctly included in nf-benchmark: ${infoBenchmark.benchmarker}"

  // yamlPathBenchmark = "${baseDir}/modules/benchmarks/${infoBenchmark.benchmarker}/meta.yml"
  yamlPathBenchmark = "${benchmark_path}/meta.yml"
  input_benchmark_param = set_input_param(yamlPathBenchmark)
}
else {
    log.info "INFO: Skip benchmark set to true\n"
}

// Assign the input parameter
// TODO Deal with test config test data TRY WITH EMPTY PARAM if param = "" set this one
// if is set by test config do not reset?

// Set input and reference data sets
// TODO: Separate in two functions so that the reference is not set if skip_benchmark para is set?
(input_data, ref_data) = setReference (infoBenchmark, csvPathBenchmarker, csvPathReference)
// log.info "Input data set to >>>>>>>>>>> $input_data\n" //#del
// log.info "Ref data set to >>>>>>>>>>> $ref_data\n" //#del

params[input_pipeline_param] = input_data
if (!params.skip_benchmark) {
    params[input_benchmark_param] = ref_data
}

// Hardcodes testing - aligment BB11001 // #del
// params[input_pipeline_param] = "${baseDir}/reference_dataset/BB11001.fa" // #del
// params['reference'] = "${baseDir}/reference_dataset/BB11001.xml" // #del
// benchmarker = "bali_base" // #del

/*
log.info """
        Info: see here
        ${params.sequences}
        """.stripIndent()
*/

include { pipeline } from pipeline_module params(params)
if (!params.skip_benchmark) {
    include { benchmark } from benchmark_module params(params) //commented fromPath error because is not receiving the references sequences
}
include { mean_benchmark_score } from "${baseDir}/modules/mean_benchmark_score/main.nf" //TODO make it generic
//The previous include should be a module included in the benchmark pipeline

/*
if (!params.skip_benchmark) {
    params[input_benchmark_param] = ref_data
}
*/

/*
 * COMMANDS
 * nextflow run main.nf --pipeline tcoffee --skip_benchmark -profile docker,test_nfb -ansi-log false -resume
 * nextflow run main.nf --pipeline tcoffee --pipeline_output_name 'alignment' --skip_benchmark -profile docker,test_nfb -ansi-log false -resume
 * make regressive | nextflow run  main.nf --pipeline regressive_alignment --skip_benchmark -profile docker,test_nfb -ansi-log false -resume
 * make regressive | nextflow run  main.nf --pipeline regressive_alignment --pipeline_output_name 'alignment_regressive' --skip_benchmark -profile docker,test_nfb -ansi-log false -resume
 * COMMANDS WITH BENCHMARK
 * nextflow run main.nf --pipeline tcoffee -profile docker,test_nfb -ansi-log false -resume
 * nextflow run main.nf --pipeline tcoffee --pipeline_output_name 'alignment' --skip_benchmark -profile docker,test_nfb -ansi-log false -resume
 * make regressive | nextflow run  main.nf --pipeline regressive_alignment --skip_benchmark -profile docker,test_nfb -ansi-log false -resume
 * make regressive | nextflow run  main.nf --pipeline regressive_alignment --pipeline_output_name 'alignment_regressive' --skip_benchmark -profile docker,test_nfb -ansi-log false -resume
 */

params.pipeline_output_name = false
//params.pipeline_output_name = 'alignment_regressive'

// Run the workflow
workflow {

    pipeline()

    // By default take ".out" if provided (or exists) then used the named output
    if (!params.pipeline_output_name) {
        output_to_benchmark = pipeline.out[0]
    }
    else {
        output_to_benchmark = pipeline.out."$params.pipeline_output_name"
    }

    // pipeline.out.alignment_regressive.view() //WORKS
    // pipeline.out."$output_name".view() //WORKS
    // pipeline.out.view() //WORKS

    output_to_benchmark.view()
    len = pipeline.out.size()
    // len = output_to_benchmark.size() // Does not work

    log.info """
    Length output... ${len}\n
    """.stripIndent()

    // I need to declare the output of the pipeline that the benchmark should use
    
    // commented it is called even if skip_benchmark is set to true reimplement
    if (!params.skip_benchmark) {

        log.info """
        Benchmark: ${infoBenchmark.benchmarker}
        """.stripIndent()

        // benchmark (pipeline.out.alignment_regressive) // HERE USING NAMED OUTPUT
        benchmark (output_to_benchmark)

        // benchmark (pipeline.out) //TODO reference should be a param
        // //benchmark(pipeline['alignmentFile'])

        benchmark.out \
             | map { it.text } \
             | collectFile (name: 'scores.csv', newLine: false) \
             | set { scores }
        // // TODO: output sometimes could be more than just a single score, refactor to be compatible with these cases
        mean_benchmark_score(scores) | view
    }

}


