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
