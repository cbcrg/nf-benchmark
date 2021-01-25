#!/usr/bin/env nextflow

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
========================================================================================
                         nf-benchmark
========================================================================================
 nf-benchmark Benchmarking Pipeline.
 Authors:
 Jose Espinosa-Carrasco <espinosacarrascoj@gmail.com>
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl = 2

import org.yaml.snakeyaml.Yaml

@Grab('com.xlson.groovycsv:groovycsv:1.0')
// @Grab('com.xlson.groovycsv:groovycsv:1.3')// slower download
import static com.xlson.groovycsv.CsvParser.parseCsv

/*
log.info """\
===================================
 N F - B E N C H M A R K
===================================
Pipeline: ${params.pipeline}
"""
*/

////////////////////////////////////////////////////
/* -- PRINT HELP MESSAGE IF REQUIRED           -- */
////////////////////////////////////////////////////

def json_schema = "$baseDir/nextflow_schema.json"
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

////////////////////////////////////////////////////
/* --          VALIDATE INPUTS                 -- */
////////////////////////////////////////////////////

pipeline_module = file( "${params.pipeline_path}/main.nf" )
if( !pipeline_module.exists() ) exit 1, "ERROR: The selected pipeline is not correctly included in nf-benchmark: ${params.pipeline}"

params.outdir = "${workflow.projectDir}/results"
params.skip_benchmark = false

// Include functions
path_functions = "${workflow.projectDir}/modules/assets/functions.nf"
include { setBenchmark; setInputParam; getData } from path_functions

// Pipeline
// Include the pipeline from the modules path if available
// params.path_to_pipelines = "${workflow.projectDir}/modules/pipelines"
// path_to_pipelines =  "${workflow.projectDir}/modules/pipelines"
// pipeline_path = "${params.path_to_pipelines}/${params.pipeline}"

// Pipeline meta-information from the pipeline
yamlPathPipeline = "${params.pipeline_path}/meta.yml" //TODO check if exists

// Benchmark
// benchmarker_path =  "${workflow.projectDir}/modules/benchmarkers"
// params.benchmarker_path = "${workflow.projectDir}/modules/benchmarkers"

csvPathMethods = "${baseDir}/assets/methods2benchmark.csv"
csvPathBenchmarker = "${baseDir}/assets/dataFormat2benchmark.csv"
csvPathReference = "${baseDir}/assets/referenceData.csv"

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

/* // #del
log.info """
        ************************
        pipeline input name: ${input_pipeline_param}\n
        benchmark input name: ${input_benchmark_param}\n
        ************************
        """.stripIndent()
*/

// pipeline is the generic name
// hacer un wrapper por encima?
include { pipeline } from pipeline_module params(params)

if (!params.skip_benchmark) {
    include { benchmark } from benchmark_module params(params)
}
include { mean_benchmark_score } from "${baseDir}/modules/benchmarkers/mean_benchmark_score/main.nf" //TODO make it generic
//The previous include should be a module included in the benchmark pipeline

params.pipeline_output_name = false
//params.pipeline_output_name = 'alignment_regressive'

// TODO move to the correct place
// Header log info
log.info nfcoreHeader()
def summary = [:]

// Run the workflow
workflow {

    pipeline()
   
    // By default take ".out" if provided (or exists) then used the named output (params.pipeline_output_name)
    /*
    if (!params.pipeline_output_name) {
        output_to_benchmark = pipeline.out[0]
    }
    else {
        output_to_benchmark = pipeline.out."$params.pipeline_output_name"
    }
    */
    if (!params.skip_benchmark) {

        // By default take ".out" if provided (or exists) then used the named output (params.pipeline_output_name)
        if (!params.pipeline_output_name) {
            output_to_benchmark = pipeline.out[0]
        }
        else {
            output_to_benchmark = pipeline.out."$params.pipeline_output_name"
        }

        log.info """
        Benchmark: ${infoBenchmark.benchmarker}
        """.stripIndent()

        // benchmark (pipeline.out.alignment_regressive) // HERE USING NAMED OUTPUT
        benchmark (output_to_benchmark)
        // benchmark (pipeline.out) //TODO reference should be a param

        benchmark.out \
             | map { it.text } \
             | collectFile (name: 'scores.csv', newLine: false) \
             | set { scores }
        // TODO: output sometimes could be more than just a single score, refactor to be compatible with these cases
        mean_benchmark_score(scores) | view
    }

}

