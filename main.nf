/*
 * Copyright (c) 2020 Centre for Genomic Regulation (CRG)
 * and the authors, Jose Espinosa-Carrasco and Paolo Di Tommaso.
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
 * Proof of concept of a RNAseq pipeline implemented with Nextflow
 *
 * Authors:
 * - Jose Espinosa-Carrasco <espinosacarrascoj@gmail.com>
 */

nextflow.preview.dsl = 2

@Grab(group='org.yaml', module='snakeyaml', version='1.5')
import org.yaml.snakeyaml.Yaml

@Grab('com.xlson.groovycsv:groovycsv:1.0')
// @Grab('com.xlson.groovycsv:groovycsv:1.3')// slower download
import static com.xlson.groovycsv.CsvParser.parseCsv

// def yaml = new Yaml() //del
// params --> pipeline

// if the pipeline is present then run it and the corresponding benchmark.
// check for pipeline or method (think about the naming)

// 1 check for the pipeline/method provided in the parameters
// 2 include the method
// 3 run the method
//      (think about the input data and reference data)
// 4 benchmarker checks the input
//               checks the output
//               runs the benchmark

// YML parse in order to know which is the input format and the output format
// then the benchmarker should take the reference data

pipeline_module = file( "${baseDir}/modules/${params.pipeline}/main.nf")

if( !pipeline_module.exists() ) exit 1, "ERROR: The selected pipeline is not included in nf-benchmark: ${params.pipeline}"

include pipeline from  "${baseDir}/modules/${params.pipeline}/main.nf"

yamlPath = "${baseDir}/modules/${params.pipeline}/meta.yml"
csvPathMethods = "${baseDir}/assets/methods2benchmark.csv"
csvPathReference = "${baseDir}/assets/referenceData.csv"
csvPathTest = "${baseDir}/assets/testDataInput.csv"
csvPathBenchmarker = "${baseDir}/assets/dataFormat2benchmark.csv"

// benchmark = setBenchmarkChannel(yamlPath, csvPath)
// benchmark.view()

infoBenchmark = setBenchmark(yamlPath, csvPathMethods)
// println (infoBenchmark.benchmark)
println (infoBenchmark)

setReference (infoBenchmark, csvPathBenchmarker, csvPathTest, csvPathReference)

// Think about which terms should I include:
//  operation ??
//  data  X
//  format X
//  tool ??
//  benchmark ??
def readCsv (pathCsv) {
    def fileCsv = new File(pathCsv)
    def data = parseCsv(fileCsv.text, autoDetect:true)

    return data
}

def setReference (benchmarkInfo, benchmarkerCsv, testDataCsv, refDataCsv) {

    def dataFormat2benchmark = readCsv(benchmarkerCsv)
    def testData = readCsv(testDataCsv)
    def refData = readCsv(refDataCsv)

    def i = 0
    def refDataDict = [:]

    for( row in dataFormat2benchmark ) {
        if ( row.edam_test_format == benchmarkInfo.input_format  &&
             row.edam_ref_format  == benchmarkInfo.output_format &&
             row.benchmarker      == benchmarkInfo.benchmarker ) {
                i += 1

                refDataDict = [ (i) : [ benchmarker: row.benchmarker,
                                        test_format: row.edam_test_format,
                                        ref_format : row.edam_ref_format ] ]
        }
    }

    if ( refDataDict.size() > 1 ) exit 1, "Error: More than one possible benchmarker please refine pipeline description for \"${params.pipeline}\" pipeline"
    if ( refDataDict.size() == 0 ) exit 1, "Error: The selected pipeline  \"${params.pipeline}\" is not included in nf-benchmark"

    println("##################")

    println (refDataDict [1])
    def test_format = ""
    def ref_format = ""
    refDataHit = refDataDict[ 1 ]

    for( row in refData) {
        if ( row.benchmarker == refDataHit.benchmarker  &&
             row.edam_test_format == refDataHit.test_format &&
             row.edam_ref_format == refDataHit.ref_format) {
                println ("@@@ id ${row.id}")
                println ("### test ${row.edam_test_format}")
                println ("### ref ${row.edam_ref_format}")
        }
    }
}
// set input for the pipeline
// set the reference for the benchmarker


def setReferenceLong (benchmarkInfo, benchmarkerCsv, testDataCsv, refDataCsv) {

    def fileCsvBen = new File(benchmarkerCsv)
    def benchmarkData = parseCsv(fileCsv.text, autoDetect:true)

    def fileCsvTest = new File(testDataCsv)
    def csvTestData = parseCsv(fileCsvTest.text, autoDetect:true)

    def fileCsvRef = new File(refDataCsv)
    def csvRefData = parseCsv(fileCsvRef.text, autoDetect:true)

    def i = 0
    def refDataDict = [:]

    for( row in csvRefData ) {
        if ( row.edam_data == benchmarkInfo.input_data  &&
             row.edam_format == benchmarkInfo.input_format ) {
                i += 1

                refDataDict = [ (i) : [ ref_input_data: row.edam_data,
                                        ref_input_format: row.edam_format,
                                        ref_input_p: row.ref_data_p ] ]
        }
    }

    println ("..............................................")
    println (refDataDict)
    println ("..............................................")
}

// benchmarker = "bali_base"
include benchmark from "./modules/${infoBenchmark.benchmarker}/main.nf"

println("INFO: Benchmark set to: ${infoBenchmark.benchmarker}")

// relationship 1 to 1 between the input and the output
// could be that some inputs can also be output to other pipelines

// alignment BBA0001
params.sequences = "${baseDir}/test/sequences/input/BBA0001.tfa"
params.reference = "${baseDir}/test/sequences/reference/BBA0001.xml"

