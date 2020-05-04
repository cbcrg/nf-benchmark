// Pipelines could be complex with several steps, thus I need to declare here all the modules and the logic of the
// pipeline but not the benchmark steps

include reformat as reformat_to_benchmark from "${baseDir}/modules/test_bali_score/reformat.nf"
include run_benchmark from "${baseDir}/modules/test_bali_score/run_benchmark.nf"

// Run the workflow
workflow benchmark {
    take: result_and_ref
    main:
    reformat_to_benchmark (result_and_ref) \
      | run_benchmark

    emit:
      run_benchmark.out
}