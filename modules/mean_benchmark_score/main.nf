process mean_benchmark_score {
    tag { 'benchmark_mean' }
    publishDir "${params.outdir}/tcoffee"
    container 'joseespinosa/r-base@sha256:cc35d5e41d1252709b3c9c8a166daaab7e3231ec57a97113814f0345fcf19b54'

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
