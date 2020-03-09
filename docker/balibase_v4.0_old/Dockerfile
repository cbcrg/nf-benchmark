#  Copyright (c) 2020, Centre for Genomic Regulation (CRG).
#  Copyright (c) 2020, Jose Espinosa-Carrasco and the respective authors.
FROM ubuntu:19.10
MAINTAINER Jose Espinosa-Carrasco <espinosacarrascoj@gmail.com>

RUN apt-get update && \
    apt-get install -y wget cmake libtool libev-dev autotools-dev autoconf cmake nano

RUN wget http://www.lbgi.fr/balibase/BalibaseDownload/BAliBASE_R10_bali_score.tar.gz && \
    tar -xzf BAliBASE_R10_bali_score.tar.gz && \
    rm BAliBASE_R10_bali_score.tar.gz && \
    cd bali_score_src && \
    wget https://github.com/libexpat/libexpat/releases/download/R_1_95_6/expat-1.95.6.tar.gz && \
    tar -xzf expat-1.95.6.tar.gz && \
    rm expat-1.95.6.tar.gz && \
    cd expat-1.95.6 && \
    ./configure && \
    make && \
    make install && \
    cd ..


COPY makefile_balibase bali_score_src/makefile
COPY util.c bali_score_src/util.c

RUN cd /bali_score_src && \
    # mv makefile_balibase makefile && \
    make clean && \
    make -f makefile

RUN apt-get install -y pkg-config

ENV PATH="/bali_score_src:${PATH}"