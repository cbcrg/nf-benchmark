# nf-benchmark

# nf-benchmark: Documentation

The nf-benchmark documentation is split into the following files:

1. [Installation](https://nf-co.re/usage/installation)
2. Pipeline configuration
    * [Local installation](https://nf-co.re/usage/local_installation)
    * [Adding your own system config](https://nf-co.re/usage/adding_own_config)
    * [Reference genomes](https://nf-co.re/usage/reference_genomes)
3. [Running the pipeline](usage.md)
4. [Output and how to interpret the results](output.md)
5. [Troubleshooting](https://nf-co.re/usage/troubleshooting)

## How to run the pipeline

### From root

```bash
NXF_VER=20.04.1-edge nextflow run main.nf \
    --pipeline regressive_alignment \
    --regressive_align true \
    --align_methods "CLUSTALO" \
    --skip_benchmark \
    -profile test,docker \
    -resume
```

### From a module

#### Regressive-alignment

```bash
NXF_VER=20.04.1-edge nextflow run main.nf \
    --pipeline regressive_alignment \
    --regressive_align true \
    --align_methods "CLUSTALO" \
    --skip_benchmark \
    -profile test,docker \
    -resume
```

## declare workflow on main as pipeline  

## Include yml file

