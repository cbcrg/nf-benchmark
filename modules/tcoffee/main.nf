process tcoffee {
    tag {fasta}
    publishDir "${params.outdir}/tcoffee"
    container 'quay.io/biocontainers/t_coffee:11.0.8--py27pl5.22.0_5'

    input:
    path(fasta)

    output:
    path "${fasta}.aln.fasta", emit: alignment

    script:
    """
    t_coffee -in $fasta -outfile ${fasta}.aln.fasta -output fasta
    """
}
