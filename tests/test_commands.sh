#!/usr/bin/env bash
echo "...............$NXF_WORK"

# COMMANDS WITHOUT BENCHMARK
nextflow run ../main.nf --pipeline tcoffee --skip_benchmark -profile docker,test_nfb -ansi-log false -resume
nextflow run ../main.nf --pipeline tcoffee --skip_benchmark --pipeline_output_name 'alignment' -profile docker,test_nfb -ansi-log false -resume

make -f ../Makefile regressive | nextflow run  ../main.nf --pipeline regressive_alignment --skip_benchmark -profile docker,test_nfb -ansi-log false -resume
make -f ../Makefile regressive | nextflow run  ../main.nf --pipeline regressive_alignment --skip_benchmark --pipeline_output_name 'alignment_regressive' -profile docker,test_nfb -ansi-log false -resume

#### COMMANDS WITH BENCHMARK
nextflow run ../main.nf --pipeline tcoffee -profile docker,test_nfb -ansi-log false -resume
nextflow run ../main.nf --pipeline tcoffee --pipeline_output_name 'alignment' -profile docker,test_nfb -ansi-log false -resume

make -f ../Makefile regressive | nextflow run ../main.nf --pipeline regressive_alignment -profile docker,test_nfb -ansi-log false -resume
make -f ../Makefile regressive | nextflow run ../main.nf --pipeline regressive_alignment --pipeline_output_name 'alignment_regressive' --skip_benchmark -profile docker,test_nfb -ansi-log false -resume
