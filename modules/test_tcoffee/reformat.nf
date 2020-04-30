params.outdir = ''

process reformat {
    tag { id }
    publishDir "${params.outdir}/tcoffee"
    container 'quay.io/biocontainers/t_coffee:11.0.8--py27pl5.22.0_5'

    input:
    tuple val (id), file (alignment), file (reference)

    output:
    tuple val (id), path ("${alignment}.fasta"), path (reference)

    script:
    """
    t_coffee -other_pg seq_reformat ${alignment} -output fasta > ${alignment}.fasta
    """
}