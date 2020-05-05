process benchmark {
    tag { id }
    publishDir "${params.outdir}/bali_base"
    container 'cbcrg/baliscore-v3.1@sha256:e72eb7b2f375c3c1248cc31a96db36dc9c20c2891d297fe8c94f1124930932bb'

    input:
    tuple val (id), path (target_aln), path (ref_aln)

    output:
    path "score.out", emit: score

    script:
    """
    mview -in fasta -out msf $target_aln > aln.msf
    bali_score ${ref_aln} aln.msf | grep auto | awk '{ print \$3 }' > score.out
    """
}

// bali_score ${ref_aln} aln.msf | grep auto | awk '{ print "SP="\$3 ";TC="\$4 }' > score.out

// container 'cbcrg/baliscore-v4.0@sha256:0c1f8534ebf9f99b65c3ef78b8e7dacb134f9c162ef987ce379463c28ab9c9df'
// version cbcrg/baliscore-v4.0@sha256:0c1f8534ebf9f99b65c3ef78b8e7dacb134f9c162ef987ce379463c28ab9c9df
// bali_score ${ref_aln} $target_aln | grep CS | awk '{ print "SP="\$3 }' > score.out