/*
 * Completion e-mail notification
 */
/*
workflow.onComplete {

    // Set up the e-mail variables
    def subject = "[nf-core/nfbenchmark] Successful: $workflow.runName"
    if (!workflow.success) {
        subject = "[nf-core/nfbenchmark] FAILED: $workflow.runName"
    }
    def email_fields = [:]
    email_fields['version'] = workflow.manifest.version
    email_fields['runName'] = custom_runName ?: workflow.runName
    email_fields['success'] = workflow.success
    email_fields['dateComplete'] = workflow.complete
    email_fields['duration'] = workflow.duration
    email_fields['exitStatus'] = workflow.exitStatus
    email_fields['errorMessage'] = (workflow.errorMessage ?: 'None')
    email_fields['errorReport'] = (workflow.errorReport ?: 'None')
    email_fields['commandLine'] = workflow.commandLine
    email_fields['projectDir'] = workflow.projectDir
    email_fields['summary'] = summary
    email_fields['summary']['Date Started'] = workflow.start
    email_fields['summary']['Date Completed'] = workflow.complete
    email_fields['summary']['Pipeline script file path'] = workflow.scriptFile
    email_fields['summary']['Pipeline script hash ID'] = workflow.scriptId
    if (workflow.repository) email_fields['summary']['Pipeline repository Git URL'] = workflow.repository
    if (workflow.commitId) email_fields['summary']['Pipeline repository Git Commit'] = workflow.commitId
    if (workflow.revision) email_fields['summary']['Pipeline Git branch/tag'] = workflow.revision
    email_fields['summary']['Nextflow Version'] = workflow.nextflow.version
    email_fields['summary']['Nextflow Build'] = workflow.nextflow.build
    email_fields['summary']['Nextflow Compile Timestamp'] = workflow.nextflow.timestamp

    // // TODO nf-core: If not using MultiQC, strip out this code (including params.max_multiqc_email_size)
    // // On success try attach the multiqc report
    // def mqc_report = null
    // try {
    //     if (workflow.success) {
    //         mqc_report = ch_multiqc_report.getVal()
    //         if (mqc_report.getClass() == ArrayList) {
    //             log.warn "[nf-core/nfbenchmark] Found multiple reports from process 'multiqc', will use only one"
    //             mqc_report = mqc_report[0]
    //         }
    //     }
    // } catch (all) {
    //     log.warn "[nf-core/nfbenchmark] Could not attach MultiQC report to summary email"
    // }

    // Check if we are only sending emails on failure
    email_address = params.email
    if (!params.email && params.email_on_fail && !workflow.success) {
        email_address = params.email_on_fail
    }

    // Render the TXT template
    def engine = new groovy.text.GStringTemplateEngine()
    def tf = new File("$baseDir/assets/email_template.txt")
    def txt_template = engine.createTemplate(tf).make(email_fields)
    def email_txt = txt_template.toString()

    // Render the HTML template
    def hf = new File("$baseDir/assets/email_template.html")
    def html_template = engine.createTemplate(hf).make(email_fields)
    def email_html = html_template.toString()

    // Render the sendmail template
    def smail_fields = [ email: email_address, subject: subject, email_txt: email_txt, email_html: email_html, baseDir: "$baseDir", mqcFile: mqc_report, mqcMaxSize: params.max_multiqc_email_size.toBytes() ]
    def sf = new File("$baseDir/assets/sendmail_template.txt")
    def sendmail_template = engine.createTemplate(sf).make(smail_fields)
    def sendmail_html = sendmail_template.toString()

    // Send the HTML e-mail
    if (email_address) {
        try {
            if (params.plaintext_email) { throw GroovyException('Send plaintext e-mail, not HTML') }
            // Try to send HTML e-mail using sendmail
            [ 'sendmail', '-t' ].execute() << sendmail_html
            log.info "[nf-core/nfbenchmark] Sent summary e-mail to $email_address (sendmail)"
        } catch (all) {
            // Catch failures and try with plaintext
            [ 'mail', '-s', subject, email_address ].execute() << email_txt
            log.info "[nf-core/nfbenchmark] Sent summary e-mail to $email_address (mail)"
        }
    }

    // Write summary e-mail HTML to a file
    def output_d = new File("${params.outdir}/pipeline_info/")
    if (!output_d.exists()) {
        output_d.mkdirs()
    }
    def output_hf = new File(output_d, "pipeline_report.html")
    output_hf.withWriter { w -> w << email_html }
    def output_tf = new File(output_d, "pipeline_report.txt")
    output_tf.withWriter { w -> w << email_txt }

    c_green = params.monochrome_logs ? '' : "\033[0;32m";
    c_purple = params.monochrome_logs ? '' : "\033[0;35m";
    c_red = params.monochrome_logs ? '' : "\033[0;31m";
    c_reset = params.monochrome_logs ? '' : "\033[0m";

    if (workflow.stats.ignoredCount > 0 && workflow.success) {
        log.info "-${c_purple}Warning, pipeline completed, but with errored process(es) ${c_reset}-"
        log.info "-${c_red}Number of ignored errored process(es) : ${workflow.stats.ignoredCount} ${c_reset}-"
        log.info "-${c_green}Number of successfully ran process(es) : ${workflow.stats.succeedCount} ${c_reset}-"
    }

    if (workflow.success) {
        log.info "-${c_purple}[nf-core/nfbenchmark]${c_green} Pipeline completed successfully${c_reset}-"
    } else {
        checkHostname()
        log.info "-${c_purple}[nf-core/nfbenchmark]${c_red} Pipeline completed with errors${c_reset}-"
    }

}
*/

