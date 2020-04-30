// Pipelines could be complex with several steps, thus I need to declare here all the modules and the logic of the
// pipeline but not the benchmark steps

params.outdir = ""
params.ref_data = ""

println ("------------------- $params.outdir")
include align from "${baseDir}/modules/test_tcoffee/align.nf"
include reformat from "${baseDir}/modules/test_tcoffee/reformat.nf"

//params.ref_data.view()
//return
// Run the workflow
workflow pipeline {
    main:
    // Channel.from(params.ref_data) \
    align (params.ref_data) \
      | reformat

    emit:
      reformat.out
}






/*
 = Channel.from(params.ref_data)


process pipeline {
    align | convert | view
}
*/