# nf-benchmark

## Introduction:

nf-benchmark is a benchmarking tool based on nextflow DSL2 that allows to include your nextflow pipeline as a module for 
its benchmarking.

## Quick start

1. Install **Nextflow** following [this](https://www.nextflow.io/docs/latest/getstarted.html#installation) instructions.

2. Install either [`Docker`](https://docs.docker.com/engine/installation/) or 
[`Singularity`](https://www.sylabs.io/guides/3.0/user-guide/) to use the sandboxes images containing the software used 
by the pipeline.

3. Clone the repository:

```bash
git clone https://github.com/cbcrg/nf-benchmark
```

4. Run nf-benchmark

```bash
nextflow run main.nf --pipeline tcoffee -profile docker,test_nfb -resume
```

## Add your pipeline 

If you want to include your pipeline on nf-benchmark you just need to:
* Place the pipeline under the `modules/pipelines` directory e.g. 'modules/pipelines/my_pipeline'
* Create a `yml` file that includes some meta-information of your pipeline so that nf-benchmark can correctly run it. See
the `tcoffee` pipeline example [here](https://github.com/cbcrg/nf-benchmark/blob/master/modules/pipelines/tcoffee/meta.yml)
* Include a nextflow configuration file that should be named `test_nfb.config` and should be 
placed under `modules/pipelines/my_pipeline/conf/`, find the tcoffee example on this 
[link](https://github.com/cbcrg/nf-benchmark/blob/master/modules/pipelines/tcoffee/conf/test_nfb.config). This 
configuration should at least provide a input dataset for testing purposes. If you follow these steps you should be able
to run your pipeline under nf-benchmark using the following command: 

    ```bash
    nextflow run main.nf --pipeline my_pipeline --skip_benchnmark -profile test_nfb -resume
    ```

    Note that the `--pipeline` parameter design the name of the pipeline run.

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

* regressive without benchmarking

```bash
NXF_VER=20.11.0-edge nextflow run main.nf \
    --pipeline regressive_alignment \
    --regressive_align false \
    --align_methods CLUSTALO \
    --evaluate false \
    --skip_benchmark \
    -profile nfb-test,nfb-docker \
    -resume
```

* Regressive with benchmarking

```bash
NXF_VER=20.11.0-edge nextflow run main.nf \
    --pipeline regressive_alignment \
    --regressive_align false \
    --align_methods CLUSTALO \
    --evaluate false \    
    -profile nfb-test,nfb-docker \
    -resume
```

```bash
# 20210204 
NXF_VER=20.11.0-edge nextflow run main.nf     --pipeline regressive_alignment     --regressive_align false     --align_methods CLUSTALO     --evaluate false  --pipeline_test_config $PWD/modules/pipelines/regressive_alignment/conf/test_nfb.config   -profile nfb-test,nfb-docker -resume

# 20210205
NXF_VER=20.11.0-edge nextflow run main.nf     --pipeline regressive_alignment     --regressive_align false     --align_methods CLUSTALO     --evaluate false  --pipeline_test_config $PWD/modules/pipelines/regressive_alignment/conf/test_nfb.config  --pipeline_output_name alignment_progressive -profile nfb-test,nfb-docker -resume
```

```bash
NXF_VER=20.11.0-edge nextflow run main.nf \
    --pipeline regressive_alignment \
    --regressive_align true \
    --align_methods CLUSTALO \
    --evaluate false \
    -profile nfb-test,nfb-docker \
    -resume
```

### From a module

#### t-coffee

```bash
NXF_VER=20.11.0-edge nextflow run main.nf --pipeline tcoffee --skip_benchmark -resume
```

```bash
nextflow run main.nf --pipeline tcoffee --skip_benchmark -profile nfb-docker,nfb-test -ansi-log false -resume
```

#### Regressive-alignment

```bash
NXF_VER=20.11.0 nextflow run main.nf \
    --regressive_align true \
    --align_methods CLUSTALO \
    --evaluate false \
    -profile nfb-test,nfb-docker \
    -resume
```

* 2020/07/28 

```bash
NXF_VER=20.11.0 nextflow run main.nf \
    --pipeline regressive_alignment_new  \
    --regressive_align false \
    --align_methods CLUSTALO \
    --evaluate false \
    -profile nfb-test,nfb-docker
```

#### Directly run regressive alignment pipeline

```bash
NXF_VER=20.04.1-edge nextflow run main.nf \
    --regressive_align true \
    --align_methods CLUSTALO \
    -profile test,docker \
    -resume
```

#### With makefile

```bash
make regressive | nextflow run main.nf \
    --pipeline regressive_alignment \
    --skip_benchmark \
    -profile nfb-docker,nfb-test \
    -ansi-log false \
    -resume
```

#### nfcore

```bash
NXF_VER=20.11.0-edge nextflow run main.nf --pipeline rnaseq -profile nfb-test,nfb-docker --skip_benchmark -stub-run
```

## declare workflow on main as pipeline  

```bash
NXF_VER=20.04.1-edge nextflow run main.nf --regressive_align false --align_methods "CLUSTALO" --evaluate false -profile test,docker -resume
```

## Points to add to the documentation

### Structure

#### Modules/pipelines/

### Modules/benchmarks

### Modules/assests

### Include yml file

### Include a test config

If you want to use the test_nfb you should include a configuration file in pipelines/your_pipeline/conf/test_nfb.config
Otherwise, you can use your own test file using -c option see 

### Params:

--params.pipeline 

--params.path_to_pipelines

--params.path_to_benchmarks

## Tables description:

### methods2benchmark:

The **methods2benchmark.csv** table contains the relationship between the pipeline method, its data input output and 
finally the benchmark, it contains the following fields:

* edam_operation
* edam_input_data
* edam_input_format
* edam_output_data 
* edam_output_format
* benchmarker

The input and output data of benchmarkers can be found in **dataFormat2benchmark.csv**. The fields of the table are:

* benchmarker
* edam_operation
* edam_test_data
* edam_test_format
* edam_ref_data
* edam_ref_format
   
NXF_VER=20.10.0 nextflow run main.nf --pipeline tcoffee --skip_benchmark -profile nfb-test,nfb-docker

NXF_VER=20.11.0-edge nextflow run main.nf --pipeline rnaseq -profile nfb-test,nfb-docker --skip_benchmark -resume -stub-run

## Tags

Tag #modified for things modified on `nf-core/rnaseq`
