/*
 * Workflow to run tcoffee
 * Pipelines could be complex with several steps, thus I need to declare here all the modules and the logic of the
 * pipeline but not the benchmark steps
 */

// input sequences to align in fasta format
// params.sequences = "${baseDir}/test/sequences/input/BB11001.fa"
// params.reference = "${baseDir}/test/sequences/reference/BB11001.xml.ref"

params.sequences = ''
params.outdir = ''
params.ref_data = '' // TODO #del

// Set sequences channel
sequences_ch = Channel.fromPath( params.sequences, checkIfExists: true ).map { item -> [ item.baseName, item ] }
include align from "${baseDir}/modules/tcoffee/align.nf"
// include reformat from "${baseDir}/modules/tcoffee/reformat.nf"

// Run the workflow
workflow pipeline {
    main:
    // Channel.from(params.ref_data) \
    //align (params.ref_data) \

    align (sequences_ch) //\
    //  | reformat

    emit:
      // reformat.out
      align.out
}

workflow {
  pipeline()
}