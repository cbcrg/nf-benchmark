/*
 * Reformats a MSA produced by t-coffee to fasta
 * This probably should be included directly inside the align.nf of t-coffee
 */

params.outdir = ''

process reformat {
    tag { id }
    publishDir "${params.outdir}/tcoffee"
    container 'quay.io/biocontainers/t_coffee:11.0.8--py27pl5.22.0_5'

    input:
    // tuple val (id), file (alignment)//, file (reference)
    tuple val (id), path (alignment)
    output:
    // tuple val (id), path ("${alignment}.fasta")//, path (reference)
    tuple val (id), path ("${alignment}.fasta")

    script:
    """
    t_coffee -other_pg seq_reformat ${alignment} -output fasta > ${alignment}.fasta
    """
}