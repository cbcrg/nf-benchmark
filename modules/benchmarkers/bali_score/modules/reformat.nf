/*
 * Reformats an alignment using mview
 */

params.format_in = "fasta"
params.format_out = "msf"

process REFORMAT {    
    tag { id }
    publishDir "${params.outdir}/bali_base"
    container 'cbcrg/baliscore-v3.1@sha256:c8b2959125c80045e5254aeb92f5f8bdb14d65d84561a540f71cdc9a0ee5c18c'
           
    input:
    tuple val (id), path (target_aln), path (ref_aln)

    output:
    tuple val (id), path ("${target_aln}.${params.format_out}"), path (ref_aln)

    script:
    """        
    mview -in ${params.format_in} -out msf ${target_aln} > ${target_aln}.${params.format_out}
    """
}

/*
mview -in ${params.format_in} -out msf ${target_aln} > tool.log 2>&1
mview -in ${params.format_in} -out msf ${target_aln} > ${target_aln}.${params.format_out}   
*/