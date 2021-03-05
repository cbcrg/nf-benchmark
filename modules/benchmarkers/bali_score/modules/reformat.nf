/*
 * Reformats an alignment using mview
 */

params.format_in = "fasta"
params.format_out = "msf"

process REFORMAT {
    tag { id }
    publishDir "${params.outdir}/bali_base"
    container 'cbcrg/baliscore-v3.1@sha256:31040f7090f8570b7043ee03a416d2977756e5fde2987d11358492631f202368'
           
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
mview -in ${params.format_in} -out msf ${target_aln} > ${target_aln}.${params.format_out}    
    
/Users/jaespinosa/nxf_scratch/31/7c0848afc0f622be7fefb93f3babe2
*/