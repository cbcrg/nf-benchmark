#!/usr/bin/env nextflow

nextflow.preview.dsl=2

/*
 * Workflow to run tcoffee
 * Pipelines could be complex with several steps, thus I need to declare here all the modules and the logic of the
 * pipeline but not the benchmark steps
 */

// input sequences to align in fasta format
params.sequences = "${projectDir}/test/sequences/BB11001.fa"
params.outdir = './results'

// Set sequences channel
sequences_ch = Channel.fromPath( params.sequences, checkIfExists: true ).map { item -> [ item.baseName, item ] }
include align from "${moduleDir}/align.nf"
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