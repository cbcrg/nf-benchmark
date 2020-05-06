/*
 * Workflow to run tcoffee
 * Pipelines could be complex with several steps, thus I need to declare here all the modules and the logic of the
 * pipeline but not the benchmark steps
 */

params.outdir = ''
params.ref_data = ''

include align from "${baseDir}/modules/tcoffee/align.nf"
include reformat from "${baseDir}/modules/tcoffee/reformat.nf"

// Run the workflow
workflow pipeline {
    main:
    // Channel.from(params.ref_data) \
    align (params.ref_data) \
      | reformat

    emit:
      reformat.out
}