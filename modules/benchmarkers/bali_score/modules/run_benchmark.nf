/*
 * Benchmark a MSA using baliscore
 */
process RUN_BENCHMARK {
    tag { id }
    publishDir "${params.outdir}/bali_base"
    container 'cbcrg/baliscore-v3.1@sha256:c8b2959125c80045e5254aeb92f5f8bdb14d65d84561a540f71cdc9a0ee5c18c'

    input:
    tuple val (id), path (target_aln), path (ref_aln)

    output:
    path "score.out", emit: score

    script:
    """
    ## bali_score ${ref_aln} ${target_aln} > score.out
    bali_score ${ref_aln} ${target_aln} | grep auto | awk '{ print \$3 }' > score.out
    """
}