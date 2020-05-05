/*
 * Reformats an alignment using mview
 */

params.format_in = "fasta"
params.format_out = "msf"

process reformat {
    tag { id }
    publishDir "${params.outdir}/bali_base"
    container 'cbcrg/baliscore-v3.1@sha256:e72eb7b2f375c3c1248cc31a96db36dc9c20c2891d297fe8c94f1124930932bb'

    input:
    tuple val (id), path (target_aln), path (ref_aln)

    output:
    tuple val (id), path ("${target_aln}.${params.format_out}"), path (ref_aln)

    script:
    """
    mview -in ${params.format_in} -out msf $target_aln > ${target_aln}.${params.format_out}
    """
}