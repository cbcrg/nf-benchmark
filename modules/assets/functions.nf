#!/bin/bash nextflow

/*
 ******************
 * Import libraries
 ******************
 */
import org.yaml.snakeyaml.Yaml

@Grab('com.xlson.groovycsv:groovycsv:1.0')
// @Grab('com.xlson.groovycsv:groovycsv:1.3')// slower download
import static com.xlson.groovycsv.CsvParser.parseCsv

/*
 ************
 * Functions
 ************
 */
def readYml(path) {
    def fileYml = new File(path)
    def yaml = new Yaml()
    def content = yaml.load(fileYml.text)

    return content
}

/*
 * Function reads a csv file and returns the data inside the file ready to be used
 */
def readCsv (path) {
    def fileCsv = new File(path)
    def content = parseCsv(fileCsv.text, autoDetect:true)

    return content
}

def set_input_param (path) {
    def pipelineConfigYml = readYml (path)

    input_param = pipelineConfigYml.input.input_param[0][0]

    log.info """
    INFO: This a message for testing purpose!
    INFO: Pipeline input parameter set to: $input_param
    """
    .stripIndent()

    return input_param
}

/*
 * Takes the info from the pipeline yml file with the pipeline metadata and sets the corresponding benchmark
 * The information that reads from the pipeline are:
 *  - edam_operation
 *  - edam_input_data
 *  - edam_input_format
 *  - edam_output_format
 *  - edam_output_data
 *  - edam_output_format
 * With this information the benchmarker is set and it is returned in a dictionary along with the above-mentioned
 * metadata
 */
// MAYBE ALIGNMENT SHOULD BE MODIFIED BY SOMETHING MORE GENERAL
// benchmarkInfo currently is a CSV but could become a DBs or something else
def setBenchmark (configYmlFile, benchmarkInfo, pipeline) {

    def fileYml = new File(configYmlFile)
    def yaml = new Yaml()
    def pipelineConfig = yaml.load(fileYml.text)

    topic = pipelineConfig.pipeline."$pipeline".edam_topic[0]
    operation = pipelineConfig.pipeline."$pipeline".edam_operation[0]

    input_data = pipelineConfig.input.fasta.edam_data[0][0]
    input_format = pipelineConfig.input.fasta.edam_format[0][0]
    output_data = pipelineConfig.output.alignment.edam_data[0][0]
    output_format = pipelineConfig.output.alignment.edam_format[0][0]

    /*
    log.info """
    INFO: Selected pipeline name is: ${pipelineConfig.name}
    INFO: Path to yaml pipeline configuration file \"${configYmlFile}\"
    INFO: Path to CSV benchmark info file \"${benchmarkInfo}\"
    INFO: Selected edam topic is: $topic
    INFO: Selected edam operation is: $operation

    INFO: Input data is: $input_data
    INFO: Input format is: ${input_format}
    INFO: Output data is: $output_data
    INFO: Output format is: ${output_format}
    """
    */

    def csvBenchmark = readCsv (benchmarkInfo)
    def benchmarkDict = [:]
    def i = 0

    for( row in csvBenchmark ) {
        if ( row.edam_operation == operation  &&
             row.edam_input_data == input_data &&
             row.edam_input_format == input_format &&
             row.edam_output_data == output_data &&
             row.edam_output_format == output_format ) {
                i += 1
                benchmarkDict[ (i) ] = [ benchmarker: row.benchmarker,
                                         operation: row.edam_operation,
                                         input_data: row.edam_input_data,
                                         input_format: row.edam_input_format,
                                         output_data: row.edam_output_data,
                                         output_format: row.edam_output_format ]
        }
    }
    // log.info "benchmarkDict[1]" //#del
    if ( benchmarkDict.size() > 1 ) exit 1, "Error: More than one possible benchmark please refine pipeline description for \"${params.pipeline}\" pipeline"
    if ( benchmarkDict.size() == 0 ) exit 1, "Error: No available benchmark for the selected pipeline  \"${params.pipeline}\" is not included in nf-benchmark"

    return benchmarkDict [ 1 ]
}

/*
 * Functions returns the test and reference data to be used given a benchmarker
 */
