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

def setInputParam (path) {
    bench_bool = 'input_nfb'

    def pipelineConfigYml = readYml (path)

    // Get all input parameters
    // input_param = pipelineConfigYml.input.input_param[0][0]
    map_input = pipelineConfigYml.input[0][0]

    // Checks whether yml has the input_nfb field check to true (input nf-benchmark)
    map_input.each{
        // log.info "key_________: ${it.key}" // #del
        if (map_input[it.key]['input_nfb']) {
            input_param = it.key
        }
    }

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
def setBenchmark (configYmlFile, benchmarkInfo, pipeline, input_field) {

    def fileYml = new File(configYmlFile)
    def yaml = new Yaml() //TODO change to use function readYml
    def pipelineConfig = yaml.load(fileYml.text)

    topic = pipelineConfig.pipeline."$pipeline".edam_topic[0]
    operation = pipelineConfig.pipeline."$pipeline".edam_operation[0]

    input_data = pipelineConfig.input."$input_field".edam_data[0][0] // TODO these are hardcodes for the current example
    input_format = pipelineConfig.input."$input_field".edam_format[0][0]
    output_data = pipelineConfig.output.alignment.edam_data[0][0]
    output_format = pipelineConfig.output.alignment.edam_format[0][0]

    /*
    log.info """
    INFO: pipeline ........... $pipeline
    INFO: topic .............. $topic
    INFO: operation .......... $operation
    INFO: input_data ......... $input_data
    INFO: input_format ....... $input_format
    INFO: output_data ........ $output_data
    INFO: output_format ...... $output_format
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
                benchmarkDict [ (row.benchmarker_priority) ] = [ benchmarker: row.benchmarker,
                                                                 operation: row.edam_operation,
                                                                 input_data: row.edam_input_data,
                                                                 input_format: row.edam_input_format,
                                                                 output_data: row.edam_output_data,
                                                                 output_format: row.edam_output_format ]
        }
    }

    higher_priority = benchmarkDict.keySet().min()

    if ( benchmarkDict.size() == 0 ) exit 1, "Error: No available benchmark for the selected pipeline  \"${params.pipeline}\" is not included in nf-benchmark"

    if ( benchmarkDict.size() > 1 ) {
        log.info """
        More than one possible benchmarker for \"${params.pipeline}\" pipeline benchmarker set to \"${benchmarkDict[higher_priority].benchmarker}\" (higher priority)
        """.stripIndent()
        benchmarkDict = benchmarkDict [ higher_priority ]
    }

    // return benchmarkDict [ higher_priority ]
    return benchmarkDict
}

/*
 * Functions returns the test and reference data to be used given a benchmarker
 */
//csvPathBenchmarker = "${baseDir}/assets/dataFormat2benchmark.csv"
//csvPathReference = "${baseDir}/assets/referenceData.csv"
/*
 * benchmarkInfo =
 */
def getData (benchmarkInfo, refDataCsv, skipReference) {
    log.info"""
    benchmarkInfo................... ${benchmarkInfo}
    """.stripIndent()
    def refData = readCsv(refDataCsv)

    def i = 0
    def refDataDict = [:]
    def dataIds  = []
    def pipelineInputList  = []
    def refBenchmarkerList  = []

    for ( row in refData ) {
        if ( row.benchmarker == benchmarkInfo.benchmarker &&
             row.pipeline_input_format == benchmarkInfo.input_format  &&
             row.benchmark_ref_format  == benchmarkInfo.output_format ) {

             id = row.id
             pipeline_input_file = id + row.test_data_format
             ref_file  = id + row.ref_data_format

             pipelineInputList.add ("${baseDir}/reference_dataset/" + pipeline_input_file)
             refBenchmarkerList.add ("${baseDir}/reference_dataset/" + ref_file)

             dataIds.add ( id )
        }
    }

    if (skipReference) { refBenchmarkerList = false }

    // return dataIds
    return [ pipelineInputList, refBenchmarkerList ]

}
