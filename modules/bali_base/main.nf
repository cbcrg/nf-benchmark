process bali_base {
    tag {balibase}
    publishDir "${params.outdir}/bali_base"
    // container 'bengen/baliscore-v3.01@sha256:539664ed8d55543b1efac072fa29b0bc9e5d0eefc3b41c65d243c67b91543a61'
    // container 'cbcrg/baliscore-v4.0sha256:0c1f8534ebf9f99b65c3ef78b8e7dacb134f9c162ef987ce379463c28ab9c9df'
    container 'ce491f84786a'

    input:
        path (target_aln)
        path (ref_aln)
    output:
    path "score.out", emit: score

    script:
    """
    mview -in fasta -out msf $target_aln > aln.msf
    bali_score ${ref_aln} aln.msf | grep auto | awk '{ print "SP="\$3 ";TC="\$4 }' > score.out
    """
}

// version cbcrg/baliscore-v4.0@sha256:0c1f8534ebf9f99b65c3ef78b8e7dacb134f9c162ef987ce379463c28ab9c9df
// container '2f99e2bcb8e9'
// bali_score ${ref_aln} $target_aln | grep CS | awk '{ print "SP="\$3 }' > score.out

