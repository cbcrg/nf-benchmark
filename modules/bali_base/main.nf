process bali_base {
    tag {balibase}
    publishDir "${params.outdir}/bali_base"
    container 'bengen/baliscore-v3.01@sha256:539664ed8d55543b1efac072fa29b0bc9e5d0eefc3b41c65d243c67b91543a61'

    input:
        path (ref_aln)
        path (target_aln)

    output:
    path "score.out", emit: score

    //baliscore ${ref_aln} ${target_aln}
    script:
    """
    mview -in fasta -out msf $target_aln > aln.msf
    bali_score ${ref_aln} aln.msf | grep auto | awk '{ print "SP="\$3 ";TC="\$4 }' > score.out
    """
}
