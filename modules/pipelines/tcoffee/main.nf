#!/usr/bin/env nextflow

nextflow.enable.dsl=2

/*
 * Workflow to run tcoffee
 * Pipelines could be complex with several steps, thus I need to declare here all the modules and the logic of the
 * pipeline but not the benchmark steps
 */

// input sequences to align in fasta format
params.sequences = "${projectDir}/test/sequences/BB11001.fa"
params.outdir = './results'

log.info """\
         PIPELINE  ~  version 0.1"
         ======================================="
         Input sequences (FASTA)                        : ${params.sequences}
         """
         .stripIndent()

// Set sequences channel
sequences_ch = Channel.fromPath( params.sequences, checkIfExists: true ).map { item -> [ item.baseName, item ] }

include { align } from "${moduleDir}/modules/align.nf"
// include { reformat } from "${baseDir}/modules/tcoffee/reformat.nf"

// Run the workflow
workflow pipeline {
    main:
    // Channel.from(params.ref_data) \
    // align (params.ref_data) \

    align (sequences_ch) //\
    //  | reformat

    emit:
    // align.out
    alignment = align.out
}

workflow {
  pipeline()
}