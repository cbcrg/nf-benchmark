/*
 * Workflow to run bali_score
 * Pipelines could be complex with several steps, thus I need to declare here all the modules and the logic of the
 * pipeline but not the benchmark steps
 * This workflow should enclose all the steps to perform the benchmark
 */

params.reference = ""

include reformat as reformat_to_benchmark from "${moduleDir}/modules/reformat.nf"
include run_benchmark from "${moduleDir}/modules/run_benchmark.nf"

// log.info ("$params.reference >>>>>>>>>>>>>>>>>") // #del
// Set sequences channel
reference_ch = Channel.fromPath( params.reference, checkIfExists: true ).map { item -> [ item.baseName, item ] }

// Run the workflow
workflow benchmark {
    take:
      target_aln
    // result
    // result, path(ref)

    main:
      target_aln
        .cross ( reference_ch )
        .map { it -> [ it[0][0], it[0][1], it[1][1] ] }
        .set { target_and_ref }

      reformat_to_benchmark (target_and_ref)  \
        | run_benchmark
      //run_benchmark (target_and_ref)

    emit:
      run_benchmark.out
}

workflow {
  benchmark()
}