// aligment BB11001
// params.sequences = "${baseDir}/test/sequences/input/BB11001.fa"
// params.reference = "${baseDir}/test/sequences/reference/BB11001.xml.ref"

 log.info """\
 N F - B E N C H M A R K
 ===================================
 sequences: ${params.sequences}
 """

// Run the workflow
workflow {
    pipeline(params.sequences)
    benchmark(pipeline.out, params.reference)
    // bali_base(pipeline.out, params.reference)
    // nf-benchmark()
    // .check_output()
}

// benchmarkInfo currently is a CSV but could become a DBs or something else
def setBenchmark (configYmlFile, benchmarkInfo) {

    def fileYml = new File(configYmlFile)
    def yaml = new Yaml()
    def pipelineConfig = yaml.load(fileYml.text)

    println("INFO: Selected pipeline name is \"${pipelineConfig.name}\"")
    println("INFO: Path to yaml pipeline configuration file \"${configYmlFile}\"")
    println("INFO: Path to CSV benchmark info file \"${benchmarkInfo}\"")

    topic = pipelineConfig.pipeline.tcoffee.edam_topic[0]
    operation = pipelineConfig.pipeline.tcoffee.edam_operation[0]

    input_data = pipelineConfig.input.fasta.edam_data[0][0]
    input_format = pipelineConfig.input.fasta.edam_format[0][0]
    output_data = pipelineConfig.output.alignment.edam_data[0][0]
    output_format = pipelineConfig.output.alignment.edam_format[0][0]

    println("INFO: Selected pipeline name is: ${pipelineConfig.name}")
    println("INFO: Selected edam topic is: $topic")
    println("INFO: Selected edam operation is: $operation")

    println("INFO: Input data is: $input_data")
    println("INFO: Input format is: ${input_format}")
    println("INFO: Output data is: $output_data")
    println("INFO: Output format is: ${output_format}")

    def fileCsv = new File(benchmarkInfo)
    def csvData = parseCsv(fileCsv.text, autoDetect:true)
    // def benchmarkList = []
    def benchmarkDict = [:]
    def i = 0

    for( row in csvData ) {
        if ( row.edam_operation == operation  &&
             row.edam_input_data == input_data &&
             row.edam_input_format == input_format &&
             row.edam_output_data == output_data &&
             row.edam_output_format == output_format ) {
                i += 1
                // benchmarkList.add(row.benchmarker)
                benchmarkDict = [ (i) : [ benchmarker: row.benchmarker,
                                          operation: row.edam_operation,
                                          input_data: row.edam_input_data,
                                          input_format: row.edam_input_format,
                                          output_data: row.edam_output_data,
                                          output_format: row.edam_output_format ] ]
                // println "$row.edam_operation -----************---------"
        }
    }

    //if ( benchmarkList.size() > 1 ) exit 1, "Error: More than one possible benchmark please refine pipeline description for \"${params.pipeline}\" pipeline"
    //if ( benchmarkList.size() == 0 ) exit 1, "Error: The selected pipeline  \"${params.pipeline}\" is not included in nf-benchmark"

    if ( benchmarkDict.size() > 1 ) exit 1, "Error: More than one possible benchmark please refine pipeline description for \"${params.pipeline}\" pipeline"
    if ( benchmarkDict.size() == 0 ) exit 1, "Error: The selected pipeline  \"${params.pipeline}\" is not included in nf-benchmark"

    //println ( "Size is........." + benchmarkDict.size()  )
    //println ( "====================" )
    //println ( benchmarkDict [ 1 ] )
    //println ( benchmarkDict.keySet() )

    // return benchmarkList[0]
    return benchmarkDict[ 1 ]
}

// benchmarkInfo currently is a CSV but could become a DBs or something else
def setBenchmarkChannel (configYmlFile, benchmarkInfo) {

    def file = new File(configYmlFile)
    def yaml = new Yaml()
    def pipelineConfig = yaml.load(file.text)

    println("INFO: Selected pipeline name is \"${pipelineConfig.name}\"")
    println("INFO: Path to yaml pipeline configuration file \"${configYmlFile}\"")
    println("INFO: Path to CSV benchmark info file \"${benchmarkInfo}\"")

    topic = pipelineConfig.pipeline.tcoffee.edam_topic[0]
    operation = pipelineConfig.pipeline.tcoffee.edam_operation[0]

    input_data = pipelineConfig.input.fasta.edam_data[0][0]
    input_format = pipelineConfig.input.fasta.edam_format[0][0]
    output_data = pipelineConfig.output.alignment.edam_data[0][0]
    output_format = pipelineConfig.output.alignment.edam_format[0][0]

    println("INFO: Selected pipeline name is: ${pipelineConfig.name}")
    println("INFO: Selected edam topic is: $topic")
    println("INFO: Selected edam operation is: $operation")

    println("INFO: Input data is: $input_data")
    println("INFO: Input format is: ${input_format}")
    println("INFO: Output data is: $output_data")
    println("INFO: Output format is: ${output_format}")

    Channel
        .fromPath( "${baseDir}/assets/methods2benchmark.csv" )
        .splitCsv(header: true)
        .filter { row ->
            row.edam_operation == operation  &&
            row.edam_input_data == input_data &&
            row.edam_input_format == input_format &&
            row.edam_output_data == output_data &&
            row.edam_output_format == output_format
        }
        .map { it.benchmark }
        .set { benchmark }

     benchmark
        .count()
        .subscribe {
            if ( it > 1 ) exit 1, "Error: More than one possible benchmark please refine pipeline description for \"${params.pipeline}\" pipeline"
            if ( it == 0 ) exit 1, "Error: The selected pipeline  \"${params.pipeline}\" is not included in nf-benchmark"
        }

    return benchmark
}