def setReference (benchmarkInfo, benchmarkerCsv, refDataCsv) {

    def dataFormat2benchmark = readCsv(benchmarkerCsv)
    def refData = readCsv(refDataCsv)

    def i = 0
    def refDataDict = [:]

    for( row in dataFormat2benchmark ) {
        if ( row.edam_test_format == benchmarkInfo.input_format  &&
             row.edam_ref_format  == benchmarkInfo.output_format &&
             row.benchmarker      == benchmarkInfo.benchmarker ) {
                i += 1

                refDataDict[ (i) ] = [ benchmarker: row.benchmarker,
                                        test_format: row.edam_test_format,
                                        ref_format : row.edam_ref_format ]
        }
    }

    // There can be more than one type of data for a given benchmarker
    // log.info "Type of data for a given benchmarker...................." +  refDataDict.size()

    if ( refDataDict.size() > 1 ) exit 1, "Error: More than one possible benchmarker please refine pipeline description for \"${params.pipeline}\" pipeline"
    if ( refDataDict.size() == 0 ) exit 1, "Error: The selected pipeline  \"${params.pipeline}\" is not included in nf-benchmark"

    refDataHit = refDataDict[ 1 ]

    def refList = []
    def pipelineInputList = []
    def refBenchmarkerList = []

    for( row in refData ) {
        if ( row.benchmarker == refDataHit.benchmarker) {
            //log.info ( row.id + "===" + row.id + row.test_data_format + "===" + row.id +  row.ref_data_format ) //#del
            id = row.id
            test_data_file = row.id + row.test_data_format
            ref_data_file = row.id + row.ref_data_format

            pipelineInputList.add ("${baseDir}/reference_dataset/" + test_data_file)
            refBenchmarkerList.add ("${baseDir}/reference_dataset/" + ref_data_file)
            refList.add(  [ id, test_data_file, ref_data_file ] )
        }
    }
    /*
    Channel
        .fromPath( refDataCsv )
        .splitCsv(header: true)
        .filter { row ->
            row.benchmarker == refDataHit.benchmarker
        }
        .map { [ it.id, //it.edam_test_data,
                 file("${baseDir}/reference_dataset/" + it.id + it.test_data_format),
                 file("${baseDir}/reference_dataset/" + it.id + it.ref_data_format) ]

        }
        .set { reference_data }

        hits = reference_data.ifEmpty ( false )

        hits.map {
            if ( !it ) { exit 1, "Error: No reference data found for benchmarker" }
        }
    */
    // return [ id, test_data_file, ref_data_file ]
    //return reference_data
    // return refList
    return [pipelineInputList, refBenchmarkerList]
}

/*
 * Functions returns the test and reference data to be used given a benchmarker
 */
def setReferenceOld (benchmarkInfo, benchmarkerCsv, refDataCsv) {

    def dataFormat2benchmark = readCsv(benchmarkerCsv)
    def refData = readCsv(refDataCsv)

    def i = 0
    def refDataDict = [:]

    for( row in dataFormat2benchmark ) {
        if ( row.edam_test_format == benchmarkInfo.input_format  &&
             row.edam_ref_format  == benchmarkInfo.output_format &&
             row.benchmarker      == benchmarkInfo.benchmarker ) {
                i += 1

                refDataDict[ (i) ] = [ benchmarker: row.benchmarker,
                                        test_format: row.edam_test_format,
                                        ref_format : row.edam_ref_format ]
        }
    }

    // There can be more than one type of data for a given benchmarker
    // log.info "Type of data for a given benchmarker...................." +  refDataDict.size()

    if ( refDataDict.size() > 1 ) exit 1, "Error: More than one possible benchmarker please refine pipeline description for \"${params.pipeline}\" pipeline"
    if ( refDataDict.size() == 0 ) exit 1, "Error: The selected pipeline  \"${params.pipeline}\" is not included in nf-benchmark"

    refDataHit = refDataDict[ 1 ]

    def refList = []

    for( row in refData ) {
        if ( row.benchmarker == refDataHit.benchmarker) {
            //log.info ( row.id + "===" + row.id + row.test_data_format + "===" + row.id +  row.ref_data_format ) //#del
            id = row.id
            test_data_file = row.id + row.test_data_format
            ref_data_file = row.id + row.ref_data_format
            refList.add(  [ id, test_data_file, ref_data_file ] )
        }
    }

    Channel
        .fromPath( refDataCsv )
        .splitCsv(header: true)
        .filter { row ->
            row.benchmarker == refDataHit.benchmarker
        }
        .map { [ it.id, //it.edam_test_data,
                 file("${baseDir}/reference_dataset/" + it.id + it.test_data_format),
                 file("${baseDir}/reference_dataset/" + it.id + it.ref_data_format) ]

        }
        .set { reference_data }

        hits = reference_data.ifEmpty ( false )

        hits.map {
            if ( !it ) { exit 1, "Error: No reference data found for benchmarker" }
        }

    // return [ id, test_data_file, ref_data_file ]
    // return refList
    return reference_data
}
