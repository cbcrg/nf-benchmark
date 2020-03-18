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

def yaml = new Yaml()

pipeline_module = file( "./modules/${params.pipeline}/main.nf")

if( !pipeline_module.exists() ) exit 1, "ERROR: The selected pipeline is not included in nf-benchmark: ${params.pipeline}"

include pipeline from  "./modules/${params.pipeline}/main.nf"

yamlPath = "./modules/${params.pipeline}/meta.yml"
def file = new File(yamlPath)
def pipelineConfig = yaml.load(file.text)

println("INFO: Selected pipeline name is \"${pipelineConfig.name}\"")

def setBenchmark (configYmlFile) {
    println("INFO: Path to yaml pipeline configuration file \"${configYmlFile}\"")

    def file = new File(configYmlFile)
    def yaml = new Yaml()
    def pipelineConfig = yaml.load(file.text)

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
        .fromPath( "$baseDir/assets/methods2benchmark.csv" )
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

benchmark = setBenchmark(yamlPath)

benchmark.view()

benchmarker = "bali_base"
include benchmark from "./modules/${benchmarker}/main.nf"

println("INFO: Benchmark set to: ${benchmarker}")

// Define input channels
// alignment BBA0001
params.sequences = "$baseDir/test/sequences/input/BBA0001.tfa"
params.reference = "$baseDir/test/sequences/reference/BBA0001.xml"

// aligment BB11001
// params.sequences = "$baseDir/test/sequences/input/BB11001.fa"
// params.reference = "$baseDir/test/sequences/reference/BB11001.xml.ref"

 log.info """\
 N F - B E N C H M A R K
 ===================================
 sequences: ${params.sequences}
 """

// Run the workflow
workflow {
    pipeline(params.sequences)
    benchmark(pipeline.out, params.reference)
}
