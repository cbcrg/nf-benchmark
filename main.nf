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

def configText = '''\
name: 'test-api'
repo: 'http://github.com/.../test-api.git'
tests:
  - Unit
  - QA
vpc: 'development'
'''

def yaml = new Yaml()

def config = yaml.load(configText)
println (config.name)

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

pipeline_module = file( "./modules/${params.pipeline}/main.nf")

if( !pipeline_module.exists() ) exit 1, "Error: The selected pipeline is not included in nf-benchmark: ${params.pipeline}"

// include tcoffee from  './modules/tcoffee/main.nf'
include tcoffee from  "./modules/${params.pipeline}/main.nf"

pipeline = "${baseDir}/modules/${params.pipeline}/meta.yml"
def yaml_pipeline = new Yaml()
println (pipeline)

def pipeline_config = yaml.load( pipeline )
println (pipeline_config.name)

return
include bali_base from './modules/bali_base/main.nf'
// include benchmarker from './modules/${benchmark}/main.nf'

// alignment BBA0001
params.sequences = "$baseDir/test/sequences/input/BBA0001.tfa"
params.reference = "$baseDir/test/sequences/reference/BBA0001.xml"

// aligment BB11001
params.sequences = "$baseDir/test/sequences/input/BB11001.fa"
params.reference = "$baseDir/test/sequences/reference/BB11001.xml.ref"

 log.info """\
 N F - B E N C H M A R K
 ===================================
 sequences: ${params.sequences}
 """

// Define input channels

// Run the workflow
workflow {
    tcoffee(params.sequences)
    bali_base(tcoffee.out, params.reference)
    // nf-benchmark()
    // .check_output()
}