def nfcoreHeader() {
    // Log colors ANSI codes
    c_black = params.monochrome_logs ? '' : "\033[0;30m";
    c_blue = params.monochrome_logs ? '' : "\033[0;34m";
    c_cyan = params.monochrome_logs ? '' : "\033[0;36m";
    c_dim = params.monochrome_logs ? '' : "\033[2m";
    c_green = params.monochrome_logs ? '' : "\033[0;32m";
    c_purple = params.monochrome_logs ? '' : "\033[0;35m";
    c_reset = params.monochrome_logs ? '' : "\033[0m";
    c_white = params.monochrome_logs ? '' : "\033[0;37m";
    c_yellow = params.monochrome_logs ? '' : "\033[0;33m";

    return """    -${c_dim}--------------------------------------------------${c_reset}-
                                            ${c_green},--.${c_black}/${c_green},-.${c_reset}
    ${c_blue}        ___     __   __   __   ___     ${c_green}/,-._.--~\'${c_reset}
    ${c_blue}  |\\ | |__  __ /  ` /  \\ |__) |__         ${c_yellow}}  {${c_reset}
    ${c_blue}  | \\| |       \\__, \\__/ |  \\ |___     ${c_green}\\`-._,-`-,${c_reset}
                                            ${c_green}`._,._,\'${c_reset}
    ${c_purple}  nf-core/nfbenchmark v${workflow.manifest.version}${c_reset}
    -${c_dim}--------------------------------------------------${c_reset}-
    """.stripIndent()
}

def checkHostname() {
    def c_reset = params.monochrome_logs ? '' : "\033[0m"
    def c_white = params.monochrome_logs ? '' : "\033[0;37m"
    def c_red = params.monochrome_logs ? '' : "\033[1;91m"
    def c_yellow_bold = params.monochrome_logs ? '' : "\033[1;93m"
    if (params.hostnames) {
        def hostname = "hostname".execute().text.trim()
        params.hostnames.each { prof, hnames ->
            hnames.each { hname ->
                if (hostname.contains(hname) && !workflow.profile.contains(prof)) {
                    log.error "====================================================\n" +
                            "  ${c_red}WARNING!${c_reset} You are running with `-profile $workflow.profile`\n" +
                            "  but your machine hostname is ${c_white}'$hostname'${c_reset}\n" +
                            "  ${c_yellow_bold}It's highly recommended that you use `-profile $prof${c_reset}`\n" +
                            "============================================================"
                }
            }
        }
    }
}
