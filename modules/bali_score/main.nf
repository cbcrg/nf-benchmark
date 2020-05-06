/*
 * Workflow to run bali_score
 * Pipelines could be complex with several steps, thus I need to declare here all the modules and the logic of the
 * pipeline but not the benchmark steps
 * This workflow should enclose all the steps to perform the benchmark
 */


include reformat as reformat_to_benchmark from "${baseDir}/modules/bali_score/reformat.nf"
include run_benchmark from "${baseDir}/modules/bali_score/run_benchmark.nf"

// Run the workflow
workflow benchmark {
    take: result_and_ref
    main:
    reformat_to_benchmark (result_and_ref) \
      | run_benchmark

    emit:
      run_benchmark.out
}