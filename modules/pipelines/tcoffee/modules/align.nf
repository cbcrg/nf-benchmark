/*
 * Aligns multiple sequences in a fasta file using t-coffee producing a MSA
 */

params.outdir = ''
// params.output_format = 'msf'
params.output_format = 'fasta_aln'

process ALIGN {
    tag {id}
    publishDir "${params.outdir}/tcoffee"
    container 'cbcrg/tcoffee@sha256:8894ba57a7ff34965d8febd51dcb7765b71314ca06893bc473d32e22032bf66f'

    input:
    tuple val (id), file (sequences)// , file (reference)

    output:
    // tuple val (id), path ("${sequences}.aln.fasta"), path (reference)
    // tuple val (id), path ("${sequences}.${params.output_format}"), path (reference)
    tuple val (id), path ("${sequences}.${params.output_format}")

    script:
    """
    t_coffee -multi_core=$task.cpus -in=${sequences} -output ${params.output_format} -run_name ${sequences}.${params.output_format}
    """
}

// t_coffee -in $sequences -outfile ${sequences}.aln.fasta -output fasta


// reformat command
// t_coffee -other_pg seq_reformat aln.msf -output fasta > ${sequences}.aln.fasta