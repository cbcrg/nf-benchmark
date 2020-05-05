/*
 * Aligns multiple sequences in a fasta file using t-coffee producing a MSA
 */

params.outdir = ''
params.output_format = 'msf'

process align {
    tag {fasta}
    publishDir "${params.outdir}/tcoffee"
    container 'quay.io/biocontainers/t_coffee:11.0.8--py27pl5.22.0_5'

    input:
    tuple val (id), file (fasta), file (reference)

    output:
    // tuple val (id), path ("${fasta}.aln.fasta"), path (reference)
    tuple val (id), path ("${fasta}.${params.output_format}"), path (reference)

    script:
    """
    t_coffee -multi_core=$task.cpus -in=${fasta} -output ${params.output_format} -run_name ${fasta}.${params.output_format}
    """
}

// t_coffee -in $fasta -outfile ${fasta}.aln.fasta -output fasta


// reformat command
// t_coffee -other_pg seq_reformat aln.msf -output fasta > ${fasta}.aln.fasta