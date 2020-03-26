process mean_benchmark_score {
    tag { mean_benchmark }
    publishDir "${params.outdir}/tcoffee"
    container 'r-base@sha256:544384846abe657672f041d8b8c23142c2ffc244280f032a449f6cc3a1caedb1'

    input:
    file (scores)

    output:
    stdout()

    script:
    """
    #!/usr/bin/env Rscript

    cat(mean(read.csv (\"$scores\", header=F)\$V1))
    """
}
