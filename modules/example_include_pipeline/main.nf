
params.foo = 'Hola'

include foo from "${baseDir}/modules/example_include_pipeline/foo.nf"
include bar from "${baseDir}/modules/example_include_pipeline/bar.nf"

// Run the workflow

workflow pipeline {

    main:
    Channel.from(params.foo) | foo | bar | view

    println ("###############==================")
}

