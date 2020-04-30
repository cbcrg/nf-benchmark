
process bar {
    tag {bar}
    publishDir "${params.outdir}/test_compound_pipeline"
    // container 'quay.io/biocontainers/t_coffee:11.0.8--py27pl5.22.0_5'

    input:
    val (foo_var)

    output:
    stdout()

    script:
    """
    echo "${foo_var} ========= hello world!"
    """
}