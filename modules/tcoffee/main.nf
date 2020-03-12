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
    t_coffee -multi_core=$task.cpus -in=$fasta -output msf -run_name aln
    t_coffee -other_pg seq_reformat aln.msf -output fasta > ${fasta}.aln.fasta
    """
}

// t_coffee -in $fasta -outfile ${fasta}.aln.fasta -output fasta