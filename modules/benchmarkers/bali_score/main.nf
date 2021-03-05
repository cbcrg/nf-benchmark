/*
 * Workflow to run bali_score
 * Pipelines could be complex with several steps, thus I need to declare here all the modules and the logic of the
 * pipeline but not the benchmark steps
 * This workflow should enclose all the steps to perform the benchmark
 */

params.reference = ""

include { REFORMAT as REFORMAT_TO_BENCHMARK }  from "${moduleDir}/modules/reformat.nf"
include { RUN_BENCHMARK } from "${moduleDir}/modules/run_benchmark.nf"

// Set sequences channel
reference_ch = Channel.fromPath( params.reference, checkIfExists: true ).map { item -> [ item.baseName, item ] }

// Run the workflow
workflow BENCHMARK {
    take:
    target_aln

    main:
    target_aln
      .join ( reference_ch, by: [0] )
      .ifEmpty { error "Cannot find any reference matching alignment for benchmarking" }
      .set { target_and_ref }

    REFORMAT_TO_BENCHMARK (target_and_ref)
    // REFORMAT_TO_BENCHMARK (target_and_ref)  \
    //   | RUN_BENCHMARK
    //RUN_BENCHMARK (target_and_ref)

    emit:
    // RUN_BENCHMARK.out
    REFORMAT_TO_BENCHMARK.out
}

workflow {
  BENCHMARK()
}